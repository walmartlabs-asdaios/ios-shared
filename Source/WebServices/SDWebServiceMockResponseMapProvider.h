//
//  SDWebServiceMockResponseMapProvider.h
//  ios-shared
//
//  Created by Douglas Sjoquist on 12/15/14.
//  Copyright (c) 2014 SetDirection. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDWebServiceMockResponseProvider.h"

@class SDWebServiceMockResponseRequestMapping;

/**
 SDWebServiceMockResponseMapProvider maps particular requestMappings to individual
 mock responses.  It can match one to many requests. 
 
 The same requestMapping value can be used multiple times to return different results for
 similar requests. Once the maximumResponses have been matched, the matching algorithm
 will move to the next mapped response in the list.  
 
 For instance, something like this:
 
 [p addMockDataFile:@"fileA.json" bundle:... forRequestMapping:requestMapping maximumResponses:2];
 [p addMockDataFile:@"fileB.json" bundle:... forRequestMapping:requestMapping maximumResponses:1];
 [p addMockDataFile:@"fileC.json" bundle:... forRequestMapping:requestMapping maximumResponses:NSIntegerMax
            responseDelay:0.0]
                                                    responseDelay:0.0];;

 will return the contents of fileA the first two times requestMapping's matchesRequest returns YES
 and then return the contents of fileB the next time requestMapping's matchesRequest returns YES
 and then return the contents of fileC every other time requestMapping's matchesRequest returns YES

 (see SDWebServiceMockResponseMapProviderTests#testCompoundMockResponse for more examples)
 */
@interface SDWebServiceMockResponseMapProvider : NSObject<SDWebServiceMockResponseProvider>

/**
 Allow test classes to use a common mockResponseMapProvider if they wish
 */
+ (SDWebServiceMockResponseMapProvider *) sharedMockResponseMapProvider;

/**
 Adds single mapping for request -> responseData

 @param data the resourceData to return
 @param requestMapping the mapping to use to determine when this responseData should be used
 @param maximumResponses the maximum number of times this responseData will be returned for any matching requestMappings
 */
- (void)addMockData:(NSData *) data forRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;

/**
 Convenience method to only check the request URL's path value, sets maximumResponses to NSIntegerMax, responseDelay to 0.0
 */
- (void)addMockData:(NSData *) data forPath:(NSString *) path;

/**
 Adds single mapping for request -> responseData

 @param filename the resource filename to load responseData from
 @param bundle the bundle to use for the resource
 @param requestMapping the mapping to use to determine when this responseData should be used
 @param maximumResponses the maximum number of times this responseData will be returned for any matching requestMappings
 @param responseDelay how long to delay before responding with mock data
 */
- (void)addMockDataFile:(NSString *)filename bundle:(NSBundle *)bundle forRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;

/**
 Convenience method to only check the request URL's path value, sets maximumResponses to NSIntegerMax, responseDelay to 0.0
 */
- (void)addMockDataFile:(NSString *)filename bundle:(NSBundle *)bundle forPath:(NSString *) path;

/**
 Adds single mapping for request -> HTTPURLResponse

 @param filename the resource filename to load HTTPURLResponse text from
 @param bundle the bundle to use for the resource
 @param requestMapping the mapping to use to determine when this HTTPURLResponse should be used
 @param maximumResponses the maximum number of times this HTTPURLResponse will be returned for any matching requestMappings
 @param responseDelay how long to delay before responding with mock data
 */
- (void)addMockHTTPURLResponseFile:(NSString *)filename bundle:(NSBundle *)bundle forRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;

/**
 Adds single mapping for request -> HTTPURLResponse

 @param responseString the HTTPURLResponse text
 @param requestMapping the mapping to use to determine when this HTTPURLResponse should be used
 @param maximumResponses the maximum number of times this HTTPURLResponse will be returned for any matching requestMappings
 @param responseDelay how long to delay before responding with mock data
 */
- (void)addMockHTTPURLResponseString:(NSString *)responseString forRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping maximumResponses:(NSUInteger) maximumResponses responseDelay:(NSTimeInterval) responseDelay;

/**
 Count of how many times requestMapping matched (was used)

 @param requestMapping the requestMapping to match
 @return count of times requestMapping was used
 */
- (NSUInteger)countForRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping;

/**
 Remove all responses for requestMapping

 @param requestMapping the requestMapping to match
 */
- (void)removeRequestMapping:(SDWebServiceMockResponseRequestMapping *) requestMapping;

/**
 Find all requestMapping whose pathPatterms matches the given pathPattern exactly

 @param pathPattern to match
 */
- (NSArray *)requestMappingsForPathPattern:(NSString *) pathPattern;

/**
 Remove all responses for any requestMapping whose pathPatterms matches the given pathPattern exactly

 @param path to match
 */
- (void)removeRequestMappingsForPathPattern:(NSString *) pathPattern;

/**
 Remove all request mappings to reset everything for subsequent tests
 */
- (void)removeAllRequestMappings;

@end
