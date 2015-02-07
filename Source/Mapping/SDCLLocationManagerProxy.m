//
//  SDCLLocationManagerProxy.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import "SDCLLocationManagerProxy.h"

@interface SDCLLocationManagerProxy()
@property (nonatomic,strong) CLLocationManager *clLocationManager;
@property (nonatomic,strong) SDBaseMockCLLocationManager *baseMockCLLocationManager;
@end

@implementation SDCLLocationManagerProxy

static Class _baseMockCLLocationManagerClass = nil;

+ (Class) baseMockCLLocationManagerClass;
{
    return _baseMockCLLocationManagerClass;
}

+ (void) setBaseMockCLLocationManagerClass:(Class) clazz;
{
    _baseMockCLLocationManagerClass = clazz;
}

- (instancetype) initWithBaseMockCLLocationManager:(SDBaseMockCLLocationManager *) baseMockCLLocationManager;
{
    _clLocationManager = [[CLLocationManager alloc] init];
    _baseMockCLLocationManager = baseMockCLLocationManager;
    [[self class] setBaseMockCLLocationManagerClass:[baseMockCLLocationManager class]];
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *result = [self.baseMockCLLocationManager methodSignatureForSelector:selector];
    if (result == nil) {
        result = [self.clLocationManager methodSignatureForSelector:selector];
    }
    return result;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([self.baseMockCLLocationManager respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.baseMockCLLocationManager];
    } else {
        NSString *selectorString = NSStringFromSelector(invocation.selector);
        SDLog(@"WARNING: Ignoring call to SDBaseMockCLLocationManager instance %@", selectorString);
    }
}

+ (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *result = [[self baseMockCLLocationManagerClass] methodSignatureForSelector:selector];
    if (result == nil) {
        result = [[CLLocationManager class] methodSignatureForSelector:selector];
    }
    return result;
}

+ (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([[self baseMockCLLocationManagerClass] respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:[self baseMockCLLocationManagerClass]];
    } else {
        NSString *selectorString = NSStringFromSelector(invocation.selector);
        SDLog(@"WARNING: Ignoring call to SDBaseMockCLLocationManager class %@", selectorString);
    }
}

@end
