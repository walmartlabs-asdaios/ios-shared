//
//  SDLocationMockUpdateProvider.h
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 Asda. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@protocol SDLocationManagerDelegate;

//@interface SDMockLocationUpdate : NSObject
//@end
//
//@implementation SDMockLocationUpdate
//@end
//
/**
 SDLocationManager uses implementations of SDLocationMockUpdateProvider to provide mock updates.
 */
@protocol SDLocationMockUpdateProvider <NSObject>

@property (nonatomic,copy) CLLocation *location;
@property (nonatomic,assign) CLLocationDistance distanceFilter;
@property (nonatomic,assign) CLLocationAccuracy desiredAccuracy;
@property (nonatomic,assign) CLAuthorizationStatus authorizationStatus;

- (void)requestAlwaysAuthorization;
- (void)requestWhenInUseAuthorization;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

- (void)locationUpdatesWillStartWithDelegate:(id<SDLocationManagerDelegate>)delegate desiredAccuracy:(CLLocationAccuracy)accuracy distanceFilter:(CLLocationDistance)distanceFilter;
- (void)locationUpdatesDidStopWithDelegate:(id<SDLocationManagerDelegate>)delegate;

- (NSTimeInterval) getNextMockUpdateInterval;
- (id) getMockLocationUpdate;

/*
   - (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation __deprecated__("Use locationManager:didUpdateLocations: instead");;
   - (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
   - (void)locationManager:(CLLocationManager *)manager didUpdateToInaccurateLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
   - (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);
   - (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_4_0);
   - (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_4_0);
   - (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
*/

@end
