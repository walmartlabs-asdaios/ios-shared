//
//  CLLocationManagerProxy.h
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface CLLocationManagerProxy : NSProxy
@property (nonatomic,strong) NSObject *object;
@property (nonatomic,strong) NSMutableDictionary *receivedMessageCounts;
@property (nonatomic,strong) NSString *failOnMethodCallMessage;

- (instancetype)initWithObject:(NSObject *)object;
- (NSUInteger)receivedMessageCountForSelector:(SEL)selector;

@end
