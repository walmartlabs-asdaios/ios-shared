//
//  CLLocationManagerManualMockProviderTests.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import "CLLocationManagerProxy.h"
#import "CLLocationManagerManualMockProvider.h"

@interface SDLocationManager ()
@property (nonatomic,strong) CLLocationManager *locationManager;
@end

@interface CLLocationManagerManualMockProviderTests : XCTestCase<SDLocationManagerDelegate>
@property (nonatomic,strong) SDLocationManager *locationManager;
@property (nonatomic,strong) CLLocationManagerProxy *locationManagerProxy;
@end

@implementation CLLocationManagerManualMockProviderTests

- (void)setUp {
    [super setUp];

    self.locationManager = [[SDLocationManager alloc] init];
    self.locationManager.mockUpdateProvider = [[CLLocationManagerManualMockProvider alloc] init];
    self.locationManagerProxy = [[CLLocationManagerProxy alloc] initWithObject:self.locationManager.locationManager];
    self.locationManager.locationManager = (id) self.locationManagerProxy;
}

- (void)tearDown {
    XCTAssertEqual(0, [self.locationManagerProxy.receivedMessageCounts count], @"No methods on CLLocationManager should ever have been called when using mock provider");
    [super tearDown];
}

- (void)testExample {
    [self.locationManager startUpdatingLocationWithDelegate:self desiredAccuracy:1000.0];
    NSLog(@"%@", self.locationManagerProxy.receivedMessageCounts);
}

@end
