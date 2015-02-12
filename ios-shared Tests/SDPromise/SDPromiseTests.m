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
    id resolution = @"Test resolution";
    XCTestExpectation *expectation = [self expectationWithDescription:@"single promise resolved"];

    SDPromise *promise = [[SDPromise alloc] init];
    XCTAssertFalse(promise.isFulfilled);
    [promise then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation fulfill];
        return nil;
    } fail:^id(NSError *error) {
        [expectation fulfill];
        XCTFail(@"promise should not have failed");
        return nil;
    }];

    [promise resolve:resolution];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(promise.isFulfilled);
}

- (void)testSinglePromiseReject {
    NSError *rejectionError = [NSError errorWithDomain:@"test" code:-1 userInfo:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"single promise rejected"];

    SDPromise *promise = [[SDPromise alloc] init];
    XCTAssertFalse(promise.isFulfilled);
    [promise then:^id(id dataObject) {
        XCTFail(@"promise should have failed");
        return nil;
    } fail:^id(NSError *error) {
        XCTAssertEqualObjects(rejectionError, error);
        [expectation fulfill];
        return nil;
    }];

    [promise reject:rejectionError];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(promise.isFulfilled);
}

- (void)testSinglePromiseRejectNoFailBlock {
    NSError *rejectionError = [NSError errorWithDomain:@"test" code:-1 userInfo:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"single promise rejected"];

    SDPromise *promise = [[SDPromise alloc] init];
    XCTAssertFalse(promise.isFulfilled);
    [promise then:^id(id dataObject) {
        XCTFail(@"promise should have failed");
        return nil;
    } fail:^id(NSError *error) {
        XCTAssertEqualObjects(rejectionError, error);
        [expectation fulfill];
        return nil;
    }];

    [promise reject:rejectionError];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(promise.isFulfilled);
}

- (void)testChainedPromiseResolve {
    id resolution = @"Test resolution";

    SDPromise *promise1 = [[SDPromise alloc] init];
    XCTAssertFalse(promise1.isFulfilled);

    SDPromise *promise2 = [promise1 then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        return dataObject;
    } fail:^id(NSError *error) {
        XCTFail(@"promise1 should not have failed");
        return error;
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"last promise(3) resolved"];
    SDPromise *promise3 = [promise2 then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation fulfill];
        return dataObject;
    } fail:^id(NSError *error) {
        XCTFail(@"promise2 should not have failed");
        return nil;
    }];

    [promise1 resolve:resolution];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(promise1.isFulfilled);
    XCTAssertTrue(promise2.isFulfilled);
    XCTAssertTrue(promise3.isFulfilled);
}


- (void)testTreePromiseResolve {
    id resolution = @"Test resolution";

    SDPromise *promise1 = [[SDPromise alloc] init];
    XCTAssertFalse(promise1.isFulfilled);

    SDPromise *promise2a = [promise1 then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        return dataObject;
    } fail:^id(NSError *error) {
        XCTFail(@"promise1 (from 2a) should not have failed");
        return nil;
    }];

    SDPromise *promise2b = [promise1 then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        return dataObject;
    } fail:^id(NSError *error) {
        XCTFail(@"promise1 (from 2b) should not have failed");
        return nil;
    }];

    XCTestExpectation *expectation2a1 = [self expectationWithDescription:@"promise 2a1 resolved"];
    SDPromise *promise2a1 = [promise2a then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation2a1 fulfill];
        return dataObject;
    } fail:^id(NSError *error) {
        XCTFail(@"promise2a (from 2a1) should not have failed");
        return nil;
    }];

    XCTestExpectation *expectation2a2 = [self expectationWithDescription:@"promise 2a2 resolved"];
    SDPromise *promise2a2 = [promise2a then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation2a2 fulfill];
        return dataObject;
    } fail:^id(NSError *error) {
        XCTFail(@"promise2a (from 2a2) should not have failed");
        return nil;
    }];

    XCTestExpectation *expectation2b1 = [self expectationWithDescription:@"promise 2b1 resolved"];
    SDPromise *promise2b1 = [promise2b then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation2b1 fulfill];
        return dataObject;
    } fail:^id(NSError *error) {
        XCTFail(@"promise2b (from 2b1) should not have failed");
        return nil;
    }];

    XCTestExpectation *expectation2b2 = [self expectationWithDescription:@"promise 2b2 resolved"];
    SDPromise *promise2b2 = [promise2b then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation2b2 fulfill];
        return dataObject;
    } fail:^id(NSError *error) {
        XCTFail(@"promise2b (from 2b2) should not have failed");
        return nil;
    }];

    [promise1 resolve:resolution];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertTrue(promise1.isFulfilled);
    XCTAssertTrue(promise2a.isFulfilled);
    XCTAssertTrue(promise2a1.isFulfilled);
    XCTAssertTrue(promise2a2.isFulfilled);
    XCTAssertTrue(promise2b.isFulfilled);
    XCTAssertTrue(promise2b1.isFulfilled);
    XCTAssertTrue(promise2b2.isFulfilled);
}

@end
