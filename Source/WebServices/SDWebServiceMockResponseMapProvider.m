//
//  SDWebServiceMockResponseMapProvider.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 12/15/14.
//  Copyright (c) 2014 SetDirection. All rights reserved.
//

#import "SDWebServiceMockResponseMapProvider.h"
#import "SDWebServiceMockResponseRequestMapping.h"

@interface SDWebServiceMockResponseRequestMappingEntry : NSObject
@property (nonatomic,strong) SDWebServiceMockResponseRequestMapping *requestMapping;
@property (nonatomic,strong) NSBundle *bundle;
@property (nonatomic,assign) NSUInteger maximumResponses;
@property (nonatomic,assign) NSUInteger matchCount;

@property (nonatomic,strong) NSString *httpVersion;
@property (nonatomic,assign) NSInteger statusCode;
@property (nonatomic,strong) NSDictionary *headers;
@property (nonatomic,strong) NSData *responseData;
- (NSHTTPURLResponse *) httpURLResponseWithURL:(NSURL *) url;
@end

@implementation SDWebServiceMockResponseRequestMappingEntry

+ (SDWebServiceMockResponseRequestMappingEntry *) dataEntryWithMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping withFilename:(NSString *)filename bundle:(NSBundle *) bundle maximumResponses:(NSUInteger) maximumResponses;
{
    SDWebServiceMockResponseRequestMappingEntry *result = [[SDWebServiceMockResponseRequestMappingEntry alloc] init];
    result.requestMapping = requestMapping;
    result.bundle = bundle;
    result.maximumResponses = maximumResponses;
    [result loadResponseDataFromFilename:filename];
    return result;
}

+ (SDWebServiceMockResponseRequestMappingEntry *) responseEntryWithMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping withFilename:(NSString *)filename bundle:(NSBundle *) bundle maximumResponses:(NSUInteger) maximumResponses;
{
    SDWebServiceMockResponseRequestMappingEntry *result = [[SDWebServiceMockResponseRequestMappingEntry alloc] init];
    result.requestMapping = requestMapping;
    result.bundle = bundle;
    result.maximumResponses = maximumResponses;
    [result loadHTTPURLResponseFromFilename:filename];
    return result;
}

- (BOOL) matchesRequest:(NSURLRequest *) request;
{
    return ((self.matchCount < self.maximumResponses)
            && [self.requestMapping matchesRequest:request]);
}

- (void) loadResponseDataFromFilename:(NSString *) filename;
{
    NSString *path = [self.bundle pathForResource:filename ofType:nil];
    self.responseData = [NSData dataWithContentsOfFile:path];
}

/*

 HTTP/1.1 200 OK
 Server: Apache
 Access-Control-Allow-Headers: X-Requested-With, Content-Type
 Access-Control-Allow-Methods: OPTIONS, GET, POST, PUT
 Access-Control-Allow-Credentials: true
 X-Powered-By: APP-Server
 Last-Modified: Thu, 18 Dec 2014 15:40:44 GMT
 X-V: A11528
 Cache-Control: no-cache,no-store
 Expires: Thu, 18 Dec 2014 15:40:44 GMT
 Vary: Accept-Encoding,User-Agent
 Content-Encoding: gzip
 Content-Length: 242
 Content-Type: text/javascript;charset=UTF-8
 Date: Thu, 18 Dec 2014 15:40:44 GMT
 Connection: close
 Set-Cookie: JSESSIONID=hluy+zv-SB3P0JLyISO4Wg__.oses4440-atg13; Path=/
 Access-Control-Allow-Origin: http://m.groceries.asda.com

 {"name":"SDWebServiceMockTest_bundleC","bundleCValue":"bundle B value"}
 */
- (void) loadHTTPURLResponseFromFilename:(NSString *) filename;
{
    NSString *path = [self.bundle pathForResource:filename ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    self.httpVersion = nil;
    self.statusCode = -1;
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    NSMutableArray *dataLines = nil;

    NSArray *lines = [responseString componentsSeparatedByString:@"\n"];

    for (NSString *line in lines) {
        NSString *cleanLine = [line stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        if (self.httpVersion == nil) {
            // HTTP/1.1 200 OK
            NSArray *values = [cleanLine componentsSeparatedByString:@" "];
            self.httpVersion = [values[0] componentsSeparatedByString:@"/"][0];
            if ([values count] > 1) {
                self.statusCode = [values[1] integerValue];
            }

        } else if (dataLines == nil) {
            if ([cleanLine length] == 0) {
                dataLines = [NSMutableArray array];
            } else {
                NSArray *values = [cleanLine componentsSeparatedByString:@": "];
                NSString *parameterName = values[0];
                NSString *parameterValue = ([values count] > 1) ? values[1] : @"";
                headers[parameterName] = parameterValue;
            }
        } else {
            // store original line so we can faithfully recreate the responseData
            [dataLines addObject:line];
        }
    }

    self.headers = [headers copy];
    NSString *responseDataString = [dataLines componentsJoinedByString:@"\n"];
    self.responseData = [responseDataString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSHTTPURLResponse *) httpURLResponseWithURL:(NSURL *)url;
{
    if (self.httpVersion == nil) {
        return nil;
    } else {
        return [[NSHTTPURLResponse alloc]
                initWithURL:url
                statusCode:self.statusCode
                HTTPVersion:self.httpVersion
                headerFields:self.headers];
    }
}

@end

@interface SDWebServiceMockResponseMapProvider()
@property (nonatomic,strong) NSMutableArray *requestMappings;
@property (nonatomic,strong,readwrite) NSHTTPURLResponse *lastMatchingHTTPURLResponse;
@property (nonatomic,strong,readwrite) NSData *lastMatchingResponseData;
@end

@implementation SDWebServiceMockResponseMapProvider

- (instancetype) init
{
    if ((self = [super init]))
    {
        _requestMappings = [NSMutableArray array];
        _lastMatchingHTTPURLResponse = nil;
        _lastMatchingResponseData = nil;
    }
    return self;
}

- (NSHTTPURLResponse *) getMockHTTPURLResponseForRequest:(NSURLRequest *)request
{
    NSHTTPURLResponse *result = nil;
    for (SDWebServiceMockResponseRequestMappingEntry *entry in self.requestMappings)
    {
        if ([entry matchesRequest:request])
        {
            result = [entry httpURLResponseWithURL:request.URL];
            if (result)
            {
                entry.matchCount += 1;
                self.lastMatchingHTTPURLResponse = result;
                self.lastMatchingResponseData = entry.responseData;
                break;
            }
        }
    }
    return result;
}

- (NSData *) getMockDataForRequest:(NSURLRequest *)request
{
    NSData *result = nil;
    for (SDWebServiceMockResponseRequestMappingEntry *entry in self.requestMappings)
    {
        if ([entry matchesRequest:request])
        {
            result = entry.responseData;
            if (result)
            {
                entry.matchCount += 1;
                self.lastMatchingHTTPURLResponse = nil;
                self.lastMatchingResponseData = entry.responseData;
                break;
            }
        }
    }
    return result;
}

- (void)addMockDataFile:(NSString *)filename bundle:(NSBundle *)bundle forRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping maximumResponses:(NSUInteger) maximumResponses
{
    SDWebServiceMockResponseRequestMappingEntry *entry = [SDWebServiceMockResponseRequestMappingEntry dataEntryWithMapping:requestMapping withFilename:filename bundle:bundle maximumResponses:maximumResponses];
    [self.requestMappings addObject:entry];
}

- (void)addMockDataFile:(NSString *)filename bundle:(NSBundle *)bundle forPath:(NSString *) path
{
    SDWebServiceMockResponseRequestMapping *requestMapping =
    [[SDWebServiceMockResponseRequestMapping alloc] initWithPath:path queryParameters:nil];
    [self addMockDataFile:filename bundle:bundle forRequestMapping:requestMapping maximumResponses:NSIntegerMax];
}

- (void)addMockHTTPURLResponseFile:(NSString *)filename bundle:(NSBundle *)bundle forRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping maximumResponses:(NSUInteger) maximumResponses
{
    SDWebServiceMockResponseRequestMappingEntry *entry = [SDWebServiceMockResponseRequestMappingEntry responseEntryWithMapping:requestMapping withFilename:filename bundle:bundle maximumResponses:maximumResponses];
    [self.requestMappings addObject:entry];
}

- (void)removeRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping
{
    NSArray *requestMappings = [self.requestMappings copy];
    for (SDWebServiceMockResponseRequestMappingEntry *entry in requestMappings)
    {
        if ([entry.requestMapping isEqual:requestMapping])
        {
            [self.requestMappings removeObject:entry];
        }
    }
}

- (void)removeAllRequestMappings
{
    [self.requestMappings removeAllObjects];
}

@end
