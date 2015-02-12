//
//  NSObject+SDExtensionsTests.m
//  ios-shared
//
//  Created by Brandon Sneed on 7/10/14.
//  Copyright (c) 2014 SetDirection. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface NSObject_SDExtensionsTests : XCTestCase

@end

@implementation NSObject_SDExtensionsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAsyncWait {
    
    __block BOOL slept = NO;
    __block BOOL completed = NO;
    __block NSNumber *performThreadWasMain = nil;
    __block NSNumber *completionThreadWasMain = nil;
    XCTestExpectation *performExpectation = [self expectationWithDescription:@"perform"];
    XCTestExpectation *completeExpectation = [self expectationWithDescription:@"complete"];
    [self performBlockInBackground:^{
        sleep(5);
        slept = YES;
        performThreadWasMain = @([NSThread isMainThread]);
        [performExpectation fulfill];
    } completion:^{
        completed = YES;
        completionThreadWasMain = @([NSThread isMainThread]);
        [completeExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue(slept, "The async task was supposed to sleep for 5 seconds, and it didn't!");
    XCTAssertTrue(completed, "The async task was supposed to complete, and it didn't!");
    XCTAssertTrue((performThreadWasMain != nil) && ![performThreadWasMain boolValue], @"perform thread should not be main thread, but it was");
    XCTAssertTrue((completionThreadWasMain != nil) && [completionThreadWasMain boolValue], @"completion thread should be main thread, but it wasn't");
}

@end
