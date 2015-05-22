//
//  SDBaseMockCLLocationManagerTests.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import "SDBaseMockCLLocationManager.h"
#import "SDLocationManager.h"
#import "SDLocationManagerTestingDelegate.h"

@interface SDLocationManager ()
@property (nonatomic,strong) CLLocationManager *locationManager;
@end

@interface SDBaseMockCLLocationManagerTests : XCTestCase<SDLocationManagerDelegate>
@property (nonatomic,strong) SDLocationManager *locationManager;
@property (nonatomic,strong) SDBaseMockCLLocationManager *mock;
@end

@implementation SDBaseMockCLLocationManagerTests

- (void)setUp {
    [super setUp];

    self.locationManager = [[SDLocationManager alloc] init];
    self.mock = [SDBaseMockCLLocationManager mockCLLocationManagerWith:self.locationManager];
}

- (void)testNotDetermined {
    SDLocationManagerTestingDelegate *testingDelegate = [[SDLocationManagerTestingDelegate alloc] init];
    [[self.mock class] setAuthorizationStatus:kCLAuthorizationStatusNotDetermined];
    [self.locationManager startUpdatingLocationWithDelegate:testingDelegate desiredAccuracy:1000.0];
    self.mock.location = [[CLLocation alloc] initWithLatitude:40.0 longitude:-80];

    NSUInteger count = [testingDelegate receivedMessageCountForSelector:@selector(locationManager:didUpdateLocations:)];
    XCTAssertEqual(0, count, @"didUpdateLocations should NOT have been called");
}

- (void)testAuthorizedAlwaysInForeground {
    self.mock.simulateBackgroundProcess = NO;
    SDLocationManagerTestingDelegate *testingDelegate = [[SDLocationManagerTestingDelegate alloc] init];
    [[self.mock class] setAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];
    [self.locationManager startUpdatingLocationWithDelegate:testingDelegate desiredAccuracy:1000.0];
    self.mock.location = [[CLLocation alloc] initWithLatitude:40.0 longitude:-80];

    NSUInteger count = [testingDelegate receivedMessageCountForSelector:@selector(locationManager:didUpdateLocations:)];
    XCTAssertEqual(1, count, @"didUpdateLocations should have been called once");
}

- (void)testAuthorizedAlwaysInBackground {
    self.mock.simulateBackgroundProcess = YES;
    SDLocationManagerTestingDelegate *testingDelegate = [[SDLocationManagerTestingDelegate alloc] init];
    [[self.mock class] setAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];
    [self.locationManager startUpdatingLocationWithDelegate:testingDelegate desiredAccuracy:1000.0];
    self.mock.location = [[CLLocation alloc] initWithLatitude:40.0 longitude:-80];

    NSUInteger count = [testingDelegate receivedMessageCountForSelector:@selector(locationManager:didUpdateLocations:)];
    XCTAssertEqual(1, count, @"didUpdateLocations should have been called once");
}

- (void)testAuthorizedWhenInUseInForeground {
    self.mock.simulateBackgroundProcess = NO;
    SDLocationManagerTestingDelegate *testingDelegate = [[SDLocationManagerTestingDelegate alloc] init];
    [[self.mock class] setAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse];
    [self.locationManager startUpdatingLocationWithDelegate:testingDelegate desiredAccuracy:1000.0];
    self.mock.location = [[CLLocation alloc] initWithLatitude:40.0 longitude:-80];

    NSUInteger count = [testingDelegate receivedMessageCountForSelector:@selector(locationManager:didUpdateLocations:)];
    XCTAssertEqual(1, count, @"didUpdateLocations should have been called once");
}

- (void)testAuthorizedWhenInUseInBackground {
    self.mock.simulateBackgroundProcess = YES;
    SDLocationManagerTestingDelegate *testingDelegate = [[SDLocationManagerTestingDelegate alloc] init];
    [[self.mock class] setAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse];
    [self.locationManager startUpdatingLocationWithDelegate:testingDelegate desiredAccuracy:1000.0];
    self.mock.location = [[CLLocation alloc] initWithLatitude:40.0 longitude:-80];

    NSUInteger count = [testingDelegate receivedMessageCountForSelector:@selector(locationManager:didUpdateLocations:)];
    XCTAssertEqual(0, count, @"didUpdateLocations should NOT have been called");
}

@end
