//
//  SDISO8601DateTransformer.m
//  ios-shared
//
//  Created by Andrew Finnell on 1/2/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import "SDISO8601DateTransformer.h"
#import "NSDate+SDExtensions.h"

@implementation SDISO8601DateTransformer

+ (Class)transformedValueClass
{
    return [NSDate class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    id transformedValue = nil;
    if ( value != nil )
    {
        transformedValue = [NSDate dateFromISO8601String:value];
    }
    return transformedValue;
}

@end
