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
                             block:(void (^)(NSURLResponse*, NSInteger, NSData*, NSError*)) block
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"webService request completed"];
    [self.webService performRequestWithMethod:method
                                      headers:nil
                            routeReplacements:replacements
                          dataProcessingBlock:^id(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                              block(response, responseCode, responseData, error);
                              [expectation fulfill];
                              return nil;
                          } uiUpdateBlock:nil];
}

- (NSData *) mapMockDataWithFilename:(NSString *) filename mapping:(SDWebServiceMockResponseRequestMapping *) mapping maximumResponses:(NSUInteger) maximumResponses
{
    [self.mockResponseMapProvider addMockDataFile:filename bundle:self.bundle forRequestMapping:mapping maximumResponses:maximumResponses];
    NSString *filepath = [self.bundle pathForResource:filename ofType:nil];
    return [NSData dataWithContentsOfFile:filepath];
}

- (NSData *) mapMockHTTPURLResponseWithFilename:(NSString *) filename mapping:(SDWebServiceMockResponseRequestMapping *) mapping maximumResponses:(NSUInteger) maximumResponses
{
    [self.mockResponseMapProvider addMockHTTPURLResponseFile:filename bundle:self.bundle forRequestMapping:mapping maximumResponses:maximumResponses];
    NSString *filepath = [self.bundle pathForResource:filename ofType:nil];
    return [NSData dataWithContentsOfFile:filepath];
}

#pragma mark - simple match response data tests

- (void)testSingleSimpleMockDataResponse
{
    SDWebServiceMockResponseRequestMapping *mapping =
    [[SDWebServiceMockResponseRequestMapping alloc]
     initWithPath:@"^/api/route$" queryParameters:nil];
    NSData *checkDataA = [self mapMockDataWithFilename:@"SDWebServiceMockTest_bundleA.json" mapping:mapping maximumResponses:1];
    NSLog(@"expected:\n%@", [[NSString alloc] initWithData:checkDataA encoding:NSUTF8StringEncoding]);

    [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                       replacements:nil
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  NSLog(@"actual:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                                  XCTAssertNil(response);
                                  XCTAssertEqualObjects(checkDataA, responseData, @"mock should supply data from mock response A mapped above");
                              }];

    [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                       replacements:nil
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  XCTAssertNil(response);
                                  XCTAssertEqual(0, [responseData length], @"mock should NOT supply data from any mock response");
                              }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testMultipleSimpleMockDataResponses
{
    SDWebServiceMockResponseRequestMapping *mapping =
    [[SDWebServiceMockResponseRequestMapping alloc]
     initWithPath:@"^/api/route$" queryParameters:nil];

    NSUInteger maximumResponsesA = 3;
    NSData *checkDataA = [self mapMockDataWithFilename:@"SDWebServiceMockTest_bundleA.json" mapping:mapping maximumResponses:maximumResponsesA];
    NSUInteger maximumResponsesB = 2;
    NSData *checkDataB = [self mapMockDataWithFilename:@"SDWebServiceMockTest_bundleB.json" mapping:mapping maximumResponses:maximumResponsesB];

    for (NSInteger idx=0; idx<maximumResponsesA; idx++) {
        [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                           replacements:nil
                                  block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                      XCTAssertNil(response);
                                      XCTAssertEqualObjects(checkDataA, responseData, @"mock should supply data from mock response A mapped above");
                                  }];
    }
    for (NSInteger idx=0; idx<maximumResponsesB; idx++) {
        [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                           replacements:nil
                                  block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                      XCTAssertNil(response);
                                      XCTAssertEqualObjects(checkDataB, responseData, @"mock should supply data from mock response A mapped above");
                                  }];
    }
    [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                       replacements:nil
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  XCTAssertNil(response);
                                  XCTAssertEqual(0, [responseData length], @"mock should NOT supply data from any mock response");
                              }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - compound match response tests

- (void)testCompoundMockDataResponse
{
    SDWebServiceMockResponseRequestMapping *mapping =
    [[SDWebServiceMockResponseRequestMapping alloc]
     initWithPath:@"^/api/route$"
     queryParameters:@{@"routeParam1":@"matchAny",@"routeParam2":@"^exactMatch$"}];
    NSData *checkDataA = [self mapMockDataWithFilename:@"SDWebServiceMockTest_bundleA.json" mapping:mapping maximumResponses:NSIntegerMax];

    [self checkWebServiceWithMethod:@"testGETTwoRouteParams"
                       replacements:@{@"routeParam1":@"AAA matchAny BBB",@"routeParam2":@"exactMatch"}
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  XCTAssertNil(response);
                                  XCTAssertEqualObjects(checkDataA, responseData, @"mock should supply data from mock response A mapped above");
                              }];

    [self checkWebServiceWithMethod:@"testGETTwoRouteParams"
                       replacements:@{@"routeParam1":@"AAA matchAny BBB",@"routeParam2":@"NOTexactMatch"}
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  XCTAssertNil(response);
                                  XCTAssertEqual(0, [responseData length], @"mock should NOT supply data from any mock response");
                              }];

    [self checkWebServiceWithMethod:@"testGETTwoRouteParams"
                       replacements:@{@"routeParam1":@"XYZ matchAny ZZZ",@"routeParam2":@"exactMatch"}
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  XCTAssertNil(response);
                                  XCTAssertEqualObjects(checkDataA, responseData, @"mock should supply data from mock response A mapped above");
                              }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - test removals

- (void)testRemoveSingleMapping
{
    SDWebServiceMockResponseRequestMapping *mappingA =
    [[SDWebServiceMockResponseRequestMapping alloc]
     initWithPath:@"^/api/route$"
     queryParameters:@{@"routeParam1":@"value1A",@"routeParam2":@"value2A"}];

    SDWebServiceMockResponseRequestMapping *mappingB =
    [[SDWebServiceMockResponseRequestMapping alloc]
     initWithPath:@"^/api/route$"
     queryParameters:@{@"routeParam1":@"value1B",@"routeParam2":@"value2B"}];

    NSData *checkDataA = [self mapMockDataWithFilename:@"SDWebServiceMockTest_bundleA.json" mapping:mappingA maximumResponses:NSIntegerMax];
    [self mapMockDataWithFilename:@"SDWebServiceMockTest_bundleA.json" mapping:mappingA maximumResponses:NSIntegerMax];
    NSData *checkDataB = [self mapMockDataWithFilename:@"SDWebServiceMockTest_bundleB.json" mapping:mappingB maximumResponses:NSIntegerMax];
    [self mapMockDataWithFilename:@"SDWebServiceMockTest_bundleB.json" mapping:mappingB maximumResponses:NSIntegerMax];

    for (NSInteger idx=0; idx<4; idx++) {
        [self checkWebServiceWithMethod:@"testGETTwoRouteParams"
                           replacements:@{@"routeParam1":@"value1A",@"routeParam2":@"value2A"}
                                  block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                      XCTAssertNil(response);
                                      XCTAssertEqualObjects(checkDataA, responseData, @"mock should supply data from mock response A mapped above");
                                  }];
        [self checkWebServiceWithMethod:@"testGETTwoRouteParams"
                           replacements:@{@"routeParam1":@"value1B",@"routeParam2":@"value2B"}
                                  block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                      XCTAssertNil(response);
                                      XCTAssertEqualObjects(checkDataB, responseData, @"mock should supply data from mock response B mapped above");
                                  }];
    }

    [self.mockResponseMapProvider removeRequestMapping:mappingA];

    for (NSInteger idx=0; idx<4; idx++) {
        [self checkWebServiceWithMethod:@"testGETTwoRouteParams"
                           replacements:@{@"routeParam1":@"value1A",@"routeParam2":@"value2A"}
                                  block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                      XCTAssertNil(response);
                                      XCTAssertEqual(0, [responseData length], @"mock should NOT supply data from any mock response");
                                  }];
        [self checkWebServiceWithMethod:@"testGETTwoRouteParams"
                           replacements:@{@"routeParam1":@"value1B",@"routeParam2":@"value2B"}
                                  block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                      XCTAssertNil(response);
                                      XCTAssertEqualObjects(checkDataB, responseData, @"mock should supply data from mock response B mapped above");
                                  }];
    }

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testRemoveAll
{
    SDWebServiceMockResponseRequestMapping *mappingA =
    [[SDWebServiceMockResponseRequestMapping alloc]
     initWithPath:@"^/api/route$"
     queryParameters:@{@"routeParam1":@"value1A",@"routeParam2":@"value2A"}];

    SDWebServiceMockResponseRequestMapping *mappingB =
    [[SDWebServiceMockResponseRequestMapping alloc]
     initWithPath:@"^/api/route$"
     queryParameters:@{@"routeParam1":@"value1B",@"routeParam2":@"value2B"}];

    NSData *checkDataA = [self mapMockDataWithFilename:@"SDWebServiceMockTest_bundleA.json" mapping:mappingA maximumResponses:NSIntegerMax];
    NSData *checkDataB = [self mapMockDataWithFilename:@"SDWebServiceMockTest_bundleB.json" mapping:mappingB maximumResponses:NSIntegerMax];

    [self checkWebServiceWithMethod:@"testGETTwoRouteParams"
                       replacements:@{@"routeParam1":@"value1A",@"routeParam2":@"value2A"}
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  XCTAssertNil(response);
                                  XCTAssertEqualObjects(checkDataA, responseData, @"mock should supply data from mock response A mapped above");
                              }];
    [self checkWebServiceWithMethod:@"testGETTwoRouteParams"
                       replacements:@{@"routeParam1":@"value1B",@"routeParam2":@"value2B"}
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  XCTAssertNil(response);
                                  XCTAssertEqualObjects(checkDataB, responseData, @"mock should supply data from mock response B mapped above");
                              }];

    [self.mockResponseMapProvider removeAllRequestMappings];

    [self checkWebServiceWithMethod:@"testGETTwoRouteParams"
                       replacements:@{@"routeParam1":@"value1A",@"routeParam2":@"value2A"}
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  XCTAssertNil(response);
                                  XCTAssertEqual(0, [responseData length], @"mock should NOT supply data from any mock response");
                              }];
    [self checkWebServiceWithMethod:@"testGETTwoRouteParams"
                       replacements:@{@"routeParam1":@"value1B",@"routeParam2":@"value2B"}
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  XCTAssertNil(response);
                                  XCTAssertEqual(0, [responseData length], @"mock should NOT supply data from any mock response");
                              }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - simple match mockHTTPURLResponse tests

- (void)testSingleSimpleMockHTTPURLResponse
{
    SDWebServiceMockResponseRequestMapping *mapping =
    [[SDWebServiceMockResponseRequestMapping alloc]
     initWithPath:@"^/api/route$" queryParameters:nil];
    [self mapMockHTTPURLResponseWithFilename:@"SDWebServiceMockTest_bundleC_v123_sc999.response" mapping:mapping maximumResponses:1];
/*
HTTP/123 999 OK
Header1: bundleCHeader1
Header2: bundleCHeader2

{"name":"SDWebServiceMockTest_bundleC","bundleCValue":"bundle C value"}
*/

    NSString *expectedResponseDataString = @"{\"name\":\"SDWebServiceMockTest_bundleC\",\"bundleCValue\":\"bundle C value\"}";
    NSData *expectedData = [expectedResponseDataString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *expectedHeaders = @{@"Header1":@"bundleCHeader1",@"Header2":@"bundleCHeader2"};
    NSInteger expectedStatusCode = 999;

    [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                       replacements:nil
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  XCTAssertTrue([response isKindOfClass:[NSHTTPURLResponse class]]);
                                  NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *) response;
                                  XCTAssertEqual(expectedStatusCode, httpURLResponse.statusCode);
                                  XCTAssertEqualObjects(expectedHeaders, httpURLResponse.allHeaderFields);
                                  XCTAssertEqualObjects(expectedData, responseData, @"mock should supply data from mock response");
                              }];

    [self checkWebServiceWithMethod:@"testGETNoRouteParams"
                       replacements:nil
                              block:^(NSURLResponse *response, NSInteger responseCode, NSData *responseData, NSError *error) {
                                  XCTAssertNil(response);
                                  XCTAssertEqual(0, [responseData length], @"mock should NOT supply data from any mock response");
                              }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
