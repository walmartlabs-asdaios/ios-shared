//
//  SDSearchSuggestionsDataSource.h
//  SetDirection
//
//  Created by Andrew Finnell on 4/16/14.
//  Copyright (c) 2014 SetDirection. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SDSearchSuggestionsCompletion)(NSArray<NSString *> * searchSuggestions);

@protocol SDSearchSuggestionsDataSource <NSObject>

- (void) searchSuggestionsForString:(NSString *)searchString completion:(SDSearchSuggestionsCompletion)block;
- (NSArray<NSString *> *) recentSearchStrings;
- (void) clearRecentSearches;
- (void) addRecentSearchString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END