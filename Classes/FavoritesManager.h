//
//  FavoritesManager.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClientTransaction.h"

@class CameraInfoWrapper;


/**
 *  Protocol used to notify observers when the user's favorites have been updated.
 */
@protocol FavoritesObserver <NSObject>

@optional

- (void)favoritesUpdated:(NSArray *)favorites orError:(NSError *)error;

@end


/**
 *  Singleton that manages the user's favorite cameras.
 */
@interface FavoritesManager : NSObject <ClientTransactionDelegate>

/**
 *  Array of CameraInfoWrappers representing the user's bookmarked favorites.
 *  This will be nil if the favorites have not yet been retrieved from the server.
 */
+ (NSArray *)favorites;

/**
 *  Retrieves the user's favorites from the server and optionally adds an observer.
 *  Observers will be sent a favoritesUpdated: message when the user's favorites change.
 *  
 *  @param observer An observer to notify when favorites change.  If the observer is already
 *                  in the list of observers, it will not be added again (i.e., a given
 *                  observer will only ever be notified once for each update).
 */
+ (void)updateAndAddObserver:(id <FavoritesObserver>)observer;

/**
 *  Removes the observer.  If the observer is not in the list of observers, nothing happens.
 */
+ (void)removeObserver:(id <FavoritesObserver>)observer;

/**
 *  Adds or updates the given favorite.
 *
 *  @param favorite Camera to bookmark as a favorite.
 */
+ (void)add:(CameraInfoWrapper *)favorite;

/**
 *  Removes the given favorite from the user's bookmarks.
 *
 *  @param favorite Camera to remove from favorites.
 */
+ (void)remove:(CameraInfoWrapper *)favorite;

/**
 *  Indicates whether the given camera is one of the user's bookmarked favorites.
 *  
 *  @param camera Camera to look for in list of favorites.
 *  @return YES if camera is in the list of favorites, otherwise NO
 */
+ (BOOL)isAFavorite:(CameraInfoWrapper *)camera;

/**
 *  Releases cached favorites so that they will be reloaded from the server
 *  the next time they are needed.
 */
+ (void)invalidate;

@end
