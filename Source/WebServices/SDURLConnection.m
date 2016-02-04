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

@interface SDNetworkOperationQueue : NSOperationQueue
@property (nonatomic,assign,readonly) kSDNetworkQueuePriority priority;
@end

@implementation SDNetworkOperationQueue

@synthesize priority = _priority;

- (instancetype) init;
{
    if ((self = [super init])) {
        _priority = kSDNetworkQueuePriority_default;
    }
    return self;
}

- (instancetype) initWithPriority:(kSDNetworkQueuePriority) priority;
{
    if ((self = [super init])) {
        _priority = priority;
    }
    return self;
}

@end

@interface SDNetworkOperationQueueControl : NSObject
@property (nonatomic,strong) NSArray *queues;
@end

@implementation SDNetworkOperationQueueControl

static NSString const * SDNetworkOperationQueueControlContext = @"SDNetworkOperationQueueControlContext";

- (instancetype) init;
{
    if ((self = [super init])) {
        _queues = [self buildQueues];
    }
    return self;
}

- (NSArray *) buildQueues;
{
    NSMutableArray *result = [NSMutableArray array];
    for (kSDNetworkQueuePriority priority=kSDNetworkQueuePriority_first; priority<=kSDNetworkQueuePriority_last; priority++) {
        SDNetworkOperationQueue *networkOperationQueue = [[SDNetworkOperationQueue alloc] initWithPriority:priority];
        networkOperationQueue.maxConcurrentOperationCount = SDURLCONNECTION_MAX_CONCURRENT_CONNECTIONS;
        networkOperationQueue.name = [NSString stringWithFormat:@"com.setdirection.sdurlconnectionqueue_%zd", priority];
        networkOperationQueue.suspended = YES;

        [networkOperationQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&SDNetworkOperationQueueControlContext];

        [result addObject:networkOperationQueue];
    }
    return [result copy];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    if (context == &SDNetworkOperationQueueControlContext) {
        NSInteger oldCount = [change[NSKeyValueChangeOldKey] integerValue];
        NSInteger newCount = [change[NSKeyValueChangeNewKey] integerValue];
        // we only care about the transition between empty & non-empty
        if ((oldCount == 0) && (newCount > 0)) {
            [self refreshQueues];
        } else if ((oldCount > 0) && (newCount == 0)) {
            [self refreshQueues];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) refreshQueues;
{
    BOOL haveActiveQueue = NO;
    for (NSUInteger idx=0; idx<[self.queues count]; idx++) {
        SDNetworkOperationQueue *queue = self.queues[idx];
        if (haveActiveQueue) {
            // suspend all lower priority queues
            queue.suspended = YES;
        } else if (queue.operationCount > 0) {
            haveActiveQueue = YES;
            queue.suspended = NO; // ensure the highest priority queue is running
        }
    }
}

- (SDNetworkOperationQueue *) networkOperationQueueForPriority:(kSDNetworkQueuePriority) priority;
{
    return (priority < [self.queues count]) ? [self.queues objectAtIndex:priority] : nil;
}

- (NSInteger)maxConcurrentAsyncConnectionsForPriority:(kSDNetworkQueuePriority) priority;
{
    return [[self networkOperationQueueForPriority:priority] maxConcurrentOperationCount];
}

- (void)setMaxConcurrentAsyncConnections:(NSInteger)maxCount forPriority:(kSDNetworkQueuePriority) priority;
{
    [[self networkOperationQueueForPriority:priority] setMaxConcurrentOperationCount:maxCount];
}

@end

#pragma mark - SDURLConnection

@interface SDURLConnection()

@property (nonatomic,assign,readwrite) kSDNetworkQueuePriority priority;
@property (nonatomic, strong) SDURLConnectionAsyncDelegate *asyncDelegate;

@end

@implementation SDURLConnection

+ (SDNetworkOperationQueueControl *) networkOperationQueueControl;
{
    static dispatch_once_t onceToken;
    static SDNetworkOperationQueueControl *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[SDNetworkOperationQueueControl alloc] init];
    });
    return instance;
}

+ (SDNetworkOperationQueue *) networkOperationQueueForPriority:(kSDNetworkQueuePriority) priority;
{
    return [[self networkOperationQueueControl] networkOperationQueueForPriority:priority];
}

+ (NSInteger)maxConcurrentAsyncConnectionsForPriority:(kSDNetworkQueuePriority) priority;
{
    return [[self networkOperationQueueControl] maxConcurrentAsyncConnectionsForPriority:priority];
}

+ (void)setMaxConcurrentAsyncConnections:(NSInteger)maxCount forPriority:(kSDNetworkQueuePriority) priority;
{
    [[self networkOperationQueueControl] setMaxConcurrentAsyncConnections:maxCount forPriority:priority];
}

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate startImmediately:(BOOL)startImmediately
{
    self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately];
    self.priority = kSDNetworkQueuePriority_default;
    if ([delegate isKindOfClass:[SDURLConnectionAsyncDelegate class]]) {
        self.asyncDelegate = delegate;
    }
    return self;
}

- (id)initWithRequest:(NSURLRequest *)request priority:(kSDNetworkQueuePriority) priority delegate:(id)delegate startImmediately:(BOOL)startImmediately
{
    self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately];
    self.priority = priority;
    if ([delegate isKindOfClass:[SDURLConnectionAsyncDelegate class]]) {
        self.asyncDelegate = delegate;
    }
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

+ (SDURLConnection *)sendAsynchronousRequest:(NSURLRequest *)request withResponseHandler:(SDURLConnectionResponseBlock)handler;
{
    return [self sendAsynchronousRequest:request withPriority:kSDNetworkQueuePriority_default responseHandler:handler];
}

+ (SDURLConnection *)sendAsynchronousRequest:(NSURLRequest *)request withPriority:(kSDNetworkQueuePriority) priority responseHandler:(SDURLConnectionResponseBlock)handler
{
    if (!handler)
        @throw @"sendAsynchronousRequest must be given a handler!";
    
    SDURLConnectionAsyncDelegate *delegate = [[SDURLConnectionAsyncDelegate alloc] initWithResponseHandler:handler];

#ifdef DEBUG
    // attempt to find any mock response or data if available, we need it going forward.
    NSHTTPURLResponse *mockHTTPURLResponse = nil;
    NSData *mockData = nil;
    BOOL usingMock = NO;
    mockHTTPURLResponse = [[self mockResponseProvider] getMockHTTPURLResponseForRequest:request];
    if (mockHTTPURLResponse) {
        mockData = self.mockResponseProvider.lastMatchingResponseData;
    } else {
        mockData = [self.mockResponseProvider getMockDataForRequest:request];
    }
    usingMock = (mockData != nil) || (mockHTTPURLResponse != nil);

    if (usingMock)
    {
        [self.mockResponseProvider fireDidMockRequest:request withResponse:mockHTTPURLResponse data:mockData];
        handler(nil, mockHTTPURLResponse, mockData, nil);
        return nil;
    }
    else
    {
#endif
        SDURLConnection *connection = [[SDURLConnection alloc] initWithRequest:request priority:priority delegate:delegate startImmediately:NO];

        if (!connection)
            SDLog(@"Unable to create a connection!");

        [connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

        // the sole purpose of this is to enforce a maximum active connection count.
        // eventually, these max connection numbers will change based on reachability data.

        SDNetworkOperationQueue *networkOperationQueue = [[self class] networkOperationQueueForPriority:priority];
        [networkOperationQueue addOperationWithBlock:^{
            [connection performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
            while (delegate.isRunning)
                sleep(1);
        }];
        
        return connection;
#ifdef DEBUG
    }
#endif
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
