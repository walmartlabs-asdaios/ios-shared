//
//  SDBaseMockCLLocationManager.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import "SDBaseMockCLLocationManager.h"
#import "NSArray+SDExtensions.h"
#import "SDLocationManager.h"
#import "SDLog.h"

#pragma mark - SDCLLocationManagerProxy

@interface SDCLLocationManagerProxy : NSProxy
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

#pragma mark - SDBaseMockCLLocationManager

@interface SDLocationManager()
@property (nonatomic, readwrite, strong) CLLocationManager *locationManager;
@end

@interface SDBaseMockCLLocationManager()
@end

@implementation SDBaseMockCLLocationManager

#pragma mark - class level properties

static CLAuthorizationStatus _authorizationStatus = kCLAuthorizationStatusNotDetermined;
static BOOL _locationServicesEnabled = NO;
static BOOL _headingAvailable = YES;
static BOOL _significantLocationChangeMonitoringAvailable = YES;
static BOOL _isRangingAvailable = YES;

+ (BOOL) locationServicesEnabled;
{
    return _locationServicesEnabled;
}

+ (void) setLocationServicesEnabled:(BOOL) locationServicesEnabled;
{
    _locationServicesEnabled = locationServicesEnabled;
}

+ (BOOL) headingAvailable;
{
    return _headingAvailable;
}

+ (void) setHeadingAvailable:(BOOL) headingAvailable;
{
    _headingAvailable = headingAvailable;
}

+ (BOOL) significantLocationChangeMonitoringAvailable;
{
    return _significantLocationChangeMonitoringAvailable;
}

+ (void) setSignificantLocationChangeMonitoringAvailable:(BOOL) significantLocationChangeMonitoringAvailable;
{
    _significantLocationChangeMonitoringAvailable = significantLocationChangeMonitoringAvailable;
}

+ (BOOL) isMonitoringAvailableForClass:(Class)regionClass;
{
    return [[self isMonitoringAvailableForClassSet] containsObject:NSStringFromClass(regionClass)];
}

+ (void) setIsMonitoringAvailable:(BOOL) isMonitoringAvailable forClass:(Class) regionClass;
{
    if (isMonitoringAvailable) {
        [[self isMonitoringAvailableForClassSet] addObject:NSStringFromClass(regionClass)];
    } else {
        [[self isMonitoringAvailableForClassSet] removeObject:NSStringFromClass(regionClass)];
    }
}

+ (BOOL) isRangingAvailable;
{
    return _isRangingAvailable;
}

+ (void) setIsRangingAvailable:(BOOL) isRangingAvailable;
{
    _isRangingAvailable = isRangingAvailable;
}

+ (CLAuthorizationStatus) authorizationStatus;
{
    return _authorizationStatus;
}

+ (void) setAuthorizationStatus:(CLAuthorizationStatus) authorizationStatus;
{
    _authorizationStatus = authorizationStatus;

    NSArray *currentInstances = [NSArray arrayWithArray:[self currentInstances]];
    for (id instance in currentInstances) {
        id<CLLocationManagerDelegate> delegate = (id) [instance delegate];
        if (delegate) {
            [delegate locationManager:instance didChangeAuthorizationStatus:authorizationStatus];
        }
        [instance updateLocations];
    }
}

#pragma mark - class level helpers

+ (NSMutableSet *) isMonitoringAvailableForClassSet;
{
    static dispatch_once_t onceToken;
    static NSMutableSet *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [NSMutableSet set];
    });
    return _instance;
}

+ (NSMutableArray *) currentInstances;
{
    static dispatch_once_t onceToken;
    static NSMutableArray *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [NSMutableArray array];
    });
    return _instance;
}

#pragma mark - instance life cycle

- (instancetype) init;
{
    if ((self = [super init])) {
        _activityType = CLActivityTypeOther;
        _pausesLocationUpdatesAutomatically = YES;
        _location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        [[[self class] currentInstances] addObject:self];
    }
    return self;
}

- (void) dealloc;
{
    [[[self class] currentInstances] removeObject:self];
}

#pragma mark - mimic location activity

- (BOOL) isAuthorized;
{
    if (self.simulateBackgroundProcess) {
        return [[self class] authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
    } else {
        return [[self class] authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse
        || [[self class] authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways;
    }
}

- (void) setLocation:(CLLocation *)location;
{
    _location = [location copy];
    [self updateLocations];
}

- (void) updateLocations;
{
    if (self.isAuthorized) {
        [self.delegate locationManager:(id)self didUpdateLocations:@[self.location]];
    }
}


// TODO: properties & delegates that are not yet mocked
//@property (nonatomic,assign) id<CLLocationManagerDelegate> delegate;
//@property (nonatomic,assign) CLActivityType activityType;
//@property (nonatomic,assign) CLLocationDistance distanceFilter;
//@property (nonatomic,assign) CLLocationAccuracy desiredAccuracy;
//@property (nonatomic,assign) BOOL pausesLocationUpdatesAutomatically;
//@property (nonatomic,assign) CLLocationDegrees headingFilter;
//@property (nonatomic,assign) CLDeviceOrientation headingOrientation;
//@property (nonatomic,copy) CLHeading *heading;
//@property (nonatomic,assign) CLLocationDistance maximumRegionMonitoringDistance;
//@property (nonatomic,strong) NSMutableSet *monitoredRegions;
//@property (nonatomic,strong) NSMutableSet *rangedRegions;

/*

*
 *  locationManager:didUpdateHeading:
 *
 *  Discussion:
 *    Invoked when a new heading is available.
 *
- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);

*
 *  locationManagerShouldDisplayHeadingCalibration:
 *
 *  Discussion:
 *    Invoked when a new heading is available. Return YES to display heading calibration info. The display
 *    will remain until heading is calibrated, unless dismissed early via dismissHeadingCalibrationDisplay.
 *
- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager  __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_3_0);

*
 *  locationManager:didDetermineState:forRegion:
 *
 *  Discussion:
 *    Invoked when there's a state transition for a monitored region or in response to a request for state via a
 *    a call to requestStateForRegion:.
 *
- (void)locationManager:(CLLocationManager *)manager
      didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);

*
 *  locationManager:didRangeBeacons:inRegion:
 *
 *  Discussion:
 *    Invoked when a new set of beacons are available in the specified region.
 *    beacons is an array of CLBeacon objects.
 *    If beacons is empty, it may be assumed no beacons that match the specified region are nearby.
 *    Similarly if a specific beacon no longer appears in beacons, it may be assumed the beacon is no longer received
 *    by the device.
 *
- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);

*
 *  locationManager:rangingBeaconsDidFailForRegion:withError:
 *
 *  Discussion:
 *    Invoked when an error has occurred ranging beacons in a region. Error types are defined in "CLError.h".
 *
- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_7_0);

*
 *  locationManager:didEnterRegion:
 *
 *  Discussion:
 *    Invoked when the user enters a monitored region.  This callback will be invoked for every allocated
 *    CLLocationManager instance with a non-nil delegate that implements this method.
 *
- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region __OSX_AVAILABLE_STARTING(__MAC_10_7,__IPHONE_4_0);

*
 *  locationManager:didExitRegion:
 *
 *  Discussion:
 *    Invoked when the user exits a monitored region.  This callback will be invoked for every allocated
 *    CLLocationManager instance with a non-nil delegate that implements this method.
 *
- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region __OSX_AVAILABLE_STARTING(__MAC_10_7,__IPHONE_4_0);

*
 *  locationManager:didFailWithError:
 *
 *  Discussion:
 *    Invoked when an error has occurred. Error types are defined in "CLError.h".
 *
- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error;

*
 *  locationManager:monitoringDidFailForRegion:withError:
 *
 *  Discussion:
 *    Invoked when a region monitoring error has occurred. Error types are defined in "CLError.h".
 *
- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(CLRegion *)region
              withError:(NSError *)error __OSX_AVAILABLE_STARTING(__MAC_10_7,__IPHONE_4_0);

 */

#pragma mark helper method

+ (instancetype) mockCLLocationManagerWith:(SDLocationManager *) sdLocationManager;
{
    id result = [[self alloc] init];
    sdLocationManager.locationManager = (id) [[SDCLLocationManagerProxy alloc] initWithBaseMockCLLocationManager:result];
    sdLocationManager.locationManager.delegate = sdLocationManager;
    return result;
}

@end

