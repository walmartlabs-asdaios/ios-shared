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
    XCTAssertFalse(promise.isCompleted);
    [promise then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation fulfill];
        return nil;
    } reject:^id(NSError *error) {
        [expectation fulfill];
        XCTFail(@"promise should not have been rejected");
        return nil;
    }];

    [promise resolve:resolution];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(promise.isCompleted);
    XCTAssertTrue(promise.isFulfilled);
}

- (void)testSinglePromiseReject {
    NSError *rejectionError = [NSError errorWithDomain:@"test" code:-1 userInfo:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"single promise rejected"];

    SDPromise *promise = [[SDPromise alloc] init];
    XCTAssertFalse(promise.isCompleted);
    [promise then:^id(id dataObject) {
        XCTFail(@"promise should have been rejected");
        return nil;
    } reject:^id(NSError *error) {
        XCTAssertEqualObjects(rejectionError, error);
        [expectation fulfill];
        return nil;
    }];

    [promise reject:rejectionError];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(promise.isCompleted);
    XCTAssertTrue(promise.isRejected);
}

- (void)testPromisePropagateRejectThroughRejectedBlocks {
    NSError *rejectionError = [NSError errorWithDomain:@"test" code:-1 userInfo:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"single promise rejected"];

    SDPromise *promise1 = [[SDPromise alloc] init];
    XCTAssertFalse(promise1.isCompleted);
    SDPromise *promise2 = [promise1 then:^id(id dataObject) {
        XCTFail(@"promise1 should have been rejected");
        return nil;
    } reject:^id(NSError *error) {
        return error;
    }];
    [promise2 then:^id(id dataObject) {
        XCTFail(@"promise2 should have been rejected");
        return nil;
    } reject:^id(NSError *error) {
        [expectation fulfill];
        return nil;
    }];

    [promise1 reject:rejectionError];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(promise1.isCompleted);
    XCTAssertTrue(promise2.isCompleted);
    XCTAssertTrue(promise1.isRejected);
    XCTAssertTrue(promise2.isRejected);
}

- (void)testPromisePropagateRejectWithMissingRejectedBlock {
    NSError *rejectionError = [NSError errorWithDomain:@"test" code:-1 userInfo:nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"single promise rejected"];

    SDPromise *promise1 = [[SDPromise alloc] init];
    XCTAssertFalse(promise1.isCompleted);
    SDPromise *promise2 = [promise1 then:^id(id dataObject) {
        XCTFail(@"promise1 should have been rejected");
        return nil;
    }];
    [promise2 then:^id(id dataObject) {
        XCTFail(@"promise2 should have been rejected");
        return nil;
    } reject:^id(NSError *error) {
        [expectation fulfill];
        return nil;
    }];

    [promise1 reject:rejectionError];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(promise1.isCompleted);
    XCTAssertTrue(promise2.isCompleted);
    XCTAssertTrue(promise1.isRejected);
    XCTAssertTrue(promise2.isRejected);
}

- (void)testChainedPromiseResolve {
    id resolution = @"Test resolution";

    SDPromise *promise1 = [[SDPromise alloc] init];
    XCTAssertFalse(promise1.isCompleted);

    SDPromise *promise2 = [promise1 then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        return dataObject;
    } reject:^id(NSError *error) {
        XCTFail(@"promise1 should not have been rejected");
        return error;
    }];

    XCTestExpectation *expectation = [self expectationWithDescription:@"last promise(3) resolved"];
    SDPromise *promise3 = [promise2 then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation fulfill];
        return dataObject;
    } reject:^id(NSError *error) {
        XCTFail(@"promise2 should not have been rejected");
        return nil;
    }];

    [promise1 resolve:resolution];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];

    XCTAssertTrue(promise1.isCompleted);
    XCTAssertTrue(promise2.isCompleted);
    XCTAssertTrue(promise3.isCompleted);
    XCTAssertTrue(promise1.isFulfilled);
    XCTAssertTrue(promise2.isFulfilled);
    XCTAssertTrue(promise3.isFulfilled);
}


- (void)testTreePromiseResolve {
    id resolution = @"Test resolution";

    SDPromise *promise1 = [[SDPromise alloc] init];
    XCTAssertFalse(promise1.isCompleted);

    SDPromise *promise2a = [promise1 then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        return dataObject;
    } reject:^id(NSError *error) {
        XCTFail(@"promise1 (from 2a) should not have been rejected");
        return nil;
    }];

    SDPromise *promise2b = [promise1 then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        return dataObject;
    } reject:^id(NSError *error) {
        XCTFail(@"promise1 (from 2b) should not have been rejected");
        return nil;
    }];

    XCTestExpectation *expectation2a1 = [self expectationWithDescription:@"promise 2a1 resolved"];
    SDPromise *promise2a1 = [promise2a then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation2a1 fulfill];
        return dataObject;
    } reject:^id(NSError *error) {
        XCTFail(@"promise2a (from 2a1) should not have been rejected");
        return nil;
    }];

    XCTestExpectation *expectation2a2 = [self expectationWithDescription:@"promise 2a2 resolved"];
    SDPromise *promise2a2 = [promise2a then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation2a2 fulfill];
        return dataObject;
    } reject:^id(NSError *error) {
        XCTFail(@"promise2a (from 2a2) should not have been rejected");
        return nil;
    }];

    XCTestExpectation *expectation2b1 = [self expectationWithDescription:@"promise 2b1 resolved"];
    SDPromise *promise2b1 = [promise2b then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation2b1 fulfill];
        return dataObject;
    } reject:^id(NSError *error) {
        XCTFail(@"promise2b (from 2b1) should not have been rejected");
        return nil;
    }];

    XCTestExpectation *expectation2b2 = [self expectationWithDescription:@"promise 2b2 resolved"];
    SDPromise *promise2b2 = [promise2b then:^id(id dataObject) {
        XCTAssertEqualObjects(resolution, dataObject);
        [expectation2b2 fulfill];
        return dataObject;
    } reject:^id(NSError *error) {
        XCTFail(@"promise2b (from 2b2) should not have been rejected");
        return nil;
    }];

    [promise1 resolve:resolution];

    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertTrue(promise1.isCompleted);
    XCTAssertTrue(promise2a.isCompleted);
    XCTAssertTrue(promise2a1.isCompleted);
    XCTAssertTrue(promise2a2.isCompleted);
    XCTAssertTrue(promise2b.isCompleted);
    XCTAssertTrue(promise2b1.isCompleted);
    XCTAssertTrue(promise2b2.isCompleted);
    XCTAssertTrue(promise1.isFulfilled);
    XCTAssertTrue(promise2a.isFulfilled);
    XCTAssertTrue(promise2a1.isFulfilled);
    XCTAssertTrue(promise2a2.isFulfilled);
    XCTAssertTrue(promise2b.isFulfilled);
    XCTAssertTrue(promise2b1.isFulfilled);
    XCTAssertTrue(promise2b2.isFulfilled);
}

@end
