//
//  SDPromiseTests.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/11/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SDPromise.h"

@interface SDPromiseTests : XCTestCase
@end

@implementation SDPromiseTests

- (void)setUp {
    [super setUp];
}

- (void)testSinglePromiseResolve {
    SDPromise *promise = [[SDPromise alloc] init];
    XCTAssertFalse(promise.isFulfilled);

    id resolution = @"Test resolution";

    XCTestExpectation *expectation = [self expectationWithDescription:@"then"];
    [promise then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation fulfill];
        return nil;
    }];
    [promise failed:^(NSError *error) {
        [expectation fulfill];
        XCTFail(@"promise should not have failed");
    }];

    [promise resolve:resolution];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertTrue(promise.isFulfilled);
}

- (void)testSinglePromiseReject {
    SDPromise *promise = [[SDPromise alloc] init];
    XCTAssertFalse(promise.isFulfilled);

    NSError *rejectionError = [NSError errorWithDomain:@"test" code:-1 userInfo:nil];

    XCTestExpectation *expectation = [self expectationWithDescription:@"then"];
    [promise then:^id(id dataObject) {
        [expectation fulfill];
        XCTFail(@"promise should have failed");
        return nil;
    }];
    [promise failed:^(NSError *error) {
        XCTAssertEqualObjects(rejectionError, error);
        [expectation fulfill];
    }];

    [promise reject:rejectionError];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertTrue(promise.isFulfilled);
}

@end
