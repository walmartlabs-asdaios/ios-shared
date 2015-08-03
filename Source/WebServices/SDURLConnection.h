//
//  SDURLConnection.h
//  ServiceTest
//
//  Created by Brandon Sneed on 11/3/11.
//  Copyright (c) 2011 SetDirection. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDWebServiceMockResponseProvider.h"

/**
 SDURLConnection is a subclass of NSURLConnection that manages the concurrency and queueing of multiple asynchronous connections.
 Requests are added to the queue using sendAsynchronousRequest:withResponseHandler:.
 
 ### Blocks in use are defined as: ###
    typedef void (^SDURLConnectionResponseBlock)(SDURLConnection *connection, NSURLResponse *response, NSData *responseData, NSError *error);
 */

@class SDURLConnection;
@class SDURLConnectionAsyncDelegate;

typedef void (^SDURLConnectionResponseBlock)(SDURLConnection *connection, NSURLResponse *response, NSData *responseData, NSError *error);

typedef NS_ENUM(NSUInteger, kSDNetworkQueuePriority) {
    kSDNetworkQueuePriority_first = 0,
    kSDNetworkQueuePriority_high = kSDNetworkQueuePriority_first,
    kSDNetworkQueuePriority_default,
    kSDNetworkQueuePriority_background,
    kSDNetworkQueuePriority_last = kSDNetworkQueuePriority_background
};

@interface SDURLConnection : NSURLConnection

@property (nonatomic,assign,readonly) kSDNetworkQueuePriority priority;

- (id)initWithRequest:(NSURLRequest *)request priority:(kSDNetworkQueuePriority) priority delegate:(id)delegate startImmediately:(BOOL)startImmediately;

/**
 Returns the maximum number of concurrent connections allowed.
 */
+ (NSInteger)maxConcurrentAsyncConnectionsForPriority:(kSDNetworkQueuePriority) priority;

/**
 Set the maximum number of concurrent connections allowed to `maxCount`. The default is `20`.
 */
+ (void)setMaxConcurrentAsyncConnections:(NSInteger)maxCount forPriority:(kSDNetworkQueuePriority) priority;

/**
 Create a connection for the given request parameters.
 @param request The URL request.
 @param handler The block to execute when the response has been received completely.
 */
+ (SDURLConnection *)sendAsynchronousRequest:(NSURLRequest *)request withResponseHandler:(SDURLConnectionResponseBlock)handler;

+ (SDURLConnection *)sendAsynchronousRequest:(NSURLRequest *)request withPriority:(kSDNetworkQueuePriority) priority responseHandler:(SDURLConnectionResponseBlock)handler;

#pragma mark - Unit Testing

#ifdef DEBUG

/**
 Allows for multiple mock response provider implementations
 */
+ (id<SDWebServiceMockResponseProvider>) mockResponseProvider;

+ (void) setMockResponseProvider:(id<SDWebServiceMockResponseProvider>) mockResponseProvider;

#endif

@end
