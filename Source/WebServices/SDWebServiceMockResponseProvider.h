//
//  SDWebServiceMockResponseProvider.h
//  ios-shared
//
//  Created by Douglas Sjoquist on 12/15/14.
//  Copyright (c) 2014 SetDirection. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 SDWebService uses implementations of SDWebServiceMockResponseQueueProvider to
 handle any mock responses.  
 
 All details except the get data method are handled by implementations.
 */
@protocol SDWebServiceMockResponseProvider <NSObject>

/**
 Returns value for response to use in SDWebService performRequest methods, 
 value will be replace all the normal response handling in SDWebService

 @param request providers may use the request values to determine what mock response they should return, but providers can also ignore it and do whatever they want
 @return mock response to use
 */
- (NSHTTPURLResponse *) getMockHTTPURLResponseForRequest:(NSURLRequest *) request;

/**
 Returns value for responseData to use in SDWebService performRequest methods

 @param request providers may use the request values to determine what mock response they should return, but providers can also ignore it and do whatever they want
 @return mock data to use in final part of response processing
 */
- (NSData *) getMockDataForRequest:(NSURLRequest *) request;

/**
 Remember HTTPURLResponse/responseData values for the last matching request
 so they can be retrieved later if needed without triggering a match request
 which can update the match count.

 This is needed so we can retrieve the responseData portion for an HTTPURLResponse already retrieved
 */
@property (nonatomic,strong,readonly) NSHTTPURLResponse *lastMatchingHTTPURLResponse;
@property (nonatomic,strong,readonly) NSData *lastMatchingResponseData;


@end
