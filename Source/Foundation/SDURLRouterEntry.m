//
//  SDURLRouterEntry.m
//  ios-shared
//
//  Created by Andrew Finnell on 12/11/14.
//  Copyright (c) 2014 Set Direction. All rights reserved.
//

#import "SDURLRouterEntry.h"
#import "SDURLRouteHandler.h"

@interface SDURLRouterEntry ()

@property (nonatomic, strong) id<SDURLRouteHandler> handler;
@property (nonatomic, strong) NSMutableArray *parameterNames;
@property (nonatomic, strong) NSRegularExpression *matchRegularExpression;

@end

@implementation SDURLRouterEntry

- (instancetype) initWithRoute:(NSString *)routeTemplate handler:(id<SDURLRouteHandler>)handler
{
    self = [super init];
    if (self != nil)
    {
        _handler = handler;
        _parameterNames = [NSMutableArray array];
        [self initMatchRegularExpressionWithTemplate:routeTemplate];
    }
    return self;
}

- (void) initMatchRegularExpressionWithTemplate:(NSString *)route
{
    static NSString *SDURLSegmentMatchingPattern = @"([^\\/\\?\n\r]+)";
    static NSString *SDURLCatchRestMatchingPattern = @"([^\n\r]+)";
    static NSString *SDEllipsis = @"...";

    NSMutableString *matchingString = [NSMutableString string];
    [matchingString appendString:@"^"];
    
    NSCharacterSet *escapeCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"*?+[()^$|\\./"];
    __block BOOL parsingName = NO;
    __block NSMutableString *parameterName = nil;
    
    [route enumerateSubstringsInRange:NSMakeRange(0, [route length]) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
    {
        if ( [substring isEqualToString:@"{"] )
        {
            parsingName = YES;
            parameterName = [NSMutableString string];
        }
        else if ( [substring isEqualToString:@"}"] )
        {
            if ( [parameterName hasSuffix:SDEllipsis] )
            {
                [parameterName deleteCharactersInRange:NSMakeRange([parameterName length] - [SDEllipsis length], [SDEllipsis length])];
                [matchingString appendString:SDURLCatchRestMatchingPattern];
            }
            else
            {
                [matchingString appendString:SDURLSegmentMatchingPattern];
            }
            [_parameterNames addObject:parameterName];
            parameterName = nil;
            parsingName = NO;
        }
        else if ( parsingName )
        {
            [parameterName appendString:substring];
        }
        else if ( [substring rangeOfCharacterFromSet:escapeCharacterSet].location != NSNotFound )
        {
            [matchingString appendString:@"\\"];
            [matchingString appendString:substring];
        }
        else
        {
            [matchingString appendString:substring];
        }
    }];
    
    [matchingString appendString:@"$"];
    _matchRegularExpression = [NSRegularExpression regularExpressionWithPattern:matchingString options:0 error:nil];
}

- (NSDictionary *) matchesURL:(NSURL *)url
{
    NSMutableDictionary *parameters = nil;
    
    NSString *urlString = [url absoluteString];
    NSString *query = [url query];
    if ( [query length] > 0 )
    {
        urlString = [urlString substringToIndex:[urlString length] - [query length] - 1];
    }
    
    NSArray *matches = [self.matchRegularExpression matchesInString:urlString options:0 range:NSMakeRange(0, [urlString length])];
    
    if ( [matches count] == 1 )
    {
        NSTextCheckingResult *result = matches[0];
        parameters = [NSMutableDictionary dictionary];
        [self.parameterNames enumerateObjectsUsingBlock:^(NSString *parameterName, NSUInteger idx, BOOL *stop)
        {
            NSRange valueRange = [result rangeAtIndex:idx + 1];
            parameters[parameterName] = [urlString substringWithRange:valueRange];
        }];
        [parameters addEntriesFromDictionary:[self parametersFromQuery:query]];
    }
    
    return parameters;
}

- (NSDictionary *) parametersFromQuery:(NSString *)query
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];

    NSArray *keyValuePairs = [[query stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] componentsSeparatedByString:@"&"];
    for (NSString *keyValuePair in keyValuePairs)
    {
        NSArray *pair = [keyValuePair componentsSeparatedByString:@"="];
        if ( [pair count] != 2 )
            continue;
        
        parameters[pair[0]] = pair[1];
    }
    
    return parameters;
}

- (void) handleURL:(NSURL *)url withParameters:(NSDictionary *)parameters
{
    [self.handler handleURL:url withParameters:parameters];
}

@end
