//
//  CLLocationManagerManualMockProvider.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import "CLLocationManagerManualMockProvider.h"
#import "CLLocationManagerProxy.h"

@interface CLLocationManagerManualMockProvider()
@property (nonatomic,strong,readwrite) id<CLLocationManagerDelegate> clLocationManagerDelegate;
@property (nonatomic,strong) CLLocationManager *locationManagerProxy;
@property (nonatomic,assign) BOOL isUpdating;
@end

@implementation CLLocationManagerManualMockProvider

@synthesize isUpdating = _isUpdating;
@synthesize location = _location;
@synthesize distanceFilter = _distanceFilter;
@synthesize desiredAccuracy = _desiredAccuracy;
@synthesize authorizationStatus = _authorizationStatus;

- (instancetype) initWithCLLocationManagerDelegate:(id<CLLocationManagerDelegate>) clLocationManagerDelegate;
{
    if ((self = [super init])) {
        _clLocationManagerDelegate = clLocationManagerDelegate;

        // use proxy as source to catch any cases where SDLocationManagerDelegate instances
        // do something we don't expect
        CLLocationManagerProxy *proxy = [[CLLocationManagerProxy alloc] initWithObject:[CLLocationManager new]];
        proxy.failOnMethodCallMessage = @"CLLocationManager should not be used while mockUpdateProvider is active";
        _locationManagerProxy = (id) proxy;
    }
    return self;
}

- (void)requestAlwaysAuthorization;
{
}

- (void)requestWhenInUseAuthorization;
{
}

- (void)startUpdatingLocation;
{
    self.isUpdating = YES;
}

- (void)stopUpdatingLocation;
{
    self.isUpdating = NO;
}

- (void) updateLocation;
{
    if ([self.clLocationManagerDelegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        [self.clLocationManagerDelegate locationManager:self.locationManagerProxy didUpdateLocations:@[self.location]];
    }
}

- (BOOL) isUpdating;
{
    @synchronized(self) {
        return _isUpdating;
    }
}

- (void) setIsUpdating:(BOOL)isUpdating;
{
    BOOL callUpdateLocation = NO;
    @synchronized(self) {
        if (_isUpdating != isUpdating) {
            _isUpdating = isUpdating;
            callUpdateLocation = isUpdating;
        }
    }
    if (callUpdateLocation) {
        [self updateLocation];
    }
}


- (void) setLocation:(CLLocation *)location;
{
    BOOL callUpdateLocation = NO;
    @synchronized(self) {
        if (![location isEqual:_location]) {
            _location = [location copy];
            callUpdateLocation = (location != nil);
        }
    }
    if (callUpdateLocation) {
        [self updateLocation];
    }
}

/*
 Mocked CLLocationManagerDelegate methods
    locationManager:didUpdateLocations:
*/

/*

- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);

- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region __OSX_AVAILABLE_STARTING(__MAC_10_7,__IPHONE_4_0);

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region __OSX_AVAILABLE_STARTING(__MAC_10_7,__IPHONE_4_0);

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error;

- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(CLRegion *)region
              withError:(NSError *)error __OSX_AVAILABLE_STARTING(__MAC_10_7,__IPHONE_4_0);

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status __OSX_AVAILABLE_STARTING(__MAC_10_7,__IPHONE_4_2);

- (void)locationManager:(CLLocationManager *)manager
didStartMonitoringForRegion:(CLRegion *)region __OSX_AVAILABLE_STARTING(__MAC_TBD,__IPHONE_5_0);

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_6_0);

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_6_0);

- (void)locationManager:(CLLocationManager *)manager
didFinishDeferredUpdatesWithError:(NSError *)error __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_6_0);

- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit;
 */


@end
