//
//  SDPromise.m
//  asda
//
//  Created by Andrew Finnell on 12/16/14.
//  Copyright (c) 2014 Asda. All rights reserved.
//

#import "SDPromise.h"

typedef NS_ENUM(NSUInteger, SDPromiseState)
{
    SDPromiseStatePending,
    SDPromiseStateResolved,
    SDPromiseStateRejected
};

@interface SDPromiseResult : NSObject

- (instancetype) initWithThenBlock:(SDPromiseThenBlock)thenBlock
                       rejectBlock:(SDPromiseRejectBlock)rejectBlock
                     resultPromise:(SDPromise *)promise;

- (void) resolve:(id)result;
- (void) reject:(NSError *)error;

@end

#pragma mark -

@interface SDPromise ()

@property (nonatomic, strong) NSMutableArray *promiseResults;
@property (nonatomic, assign) SDPromiseState state;
@property (nonatomic, strong) id result;
@property (nonatomic, strong) NSError *error;

@end

@implementation SDPromise

+ (instancetype) promiseWithAnd:(NSArray *)promises
{
    SDPromise *andPromise = [[SDPromise alloc] init];

    NSMutableArray *allResults = [NSMutableArray array];
    NSUInteger totalCount = [promises count];
    
    for (SDPromise *promise in promises)
    {
        [promise then:^id(id dataObject) {
            BOOL isComplete = NO;
            @synchronized(allResults)
            {
                [allResults addObject:dataObject];
                isComplete = totalCount == [allResults count];
            }
            if ( isComplete )
                [andPromise resolve:allResults];
            return nil;
        } reject:^id(NSError *error) {
            [andPromise reject:error];
            return nil;
        }];
    }
    
    return andPromise;
}

- (instancetype) init
{
    self = [super init];
    if ( self != nil )
    {
        _promiseResults = [NSMutableArray array];
    }
    return self;
}

- (BOOL) isFulfilled
{
    BOOL isFulfilled = NO;
    @synchronized(self)
    {
        isFulfilled = self.state == SDPromiseStateResolved;
    }
    return isFulfilled;
}

- (BOOL) isRejected
{
    BOOL isRejected = NO;
    @synchronized(self)
    {
        isRejected = self.state == SDPromiseStateRejected;
    }
    return isRejected;
}

- (BOOL) isCompleted
{
    BOOL isCompleted = NO;
    @synchronized(self)
    {
        isCompleted = self.state != SDPromiseStatePending;
    }
    return isCompleted;
}

// Consumer interface
- (SDPromise *) then:(SDPromiseThenBlock)thenBlock
{
    return [self then:thenBlock reject:nil];
}

// Consumer interface
- (SDPromise *) then:(SDPromiseThenBlock)thenBlock reject:(SDPromiseRejectBlock) rejectBlock
{
    SDPromise *promise = [[SDPromise alloc] init];
    SDPromiseResult *promiseResult = [[SDPromiseResult alloc] initWithThenBlock:thenBlock rejectBlock:rejectBlock resultPromise:promise];

    @synchronized(self)
    {
        if ( self.state == SDPromiseStateResolved )
        {
            // Already done, but don't call back right now
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [promiseResult resolve:self.result];
            });
        }
        else if ( self.state == SDPromiseStateRejected )
        {
            // Already done, but don't call back right now
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [promiseResult reject:self.error];
            });
        }
        else
        {
            // Nothing's happened yet, so wait
            [self.promiseResults addObject:promiseResult];
        }
    }
    
    return promise;
}

// Producer interface
- (void) resolve:(id)dataObject
{
    NSArray *promiseResults = [self markResolvedWithResult:dataObject];
    if ( promiseResults != nil )
    {
        for (SDPromiseResult *promiseResult in promiseResults)
            [promiseResult resolve:dataObject];
    }
}

- (NSArray *) markResolvedWithResult:(id)dataObject
{
    NSArray *promiseResults = nil;
    
    @synchronized(self)
    {
        if ( self.state == SDPromiseStatePending )
        {
            self.state = SDPromiseStateResolved;
            self.result = dataObject;
            promiseResults = [self.promiseResults copy];
            [self.promiseResults removeAllObjects];
        }
    }

    return promiseResults;
}

- (void) reject:(NSError *)error
{
    NSArray *promiseResults = [self markRejectedWithError:error];
    if ( promiseResults != nil )
    {
        for (SDPromiseResult *promiseResult in promiseResults)
            [promiseResult reject:self.error];
    }
}

- (NSArray *) markRejectedWithError:(NSError *)error
{
    NSArray *promiseResults = nil;
    
    @synchronized(self)
    {
        if ( self.state == SDPromiseStatePending )
        {
            self.state = SDPromiseStateRejected;
            self.error = error;
            promiseResults = [self.promiseResults copy];
            [self.promiseResults removeAllObjects];
        }
    }
    
    return promiseResults;
}

@end

#pragma mark -

@implementation SDPromiseResult {
    SDPromiseThenBlock _thenBlock;
    SDPromiseRejectBlock _rejectBlock;
    SDPromise *_resultPromise;
}

- (instancetype) initWithThenBlock:(SDPromiseThenBlock)thenBlock
                       rejectBlock:(SDPromiseRejectBlock)rejectBlock
                     resultPromise:(SDPromise *)promise;
{
    self = [super init];
    if ( self != nil )
    {
        _thenBlock = [thenBlock copy];
        _rejectBlock = [rejectBlock copy];
        _resultPromise = promise;
    }
    return self;
}

- (void) resolve:(id)result
{
    id resultOfBlock = _thenBlock(result);
    if ( resultOfBlock != nil && [resultOfBlock isKindOfClass:[NSError class]] )
    {
        NSError *error = resultOfBlock;
        [_resultPromise reject:error];
    }
    else if ( resultOfBlock != nil && [resultOfBlock isKindOfClass:[SDPromise class]] )
    {
        // Chain the promise we returned to the client, to the one the then block
        //  just returned.
        SDPromise *promiseOfBlock = resultOfBlock;
        [promiseOfBlock then:^id(id dataObject) {
            [_resultPromise resolve:dataObject];
            return nil;
        } reject:^id(NSError *error) {
            [_resultPromise reject:error];
            return nil;
        }];
    }
    else
    {
        [_resultPromise resolve:resultOfBlock];
    }
}

- (void) reject:(NSError *)error;
{
    id resultOfBlock = nil;
    if (_rejectBlock)
    {
        resultOfBlock = _rejectBlock(error);
    }
    else
    {
        resultOfBlock = error;
    }
    if ( resultOfBlock != nil && [resultOfBlock isKindOfClass:[NSError class]] )
    {
        [_resultPromise reject:resultOfBlock];
    }
    else if ( resultOfBlock != nil && [resultOfBlock isKindOfClass:[SDPromise class]] )
    {
        // Chain the promise we returned to the client, to the one the reject block
        //  just returned.
        SDPromise *promiseOfBlock = resultOfBlock;
        [promiseOfBlock then:^id(id dataObject) {
            [_resultPromise resolve:dataObject];
            return nil;
        } reject:^id(NSError *rejectError) {
            [_resultPromise reject:rejectError];
            return nil;
        }];
    }
    else
    {
        [_resultPromise resolve:resultOfBlock];
    }
}

@end
