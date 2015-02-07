//
//  SDCLLocationManagerProxy.h
//  ios-shared
//
//  Created by Douglas Sjoquist on 2/6/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "SDBaseMockCLLocationManager.h"

@interface SDCLLocationManagerProxy : NSProxy

- (instancetype) initWithBaseMockCLLocationManager:(SDBaseMockCLLocationManager *) baseMockCLLocationManager;

@end
