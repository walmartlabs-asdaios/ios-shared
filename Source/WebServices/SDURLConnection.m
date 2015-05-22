//
//  SDURLConnection
//  ServiceTest
//
//  Created by Brandon Sneed on 11/3/11.
//  Copyright (c) 2011 SetDirection. All rights reserved.
//

#import "SDURLConnection.h"
#import "NSString+SDExtensions.h"
#import "NSCachedURLResponse+LeakFix.h"
#import "NSURLCache+SDExtensions.h"
#import "SDLog.h"

#import <libkern/OSAtomic.h>

#pragma mark - SDURLResponseCompletionDelegate

#ifndef SDURLCONNECTION_MAX_CONCURRENT_CONNECTIONS
#define SDURLCONNECTION_MAX_CONCURRENT_CONNECTIONS 20
#endif

@interface SDURLConnectionAsyncDelegate : NSObject
{
@public
    SDURLConnectionResponseBlock responseHandler;
@private
	NSMutableData *responseData;
	NSHTTPURLResponse *httpResponse;
    BOOL isRunning;
}

@property (atomic, assign) BOOL isRunning;

- (id)initWithResponseHandler:(SDURLConnectionResponseBlock)newHandler;
- (void)forceError:(SDURLConnection *)connection;

@end

@implementation SDURLConnectionAsyncDelegate

@synthesize isRunning;

- (id)initWithResponseHandler:(SDURLConnectionResponseBlock)newHandler
{
    if (self = [super init])
	{
        responseHandler = [newHandler copy];
		responseData = [NSMutableData dataWithCapacity:0];
        self.isRunning = YES;
    }
	
    return self;
}

- (void)dealloc
{
    responseHandler = nil;
    responseData = nil;
}

- (void)runResponseHandlerOnceWithConnection:(SDURLConnection *)argConnection response:(NSURLResponse *)argResponse responseData:(NSData *)argResponseData error:(NSError *)argError
{
    BOOL wasRunning = isRunning;
    isRunning = NO;
    if (wasRunning && responseHandler)
    {
        responseHandler(argConnection, argResponse, argResponseData, argError);
    }
    responseHandler = nil;
}

- (void)forceError:(SDURLConnection *)connection
{
    [self runResponseHandlerOnceWithConnection:connection response:nil responseData:nil error:[NSError errorWithDomain:@"SDURLConnectionDomain" code:NSURLErrorCancelled userInfo:nil]];
}

#pragma mark NSURLConnection delegate

- (void)connection:(SDURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	httpResponse = (NSHTTPURLResponse *)response;
	[responseData setLength:0];
}

- (void)connection:(SDURLConnection *)connection didFailWithError:(NSError *)error
{
    [self runResponseHandlerOnceWithConnection:connection response:nil responseData:responseData error:error];
 }

- (void)connection:(SDURLConnection *)connection didReceiveData:(NSData *)data
{
    if (isRunning)
        [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(SDURLConnection *)connection
{
    [self runResponseHandlerOnceWithConnection:connection response:httpResponse responseData:responseData error:nil];
}

- (NSCachedURLResponse *)connection:(SDURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    NSHTTPURLResponse *response = (NSHTTPURLResponse*)[cachedResponse response];

    // If we don't have any cache control or expiration, we shouldn't store this.
    if ([connection currentRequest].cachePolicy == NSURLRequestUseProtocolCachePolicy)
    {
        NSDictionary *headers = [response allHeaderFields];
        if (![NSURLCache expirationDateFromHeaders:headers withStatusCode:response.statusCode])
            return nil; // we were effectively told not to cache it, so we won't.
    }

    return cachedResponse;
}

@end

#pragma mark - SDURLConnection

@interface SDURLConnection()

@property (nonatomic, strong) SDURLConnectionAsyncDelegate *asyncDelegate;

@end

@implementation SDURLConnection

static NSOperationQueue *networkOperationQueue = nil;

+ (void)initialize
{
    networkOperationQueue = [[NSOperationQueue alloc] init];
    networkOperationQueue.maxConcurrentOperationCount = SDURLCONNECTION_MAX_CONCURRENT_CONNECTIONS;
    networkOperationQueue.name = @"com.setdirection.sdurlconnectionqueue";
}

+ (NSInteger)maxConcurrentAsyncConnections
{
    return networkOperationQueue.maxConcurrentOperationCount;
}

+ (void)setMaxConcurrentAsyncConnections:(NSInteger)maxCount
{
    networkOperationQueue.maxConcurrentOperationCount = maxCount;
}

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately
{
    self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately];
    if ([delegate isKindOfClass:[SDURLConnectionAsyncDelegate class]])
        self.asyncDelegate = delegate;
    return self;
}

- (void)cancel
{
    @synchronized(self)
    {
        if (self.asyncDelegate.isRunning)
        {
            [super cancel];
            // forceError sets running = NO.
            [self.asyncDelegate forceError:self];
        }
    }
}

+ (SDURLConnection *)sendAsynchronousRequest:(NSURLRequest *)request withResponseHandler:(SDURLConnectionResponseBlock)handler
{
    if (!handler)
        @throw @"sendAsynchronousRequest must be given a handler!";
    
    SDURLConnectionAsyncDelegate *delegate = [[SDURLConnectionAsyncDelegate alloc] initWithResponseHandler:handler];

    // attempt to find any mock response or data if available, we need it going forward.
    NSHTTPURLResponse *mockHTTPURLResponse = nil;
    NSData *mockData = nil;
    BOOL usingMock = NO;
#ifdef DEBUG
    mockHTTPURLResponse = [[self mockResponseProvider] getMockHTTPURLResponseForRequest:request];
    if (mockHTTPURLResponse) {
        mockData = self.mockResponseProvider.lastMatchingResponseData;
    } else {
        mockData = [self.mockResponseProvider getMockDataForRequest:request];
    }
    usingMock = (mockData != nil) || (mockHTTPURLResponse != nil);
#endif

    if (usingMock)
    {
        handler(nil, mockHTTPURLResponse, mockData, nil);
        return nil;
    }
    else
    {
        SDURLConnection *connection = [[SDURLConnection alloc] initWithRequest:request delegate:delegate startImmediately:NO];

        if (!connection)
            SDLog(@"Unable to create a connection!");

        [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

        // the sole purpose of this is to enforce a maximum active connection count.
        // eventually, these max connection numbers will change based on reachability data.
        [networkOperationQueue addOperationWithBlock:^{
            [connection performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
            while (delegate.isRunning)
                sleep(1);
        }];
        
        return connection;
    }
}

#if DEBUG

static id<SDWebServiceMockResponseProvider> _mockResponseProvider;

+ (id<SDWebServiceMockResponseProvider>) mockResponseProvider;
{
    return _mockResponseProvider;
}

+ (void) setMockResponseProvider:(id<SDWebServiceMockResponseProvider>) mockResponseProvider;
{
    _mockResponseProvider = mockResponseProvider;
}

#endif

@end
