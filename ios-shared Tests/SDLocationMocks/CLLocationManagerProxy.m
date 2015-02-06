//
//  CLLocationManagerProxy.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import "CLLocationManagerProxy.h"

@implementation CLLocationManagerProxy

- (instancetype)initWithObject:(NSObject *)object
{
    _object = object;
    _receivedMessageCounts = [[NSMutableDictionary alloc] init];
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    return [self.object methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    NSString *selectorString = NSStringFromSelector(invocation.selector);
    NSUInteger count = [self.receivedMessageCounts[selectorString] unsignedIntegerValue];
    self.receivedMessageCounts[selectorString] = @(count + 1);
    SDLog(@"Ignoring call to CLLocationManager %@", selectorString);
    if (self.failOnMethodCallMessage) {
        SDLog(@"failOnMethodCallMessage: %@", self.failOnMethodCallMessage);
        assert(false);
    }
}

- (NSUInteger)receivedMessageCountForSelector:(SEL)selector;
{
     return [self.receivedMessageCounts[NSStringFromSelector(selector)] unsignedIntegerValue];
}

@end
