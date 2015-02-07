//
//  SDLocationManagerTestingDelegate.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import "SDLocationManagerTestingDelegate.h"

@interface SDLocationManagerTestingDelegate()
@property (nonatomic,strong) NSMutableDictionary *receivedMessageCounts;
@property (nonatomic,strong) NSString *failOnMethodCallMessage;

- (NSUInteger)receivedMessageCountForSelector:(SEL)selector;

@end


@implementation SDLocationManagerTestingDelegate

- (instancetype)init;
{
    _receivedMessageCounts = [[NSMutableDictionary alloc] init];
    return self;
}

- (NSUInteger) receivedMessageCount;
{
    __block NSUInteger result = 0;
    [self.receivedMessageCounts enumerateKeysAndObjectsUsingBlock:^(NSString *selectorStr, NSNumber *count, BOOL *stop) {
        result += [count integerValue];
    }];
    return result;
}

- (NSUInteger)receivedMessageCountForSelector:(SEL)selector;
{
    return [self.receivedMessageCounts[NSStringFromSelector(selector)] unsignedIntegerValue];
}

- (void) recordMessage:(NSString *) selectorString;
{
    NSUInteger count = [self.receivedMessageCounts[selectorString] unsignedIntegerValue];
    self.receivedMessageCounts[selectorString] = @(count+1);
}

#define SELECTORSTR(s) [[[[NSString stringWithCString:s encoding:NSUTF8StringEncoding] componentsSeparatedByString:@" "] lastObject]  stringByReplacingOccurrencesOfString:@"]" withString:@""]

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
{
    [self recordMessage:SELECTORSTR(__FUNCTION__)];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
{
    [self recordMessage:SELECTORSTR(__FUNCTION__)];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToInaccurateLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
{
    [self recordMessage:SELECTORSTR(__FUNCTION__)];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading;
{
    [self recordMessage:SELECTORSTR(__FUNCTION__)];
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager;
{
    [self recordMessage:SELECTORSTR(__FUNCTION__)];
    return YES;
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region;
{
    [self recordMessage:SELECTORSTR(__FUNCTION__)];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region;
{
    [self recordMessage:SELECTORSTR(__FUNCTION__)];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
{
    [self recordMessage:SELECTORSTR(__FUNCTION__)];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error;
{
    [self recordMessage:SELECTORSTR(__FUNCTION__)];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
{
    [self recordMessage:SELECTORSTR(__FUNCTION__)];
}

@end
