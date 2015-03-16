//
//  SDPromise.h
//  asda
//
//  Created by Andrew Finnell on 12/16/14.
//  Copyright (c) 2014 Asda. All rights reserved.
//

#import <Foundation/Foundation.h>

// The block can return NSError to have failBlocks propogated. Any other returned
//  value, including nil, will fire any dependant promise thenBlocks.
typedef id (^SDPromiseThenBlock)(id dataObject);
typedef id (^SDPromiseRejectBlock)(NSError *error);

@interface SDPromise : NSObject

// Logically AND all the passed in SDPromises. When all the passed in promises
//  are resolved, then the created promise is resolved. If one of the passed in
//  promises is rejected, then the created promise is rejected once, with that error.
+ (instancetype) promiseWithAnd:(NSArray *)promises;

// adjust naming to more closely mimic javascript Promises/A+ spec naming patterns
//   that spec is not entirely consistent: 'then', 'resolved' & 'fulfilled' are all the same idea
//   but 'reject' & 'rejected' are used consistently
// a promise is only fulfilled is it has been resolved, so isCompleted was introduced
//   to cover both non-pending states
@property (nonatomic, readonly) BOOL isFulfilled;
@property (nonatomic, readonly) BOOL isRejected;
@property (nonatomic, readonly) BOOL isCompleted;

// Consumer interface. The returned SDPromise allows you to easily chain promise results.
- (SDPromise *) then:(SDPromiseThenBlock)thenBlock reject:(SDPromiseRejectBlock) rejectBlock;
- (SDPromise *) then:(SDPromiseThenBlock)thenBlock;

// Producer interface
- (void) resolve:(id)dataObject;
- (void) reject:(NSError *)error;

@end

