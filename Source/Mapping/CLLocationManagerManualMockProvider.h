//
//  CLLocationManagerManualMockProvider.h
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CLLocationManagerMockProvider.h"

@interface CLLocationManagerManualMockProvider : NSObject<CLLocationManagerMockProvider>

@property (nonatomic,strong,readonly) id<CLLocationManagerDelegate> clLocationManagerDelegate;

- (instancetype) initWithCLLocationManagerDelegate:(id<CLLocationManagerDelegate>) clLocationManagerDelegate;

@end
