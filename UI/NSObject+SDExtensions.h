//
//  NSObject+SDExtensions.h
//
//  Created by brandon on 1/14/11.
//  Copyright 2011 Set Direction. All rights reserved.
//

#import <Foundation/Foundation.h>

// makes loading nibs much easier.

@interface NSObject (SDExtensions)

+ (NSString *)className;
- (NSString *)className;

+ (NSString *)nibName;
+ (id)loadFromNib;
+ (id)loadFromNibWithOwner:(id)owner;

@end