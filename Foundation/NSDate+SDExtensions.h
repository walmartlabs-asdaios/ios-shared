//
//  NSDate+SDExtensions.h
//  walmart
//
//  Created by Sam Grover on 3/8/11.
//  Copyright 2011 Set Direction. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDate (SDExtensions)

+ (NSDate *)dateFromISO8601String:(NSString *)argDateString;

@end