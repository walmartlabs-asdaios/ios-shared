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

@interface SDPromiseThen : NSObject

- (instancetype) initWithBlock:(SDPromiseThenBlock)block resultPromise:(SDPromise *)promise;

- (void) resolve:(id)result;

@end

@interface SDPromiseReject : NSObject

- (instancetype) initWithBlock:(SDPromiseRejectBlock)block resultPromise:(SDPromise *)promise;

- (void) reject:(NSError *)error;

@end

#pragma mark -

@interface SDPromise ()

@property (nonatomic, strong) NSMutableArray *thenBlocks;
@property (nonatomic, strong) NSMutableArray *rejectedBlocks;
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
        _thenBlocks = [NSMutableArray array];
        _rejectedBlocks = [NSMutableArray array];
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
    SDPromise *resultPromise = [[SDPromise alloc] init];
    SDPromiseThen *then = [[SDPromiseThen alloc] initWithBlock:thenBlock resultPromise:resultPromise];
    SDPromiseReject *rejected = [[SDPromiseReject alloc] initWithBlock:rejectBlock resultPromise:resultPromise];

    @synchronized(self)
    {
        if ( self.state == SDPromiseStateResolved )
        {
            // Already done, but don't call back right now
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [then resolve:self.result];
            });
        }
        else if ( self.state == SDPromiseStateRejected )
        {
            // Already done, but don't call back right now
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [rejected reject:self.error];
            });
        }
        else
        {
            // Nothing's happened yet, so wait
            [self.thenBlocks addObject:then];
            [self.rejectedBlocks addObject:rejected];
        }
    }
    
    return resultPromise;
}

// Producer interface
- (void) resolve:(id)dataObject
{
    NSArray *thenBlocks = [self markResolvedWithResult:dataObject];
    if ( thenBlocks != nil )
    {
        for (SDPromiseThen *then in thenBlocks)
            [then resolve:dataObject];
    }
}

- (NSArray *) markResolvedWithResult:(id)dataObject
{
    NSArray *thens = nil;
    
    @synchronized(self)
    {
        if ( self.state == SDPromiseStatePending )
        {
            self.state = SDPromiseStateResolved;
            self.result = dataObject;
            thens = [self.thenBlocks copy];
            [self.thenBlocks removeAllObjects];
            [self.rejectedBlocks removeAllObjects];
        }
    }

    return thens;
}

- (void) reject:(NSError *)error
{
    NSArray *rejectedBlocks = [self markRejectedWithError:error];
    if ( rejectedBlocks != nil )
    {
        for (SDPromiseReject *reject in rejectedBlocks)
            [reject reject:self.error];
    }
}

- (NSArray *) markRejectedWithError:(NSError *)error
{
    NSArray *rejectedBlocks = nil;
    
    @synchronized(self)
    {
        if ( self.state == SDPromiseStatePending )
        {
            self.state = SDPromiseStateRejected;
            self.error = error;
            rejectedBlocks = [self.rejectedBlocks copy];
            [self.thenBlocks removeAllObjects];
            [self.rejectedBlocks removeAllObjects];
        }
    }
    
    return rejectedBlocks;
}

@end

#pragma mark -

@implementation SDPromiseThen {
    SDPromiseThenBlock _block;
    SDPromise *_resultPromise;
}

- (instancetype) initWithBlock:(SDPromiseThenBlock)block resultPromise:(SDPromise *)promise
{
    self = [super init];
    if ( self != nil )
    {
        _block = [block copy];
        _resultPromise = promise;
    }
    return self;
}

- (void) resolve:(id)result
{
    id resultOfBlock = _block(result);
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

@end

#pragma mark -

@implementation SDPromiseReject {
    SDPromiseRejectBlock _block;
    SDPromise *_resultPromise;
}

- (instancetype) initWithBlock:(SDPromiseRejectBlock)block resultPromise:(SDPromise *)promise
{
    self = [super init];
    if ( self != nil )
    {
        _block = [block copy];
        _resultPromise = promise;
    }
    return self;
}

- (void) reject:(NSError *)error;
{
    id resultOfBlock = nil;
    if (_block)
    {
        resultOfBlock = _block(error);
    }
    else
    {
        resultOfBlock = error;
    }
    if ( resultOfBlock != nil && [resultOfBlock isKindOfClass:[NSError class]] )
    {
        NSError *error = resultOfBlock;
        [_resultPromise reject:error];
    }
    else if ( resultOfBlock != nil && [resultOfBlock isKindOfClass:[SDPromise class]] )
    {
        // Chain the promise we returned to the client, to the one the reject block
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

@end
