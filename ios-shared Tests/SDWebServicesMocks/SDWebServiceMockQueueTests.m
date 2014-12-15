//
//  SDWebServiceMockQueueTests.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 11/10/14.
//  Copyright (c) 2014 SetDirection. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SDWebService.h"

@interface SDWebServiceMockQueueTests : XCTestCase
@property (nonatomic,strong) SDWebService *webService;
@property (nonatomic,strong) NSBundle *bundle;
@end

@implementation SDWebServiceMockQueueTests

- (void)setUp;
{
    [super setUp];

    self.bundle = [NSBundle bundleForClass:[self class]];

    self.webService = [[SDWebService alloc] initWithSpecification:@"SDWebServiceMockTests" host:@"testhost" path:@"/"];
    self.webService.maxConcurrentOperationCount = 1; // to ensure predictable testing
}

- (void)testDefaultAutoPop;
{
    XCTAssertTrue(self.webService.autoPopMocks);
}

- (void) checkWebServiceWithBlock:(void (^)(NSData *responseData, NSError *error)) block;
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"webService request completed"];
    [self.webService performRequestWithMethod:@"testGETNoRouteParams"
                                      headers:nil
                            routeReplacements:nil
                          dataProcessingBlock:^id(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                              block(responseData, error);
                              [expectation fulfill];
                              return nil;
                          } uiUpdateBlock:nil];
}

- (NSData *) pushMockResponseWithFilename:(NSString *) filename;
{
    [self.webService pushMockResponseFile:filename bundle:self.bundle];
    NSString *filepath = [self.bundle pathForResource:filename ofType:nil];
    return [NSData dataWithContentsOfFile:filepath];
}

- (void)testSingleMockResponseWithAutoPop;
{
    NSData *checkData = [self pushMockResponseWithFilename:@"SDWebServiceMockTest_bundleA.json"];

    [self checkWebServiceWithBlock:^(NSData *responseData, NSError *error) {
        XCTAssertEqualObjects(checkData, responseData, @"mock should supply data from mock response pushed above");
    }];

    [self checkWebServiceWithBlock:^(NSData *responseData, NSError *error) {
        XCTAssertEqual(0, [responseData length], @"mock should NOT supply data from mock response pushed above");
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testSingleMockResponseWithNoAutoPop;
{
    NSData *checkData = [self pushMockResponseWithFilename:@"SDWebServiceMockTest_bundleA.json"];

    self.webService.autoPopMocks = NO;

    [self checkWebServiceWithBlock:^(NSData *responseData, NSError *error) {
        XCTAssertEqualObjects(checkData, responseData, @"mock should supply data from mock response pushed above");
    }];

    [self checkWebServiceWithBlock:^(NSData *responseData, NSError *error) {
        XCTAssertEqualObjects(checkData, responseData, @"mock should supply data from mock response pushed above");
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testSingleMockResponseWithManualPop;
{
    NSData *checkData = [self pushMockResponseWithFilename:@"SDWebServiceMockTest_bundleA.json"];

    [self checkWebServiceWithBlock:^(NSData *responseData, NSError *error) {
        XCTAssertEqualObjects(checkData, responseData, @"mock should supply data from mock response pushed above");
    }];

    [self.webService popMockResponseFile];

    [self checkWebServiceWithBlock:^(NSData *responseData, NSError *error) {
        XCTAssertEqual(0, [responseData length], @"mock should NOT supply data from mock response pushed above");
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
