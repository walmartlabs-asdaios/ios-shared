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
@property (nonatomic,assign) NSTimeInterval responseDelay;

@property (nonatomic,strong) NSString *httpVersion;
@property (nonatomic,assign) NSInteger statusCode;
@property (nonatomic,strong) NSDictionary *headers;
@property (nonatomic,strong) NSData *responseData;
- (NSHTTPURLResponse *) httpURLResponseWithURL:(NSURL *) url;
@end

@implementation SDWebServiceMockResponseRequestMappingEntry

+ (SDWebServiceMockResponseRequestMappingEntry *) dataEntryWithMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping withFilename:(NSString *)filename bundle:(NSBundle *) bundle maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;
{
    SDWebServiceMockResponseRequestMappingEntry *result = [[SDWebServiceMockResponseRequestMappingEntry alloc] init];
    result.requestMapping = requestMapping;
    result.bundle = bundle;
    result.maximumResponses = maximumResponses;
    result.responseDelay = responseDelay;
    [result loadResponseDataFromFilename:filename];
    return result;
}

+ (SDWebServiceMockResponseRequestMappingEntry *) dataEntryWithMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping withData:(NSData *) data maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;
{
    SDWebServiceMockResponseRequestMappingEntry *result = [[SDWebServiceMockResponseRequestMappingEntry alloc] init];
    result.requestMapping = requestMapping;
    result.maximumResponses = maximumResponses;
    result.responseData = data;
    result.responseDelay = responseDelay;
    return result;
}

+ (SDWebServiceMockResponseRequestMappingEntry *) responseEntryWithMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping withFilename:(NSString *)filename bundle:(NSBundle *) bundle maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;
{
    SDWebServiceMockResponseRequestMappingEntry *result = [[SDWebServiceMockResponseRequestMappingEntry alloc] init];
    result.requestMapping = requestMapping;
    result.bundle = bundle;
    result.maximumResponses = maximumResponses;
    result.responseDelay = responseDelay;
    [result loadHTTPURLResponseFromFilename:filename];
    return result;
}

+ (SDWebServiceMockResponseRequestMappingEntry *) responseEntryWithMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping withResponseString:(NSString *)responseString maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;
{
    SDWebServiceMockResponseRequestMappingEntry *result = [[SDWebServiceMockResponseRequestMappingEntry alloc] init];
    result.requestMapping = requestMapping;
    result.maximumResponses = maximumResponses;
    result.responseDelay = responseDelay;
    [result loadHTTPURLResponseFromString:responseString];
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
    [self loadHTTPURLResponseFromString:responseString];
}

- (void) loadHTTPURLResponseFromString:(NSString *) responseString;
{
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
            self.httpVersion = values[0];
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

- (NSString *) description;
{
    return [NSString stringWithFormat:@"Entry hv=%@, dl=%ld, mapping=%@, ", self.httpVersion, (long) [self.responseData length], self.requestMapping];
}

@end

@interface SDWebServiceMockResponseMapProvider()
@property (nonatomic,strong) NSMutableArray *requestMappings;
@property (nonatomic,strong,readwrite) NSHTTPURLResponse *lastMatchingHTTPURLResponse;
@property (nonatomic,strong,readwrite) NSData *lastMatchingResponseData;
@end

@implementation SDWebServiceMockResponseMapProvider

@synthesize defaultMockDataBlock = _defaultMockDataBlock;

+ (SDWebServiceMockResponseMapProvider *) sharedMockResponseMapProvider;
{
    static dispatch_once_t onceToken;
    static SDWebServiceMockResponseMapProvider *_instance;
    dispatch_once(&onceToken, ^{
        _instance = [[SDWebServiceMockResponseMapProvider alloc] init];
    });
    return _instance;
}

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
    NSTimeInterval responseDelay = 0.0;
    NSArray *requestMappings = [NSArray arrayWithArray:self.requestMappings];
    for (SDWebServiceMockResponseRequestMappingEntry *entry in requestMappings)
    {
        if ([entry matchesRequest:request])
        {
            result = [entry httpURLResponseWithURL:request.URL];
            if (result)
            {
                entry.matchCount += 1;
                self.lastMatchingHTTPURLResponse = result;
                self.lastMatchingResponseData = entry.responseData;
                responseDelay = entry.responseDelay;
                break;
            }
        }
    }
    if (responseDelay > 0) {
        [NSThread sleepForTimeInterval:responseDelay];
    }
    return result;
}

- (NSData *) getMockDataForRequest:(NSURLRequest *)request
{
    NSData *result = nil;
    NSTimeInterval responseDelay = 0.0;
    NSArray *requestMappings = [NSArray arrayWithArray:self.requestMappings];
    for (SDWebServiceMockResponseRequestMappingEntry *entry in requestMappings)
    {
        if ([entry matchesRequest:request])
        {
            result = entry.responseData;
            if (result)
            {
                entry.matchCount += 1;
                self.lastMatchingHTTPURLResponse = nil;
                self.lastMatchingResponseData = entry.responseData;
                responseDelay = entry.responseDelay;
                break;
            }
        }
    }
    if (responseDelay > 0) {
        [NSThread sleepForTimeInterval:responseDelay];
    }
    return result;
}

- (void)addMockData:(NSData *) data forRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;
{
    SDWebServiceMockResponseRequestMappingEntry *entry = [SDWebServiceMockResponseRequestMappingEntry dataEntryWithMapping:requestMapping withData:data maximumResponses:maximumResponses responseDelay:responseDelay];
    [self.requestMappings addObject:entry];
}

- (void)addMockData:(NSData *) data forPath:(NSString *) path;
{
    SDWebServiceMockResponseRequestMapping *requestMapping =
    [[SDWebServiceMockResponseRequestMapping alloc] initWithPath:path queryParameters:nil];
    [self addMockData:data forRequestMapping:requestMapping maximumResponses:NSIntegerMax responseDelay:0.0];
}

- (void)addMockDataFile:(NSString *)filename bundle:(NSBundle *)bundle forRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;
{
    SDWebServiceMockResponseRequestMappingEntry *entry = [SDWebServiceMockResponseRequestMappingEntry dataEntryWithMapping:requestMapping withFilename:filename bundle:bundle maximumResponses:maximumResponses responseDelay:responseDelay];
    [self.requestMappings addObject:entry];
}

- (void)addMockDataFile:(NSString *)filename bundle:(NSBundle *)bundle forPath:(NSString *) path
{
    SDWebServiceMockResponseRequestMapping *requestMapping =
    [[SDWebServiceMockResponseRequestMapping alloc] initWithPath:path queryParameters:nil];
    [self addMockDataFile:filename bundle:bundle forRequestMapping:requestMapping maximumResponses:NSIntegerMax responseDelay:0.0];
}

- (void)addMockHTTPURLResponseFile:(NSString *)filename bundle:(NSBundle *)bundle forRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;
{
    SDWebServiceMockResponseRequestMappingEntry *entry = [SDWebServiceMockResponseRequestMappingEntry responseEntryWithMapping:requestMapping withFilename:filename bundle:bundle maximumResponses:maximumResponses responseDelay:responseDelay];
    [self.requestMappings addObject:entry];
}

- (void)addMockHTTPURLResponseString:(NSString *)responseString forRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;
{
    SDWebServiceMockResponseRequestMappingEntry *entry = [SDWebServiceMockResponseRequestMappingEntry responseEntryWithMapping:requestMapping withResponseString:responseString maximumResponses:maximumResponses responseDelay:responseDelay];
    [self.requestMappings addObject:entry];
}

- (NSUInteger)countForRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping;
{
    NSUInteger result = 0;
    NSArray *requestMappings = [self.requestMappings copy];
    for (SDWebServiceMockResponseRequestMappingEntry *entry in requestMappings)
    {
        if ([entry.requestMapping isEqual:requestMapping])
        {
            result += entry.matchCount;
        }
    }
    return result;
}

- (NSArray *)requestMappingEntriesForPathPattern:(NSString *) pathPattern;
{
    NSMutableArray *result = [NSMutableArray array];
    for (SDWebServiceMockResponseRequestMappingEntry *entry in self.requestMappings)
    {
        if ([entry.requestMapping.pathPattern isEqualToString:pathPattern])
        {
            [result addObject:entry];
        }
    }
    return [result copy];
}

- (NSArray *)requestMappingsForPathPattern:(NSString *) pathPattern;
{
    NSArray *entries = [self requestMappingEntriesForPathPattern:pathPattern];
    return [entries valueForKey:@"requestMapping"];
}

- (void)removeRequestMappingsForPathPattern:(NSString *) pathPattern;
{
    NSArray *entries = [self requestMappingEntriesForPathPattern:pathPattern];
    for (SDWebServiceMockResponseRequestMappingEntry *entry in entries) {
        {
            [self.requestMappings removeObject:entry];
        }
    }
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
