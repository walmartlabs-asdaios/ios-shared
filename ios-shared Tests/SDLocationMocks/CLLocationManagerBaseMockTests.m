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
#import "SDCLLocationManagerProxy.h"
#import "SDBaseMockCLLocationManager.h"
#import "SDLocationManager.h"
#import "SDLocationManagerTestingDelegate.h"

@interface SDLocationManager ()
@property (nonatomic,strong) CLLocationManager *locationManager;
@end

@interface SDBaseMockCLLocationManagerTests : XCTestCase<SDLocationManagerDelegate>
@property (nonatomic,strong) SDLocationManager *locationManager;
@property (nonatomic,strong) SDBaseMockCLLocationManager *mock;
@property (nonatomic,strong) SDLocationManagerTestingDelegate *testingDelegate;
@end

@implementation SDBaseMockCLLocationManagerTests

- (void)setUp {
    [super setUp];

    self.testingDelegate = [[SDLocationManagerTestingDelegate alloc] init];
    self.locationManager = [[SDLocationManager alloc] init];
    self.mock = [[SDBaseMockCLLocationManager alloc] init];
    self.locationManager.locationManager = (id) [[SDCLLocationManagerProxy alloc] initWithBaseMockCLLocationManager:self.mock];
    self.locationManager.locationManager.delegate = self.locationManager;
}

- (void)testNotDetermined {
    [[self.mock class] setAuthorizationStatus:kCLAuthorizationStatusNotDetermined];
    [self.locationManager startUpdatingLocationWithDelegate:self.testingDelegate desiredAccuracy:1000.0];
    self.mock.location = [[CLLocation alloc] initWithLatitude:40.0 longitude:-80];
    XCTAssertTrue(self.testingDelegate.receivedMessageCount == 0, @"no methods should have been called on the delegate");
}

- (void)testAuthorizedAlways {
    [[self.mock class] setAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];
    [self.locationManager startUpdatingLocationWithDelegate:self.testingDelegate desiredAccuracy:1000.0];
    self.mock.location = [[CLLocation alloc] initWithLatitude:40.0 longitude:-80];
    XCTAssertTrue(self.testingDelegate.receivedMessageCount > 0, @"some methods should have been called on the delegate");
}

@end
