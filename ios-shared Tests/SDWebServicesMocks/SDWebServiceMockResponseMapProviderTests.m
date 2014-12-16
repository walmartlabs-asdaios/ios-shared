//
//  SDWebServiceMockResponseMapProviderTests.m
//  ios-shared
//
//  Created by Douglas Sjoquist on 12/15/14.
//  Copyright (c) 2014 SetDirection. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "SDWebService.h"
#import "SDWebServiceMockResponseProvider.h"
#import "SDWebServiceMockResponseQueueProvider.h"
#import "SDWebServiceMockResponseMapProvider.h"
#import "SDWebServiceMockResponseRequestMapping.h"

@interface TestSDWebServiceC : SDWebService
@property (nonatomic,weak) XCTestCase *testCase;
@end
@implementation TestSDWebServiceC
- (SDWebServiceMockResponseQueueProvider *)checkForMockResponseQueueProvider
{
    _XCTPrimitiveFail(self.testCase, @"Should not call checkForMockResponseQueueProvider (methods in SDWebService are deprecated, use methods on mockResponseProvider instance directly");
    return nil;
}
@end

@interface SDWebServiceMockResponseMapProviderTests : XCTestCase
@property (nonatomic,strong) TestSDWebServiceC *webService;
@property (nonatomic,strong) SDWebServiceMockResponseMapProvider *mockResponseMapProvider;
@property (nonatomic,strong) NSBundle *bundle;
@end

@implementation SDWebServiceMockResponseMapProviderTests

- (void)setUp {
    [super setUp];

    self.bundle = [NSBundle bundleForClass:[self class]];

    self.webService = [[TestSDWebServiceC alloc] initWithSpecification:@"SDWebServiceMockTests"];
    self.webService.testCase = self;
    self.webService.maxConcurrentOperationCount = 1; // to ensure predictable testing

    self.mockResponseMapProvider = [[SDWebServiceMockResponseMapProvider alloc] init];
    self.webService.mockResponseProvider = self.mockResponseMapProvider;
}

#pragma mark - pragma helper methods

- (void) checkWebServiceWithMethod:(NSString *) method
                      replacements:(NSDictionary *) replacements
                             block:(void (^)(NSData *responseData, NSError *error)) block
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"webService request completed"];
    [self.webService performRequestWithMethod:method
                                      headers:nil
                            routeReplacements:replacements
                          dataProcessingBlock:^id(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                              block(responseData, error);
                              [expectation fulfill];
                              return nil;
                          } uiUpdateBlock:nil];
}

- (NSData *) mapMockResponseWithFilename:(NSString *) filename mapping:(SDWebServiceMockResponseRequestMapping *) mapping maximumResponses:(NSUInteger) maximumResponses
{
    [self.mockResponseMapProvider addMockResponseFile:filename bundle:self.bundle forRequestMapping:mapping maximumResponses:maximumResponses];
    NSString *filepath = [self.bundle pathForResource:filename ofType:nil];
    return [NSData dataWithContentsOfFile:filepath];
}

#pragma mark - single response tests

- (void)testSingleSimpleMockResponse
{
    SDWebServiceMockResponseRequestMapping *mapping =
    [[SDWebServiceMockResponseRequestMapping alloc]
     initWithPath:@"^/api/route$" queryParameters:nil];
    NSData *checkDataA = [self mapMockResponseWithFilename:@"SDWebServiceMockTest_bundleA.json" mapping:mapping maximumResponses:1];

    [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                       replacements:nil
                              block:^(NSData *responseData, NSError *error) {
                                  XCTAssertEqualObjects(checkDataA, responseData, @"mock should supply data from mock response A mapped above");
                              }];

    [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                       replacements:nil
                              block:^(NSData *responseData, NSError *error) {
                                  XCTAssertEqual(0, [responseData length], @"mock should NOT supply data from any mock response");
                              }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testMultipleSimpleMockResponses
{
    SDWebServiceMockResponseRequestMapping *mapping =
    [[SDWebServiceMockResponseRequestMapping alloc]
     initWithPath:@"^/api/route$" queryParameters:nil];

    NSUInteger maximumResponsesA = 3;
    NSData *checkDataA = [self mapMockResponseWithFilename:@"SDWebServiceMockTest_bundleA.json" mapping:mapping maximumResponses:maximumResponsesA];
    NSUInteger maximumResponsesB = 2;
    NSData *checkDataB = [self mapMockResponseWithFilename:@"SDWebServiceMockTest_bundleB.json" mapping:mapping maximumResponses:maximumResponsesB];

    for (NSInteger idx=0; idx<maximumResponsesA; idx++) {
        [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                           replacements:nil
                                  block:^(NSData *responseData, NSError *error) {
                                      XCTAssertEqualObjects(checkDataA, responseData, @"mock should supply data from mock response A mapped above");
                                  }];
    }
    for (NSInteger idx=0; idx<maximumResponsesB; idx++) {
        [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                           replacements:nil
                                  block:^(NSData *responseData, NSError *error) {
                                      XCTAssertEqualObjects(checkDataB, responseData, @"mock should supply data from mock response A mapped above");
                                  }];
    }
    [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                       replacements:nil
                              block:^(NSData *responseData, NSError *error) {
                                  XCTAssertEqual(0, [responseData length], @"mock should NOT supply data from any mock response");
                              }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end