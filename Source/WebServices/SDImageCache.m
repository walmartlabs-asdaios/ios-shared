//
//  SDImageCache.m
//  ios-shared
//
//  Created by Brandon Sneed on 7/10/13.
//  Copyright (c) 2013 SetDirection. All rights reserved.
//

#import "SDImageCache.h"
#import "SDURLConnection.h"
#import "NSURLCache+SDExtensions.h"
#import "NSCachedURLResponse+LeakFix.h"
#import "NSURLRequest+SDExtensions.h"
#import "SDLog.h"

#import <objc/runtime.h>

#if (defined(DEBUG) && defined(DEBUG_SD)) || defined(TESTFLIGHT)
#define ImageCacheLog(frmt,...) { if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SDImageCache_Log"]) SDLog(@"SDImageCache: %@",[NSString stringWithFormat:frmt, ##__VA_ARGS__]); }
#else
#define ImageCacheLog(x...)
#endif


@implementation SDImageCache

+ (SDImageCache *)sharedInstance
{
    static dispatch_once_t onceToken;
    static SDImageCache *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[SDImageCache alloc] init];
    });

    return instance;
}

- (id)init
{
    self = [super init];

    _activeConnections = [NSMutableDictionary dictionary];
    _memoryCache = [NSMutableDictionary dictionary];
    _decodeQueue = [[NSOperationQueue alloc] init];
    _memoryCacheSize = 1024 * 1024 * 16; // default to 4mb
    _imageCounter = 0;

    // Subscribe to app events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(flushMemoryCache)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];

    UIDevice *device = [UIDevice currentDevice];
    if ([device respondsToSelector:@selector(isMultitaskingSupported)] && device.multitaskingSupported)
    {
        // When in background, clean memory in order to have less chance to be killed
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(flushMemoryCache)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }

    return self;
}

- (NSUInteger)actualMemoryCacheSize
{
    __block NSUInteger result = 0;
    [_memoryCache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        UIImage *thisImage = (UIImage *)obj;
        NSUInteger thisImageSize = (thisImage.size.width * thisImage.size.height) * 4; // rough estimate
        result += thisImageSize;
    }];

    return result;
}

- (void)flushMemoryCache
{
    [_memoryCache removeAllObjects];
    _imageCounter = 0;
}

- (void)flushDiskCache
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)flushCache
{
    [self flushMemoryCache];
    [self flushDiskCache];
}

- (void)cleanCacheAsNeeded
{
    NSUInteger actualSize = [self actualMemoryCacheSize];
    if (actualSize > _memoryCacheSize)
    {
        NSMutableArray *keys = [[_memoryCache keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSNumber *obj1Index = objc_getAssociatedObject(obj1, @"decodedIndex");
            NSNumber *obj2Index = objc_getAssociatedObject(obj2, @"decodedIndex");

            if ([obj1Index integerValue] > [obj2Index integerValue])
                return NSOrderedDescending;
            if ([obj1Index integerValue] < [obj2Index integerValue])
                return NSOrderedAscending;
            return NSOrderedSame;
        }] mutableCopy];

        while ([self actualMemoryCacheSize] > _memoryCacheSize - (_memoryCacheSize / 4))
        {
            NSString *key = [keys firstObject];
            [_memoryCache removeObjectForKey:key];
            [keys removeObject:key];
            ImageCacheLog(@"dumped from cache: %@", key);

            // safety break.  i don't like while loops without a break.
            if ([_memoryCache count] == 0 || [keys count] == 0)
                break;
        }
    }
}

- (NSString *) activeConnectionKeyForURL:(NSURL *) url source:(id) source;
{
    return source ? [NSString stringWithFormat:@"%@<%p>", [url absoluteString], source] : [url absoluteString];
}

- (BOOL)isImageURLInProgress:(NSURL *)url source:(id) source;
{
    SDURLConnection *connection = [_activeConnections objectForKey:[self activeConnectionKeyForURL:url source:source]];
    if (connection)
        return YES;
    return NO;
}

+ (UIImage *)decodedImageWithImage:(UIImage *)image
{
    CGImageRef imageRef = image.CGImage;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 CGImageGetWidth(imageRef),
                                                 CGImageGetHeight(imageRef),
                                                 8,
                                                 // Just always return width * 4 will be enough
                                                 CGImageGetWidth(imageRef) * 4,
                                                 // System only supports RGB, set explicitly
                                                 colorSpace,
                                                 // Makes system don't need to do extra conversion when displayed.
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;

    CGRect rect = (CGRect){CGPointZero, {CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)}};
    CGContextDrawImage(context, rect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);

    UIImage *decompressedImage = [[UIImage alloc] initWithCGImage:decompressedImageRef scale:image.scale orientation:UIImageOrientationUp];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

- (void)fetchImageAtURL:(NSURL *)url source:(id) source completionBlock:(UIImageViewURLCompletionBlock)completionBlock
{
    UIImage *cachedImage = [_memoryCache objectForKey:[url absoluteString]];
    if (cachedImage)
    {
        ImageCacheLog(@"image found in memory cache: %@", url);
        if (completionBlock)
            completionBlock(cachedImage, nil);
        return;
    }

    BOOL foundInCache = [self fetchImageFromCacheAtURL:url source:source completionBlock:completionBlock];
    if (!foundInCache)
    {
        [self fetchImageFromNetworkAtURL:url source:(id) source completionBlock:completionBlock];
    }
}

- (BOOL)fetchImageFromCacheAtURL:(NSURL *)url source:(id) source completionBlock:(UIImageViewURLCompletionBlock)completionBlock
{
    BOOL success = NO;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLCache *urlCache = [NSURLCache sharedURLCache];
    NSCachedURLResponse *cachedResponse = [urlCache validCachedResponseForRequest:request forTime:60 removeIfInvalid:YES];
    if (cachedResponse)
    {
        UIImage *diskCachedImage = [UIImage imageWithData:cachedResponse.responseData];
        if (diskCachedImage)
        {
            [self didFetchImage:diskCachedImage atURL:url source:source error:nil withCompletionBlock:completionBlock];
            success = YES;
        }
    }

    return success;
}

- (void)fetchImageFromNetworkAtURL:(NSURL *)url source:(id) source completionBlock:(UIImageViewURLCompletionBlock)completionBlock;
{
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    SDURLConnection *urlConnection = [SDURLConnection sendAsynchronousRequest:request withPriority:kSDNetworkQueuePriority_background responseHandler:^(SDURLConnection *connection, NSURLResponse *response, NSData *responseData, NSError *error) {
        UIImage *image = nil;
        if (responseData && responseData.length > 0)
            image = [UIImage imageWithData:responseData];
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode >= 400)
                error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
        }
        
        [_decodeQueue addOperationWithBlock:^{
            UIImage *decodedImage = nil;
            if (image)
                decodedImage = [SDImageCache decodedImageWithImage:image];
            [self didFetchImage:decodedImage atURL:url source:source error:error withCompletionBlock:completionBlock];
        }];
    }];
    
    if (urlConnection)
        [_activeConnections setObject:urlConnection forKey:[self activeConnectionKeyForURL:url source:source]];
}

- (void)didFetchImage:(UIImage *)decodedImage atURL:(NSURL *)url source:(id) source error:(NSError *)error withCompletionBlock:(UIImageViewURLCompletionBlock)completionBlock
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self addImageToMemoryCache:decodedImage withURL:url];
        if (completionBlock)
            completionBlock(decodedImage, error);
        if (decodedImage.size.width == 0 || decodedImage.size.height == 0)
            [self removeImageURLFromCache:url source:source];
    }];
}

- (void)cancelFetchForURL:(NSURL *)url source:(id) source;
{
    if (url) {
        NSString *activeConnectionKey = [self activeConnectionKeyForURL:url source:source];
        SDURLConnection *connection = [_activeConnections objectForKey:activeConnectionKey];
        [connection cancel];
        [_activeConnections removeObjectForKey:activeConnectionKey];
    }
}

- (void)removeImageURLFromCache:(NSURL *)url source:(id) source;
{
    [self cancelFetchForURL:url source:source];

    NSURLCache *cache = [NSURLCache sharedURLCache];

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    if ([request isValid])
        [cache removeCachedResponseForRequest:request];
}

- (void)addImageToMemoryCache:(UIImage *)image withURL:(NSURL *)url
{
    if (image)
    {
        [_memoryCache setObject:image forKey:[url absoluteString]];
        _imageCounter++;
        objc_setAssociatedObject(image, @"decodedIndex", [NSNumber numberWithUnsignedInteger:_imageCounter], OBJC_ASSOCIATION_RETAIN);
    }

    [self cleanCacheAsNeeded];
}

@end
