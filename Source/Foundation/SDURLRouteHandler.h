//
//  SDURLRouteHandler.h
//  ios-shared
//
//  Created by Andrew Finnell on 12/11/14.
//  Copyright (c) 2014 Set Direction. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SDURLRouteHandler <NSObject>

- (void) handleURL:(NSURL *)url withParameters:(NSDictionary *)parameters;

@end
