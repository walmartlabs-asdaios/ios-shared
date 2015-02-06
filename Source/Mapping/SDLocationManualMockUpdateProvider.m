//
//  SDLocationManualMockUpdateProvider.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import "SDLocationManualMockUpdateProvider.h"

@implementation SDLocationManualMockUpdateProvider

@synthesize location = _location;
@synthesize distanceFilter = _distanceFilter;
@synthesize desiredAccuracy = _desiredAccuracy;
@synthesize authorizationStatus = _authorizationStatus;

- (void)requestAlwaysAuthorization;
{
}

- (void)requestWhenInUseAuthorization;
{
}

- (void)startUpdatingLocation;
{
}

- (void)stopUpdatingLocation;
{
}

- (void)locationUpdatesWillStartWithDelegate:(id<SDLocationManagerDelegate>)delegate desiredAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distanceFilter;
{
}

- (void)locationUpdatesDidStopWithDelegate:(id<SDLocationManagerDelegate>)delegate;
{
}

- (NSTimeInterval) getNextMockUpdateInterval;
{
    return 0.0f;
}

- (id) getMockLocationUpdate;
{
    return nil;
}

@end
