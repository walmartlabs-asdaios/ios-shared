//
//  SDDecimalNumberTransformer.m
//  ios-shared
//
//  Created by Andrew Finnell on 1/5/15.
//  Copyright (c) 2015 SetDirection. All rights reserved.
//

#import "SDDecimalNumberTransformer.h"

@implementation SDDecimalNumberTransformer

+ (Class)transformedValueClass
{
    return [NSDecimalNumber class];
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
        transformedValue = [NSDecimalNumber decimalNumberWithString:value];
    }
    return transformedValue;
}

@end
