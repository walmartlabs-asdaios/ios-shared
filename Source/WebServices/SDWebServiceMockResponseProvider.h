//
//  SDWebServiceMockResponseProvider.h
//  ios-shared
//
//  Created by Douglas Sjoquist on 12/15/14.
//  Copyright (c) 2014 SetDirection. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SDWebServiceMockResponseProvider <NSObject>
- (NSData *) getMockResponseForRequest:(NSURLRequest *) request;
@end