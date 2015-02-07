//
//  SDBaseMockCLLocationManager.h
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@class SDLocationManager;

@interface SDBaseMockCLLocationManager : NSObject

@property (nonatomic,assign,readonly) BOOL isAuthorized;
@property (nonatomic,assign) BOOL simulateBackgroundProcess;

@property (nonatomic,assign) id<CLLocationManagerDelegate> delegate;
@property (nonatomic,assign) CLActivityType activityType;
@property (nonatomic,assign) CLLocationDistance distanceFilter;
@property (nonatomic,assign) CLLocationAccuracy desiredAccuracy;
@property (nonatomic,assign) BOOL pausesLocationUpdatesAutomatically;
@property (nonatomic,copy) CLLocation *location;
@property (nonatomic,assign) CLLocationDegrees headingFilter;
@property (nonatomic,assign) CLDeviceOrientation headingOrientation;
@property (nonatomic,copy) CLHeading *heading;
@property (nonatomic,assign) CLLocationDistance maximumRegionMonitoringDistance;
@property (nonatomic,strong) NSMutableSet *monitoredRegions;
@property (nonatomic,strong) NSMutableSet *rangedRegions;

+ (BOOL) locationServicesEnabled;
+ (void) setLocationServicesEnabled:(BOOL) locationServicesEnabled;

+ (BOOL) headingAvailable;
+ (void) setHeadingAvailable:(BOOL) headingAvailable;

+ (BOOL) significantLocationChangeMonitoringAvailable;
+ (void) setSignificantLocationChangeMonitoringAvailable:(BOOL) significantLocationChangeMonitoringAvailable;

+ (BOOL) isMonitoringAvailableForClass:(Class)regionClass;
+ (void) setIsMonitoringAvailable:(BOOL) isMonitoringAvailable forClass:(Class) regionClass;

+ (BOOL) isRangingAvailable;
+ (void) setIsRangingAvailable:(BOOL) isRangingAvailable;

+ (CLAuthorizationStatus) authorizationStatus;
+ (void) setAuthorizationStatus:(CLAuthorizationStatus) authorizationStatus;


#pragma mark helper method

+ (instancetype) mockCLLocationManagerWith:(SDLocationManager *) sdLocationManager;

@end
