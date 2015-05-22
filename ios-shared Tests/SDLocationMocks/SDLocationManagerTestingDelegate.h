//
//  SDLocationManagerTestingDelegate.h
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDLocationManager.h"

@interface SDLocationManagerTestingDelegate : NSObject<SDLocationManagerDelegate>

@property (nonatomic,assign,readonly) NSUInteger receivedMessageCount;

- (NSUInteger)receivedMessageCountForSelector:(SEL)selector;

@end
