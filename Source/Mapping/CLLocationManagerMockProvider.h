//
//  CLLocationManagerMockProvider.h
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 Asda. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@protocol CLLocationManagerMockProvider <NSObject>

@property (nonatomic,copy) CLLocation *location;
@property (nonatomic,assign) CLLocationDistance distanceFilter;
@property (nonatomic,assign) CLLocationAccuracy desiredAccuracy;
@property (nonatomic,assign) CLAuthorizationStatus authorizationStatus;

- (void)requestAlwaysAuthorization;
- (void)requestWhenInUseAuthorization;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end
