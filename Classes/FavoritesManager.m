//
//  FavoritesManager.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "FavoritesManager.h"
#import "ClientConfiguration.h"
#import "SystemUris.h"
#import "FavoriteEntry.h"
#import "CameraInfo.h"
#import "CameraInfoWrapper.h"
#import "ConfigurationManager.h"
#import "AddFavoriteOperation.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation FavoritesManager
{
	NSMutableArray      * favorites;
	NSMutableArray      * observers;
	NSMutableDictionary * favoritesBeingAdded;
	NSOperationQueue    * operationQueue;
	ClientTransaction   * getFavoritesRequest;
}


#pragma mark - Initialization and cleanup

// Singleton instance
static FavoritesManager * instance;

+ (FavoritesManager *)instance
{
	if (instance == nil) 
	{
		instance = [[FavoritesManager alloc] init];
	}
	return instance;
}


- (id)init
{
	NSAssert(instance==nil,@"FavoritesManager singleton should only be instantiated once");
	self = [super init];
	if (self != nil)
	{
		observers = [[NSMutableArray alloc] initWithCapacity:5];
		favoritesBeingAdded = [[NSMutableDictionary alloc] initWithCapacity:5];
		operationQueue = [[NSOperationQueue alloc] init];
	}
	return self;
}


- (void)dealloc
{
	NSAssert(NO,@"FavoritesManager singleton should never be deallocated");
}


#pragma mark - Public methods

+ (NSArray *)favorites
{
	return [self instance]->favorites;
}


+ (void)updateAndAddObserver:(id<FavoritesObserver>)observer
{
	[[self instance] updateAndAddObserver:observer];
}


+ (void)removeObserver:(id<FavoritesObserver>)observer
{
	[[self instance] removeObserver:observer];
}


+ (void)add:(CameraInfoWrapper *)favorite
{
	[[self instance] add:favorite];
}


+ (void)remove:(CameraInfoWrapper *)favorite
{
	[[self instance] remove:favorite];
}


+ (BOOL)isAFavorite:(CameraInfoWrapper *)camera
{
	return [[self instance] isAFavorite:camera];
}


+ (void)invalidate
{
	return [[self instance] invalidate];
}


#pragma mark - Private methods

- (void)updateAndAddObserver:(id <FavoritesObserver>)observer
{
	NSAssert(observer,@"observer can not be nil");
	
	@synchronized(self)
	{
		DDLogVerbose(@"FavoritesManager updateAndAddObserver");
		
		if ([observers indexOfObject:observer] == NSNotFound)
		{
			[observers addObject:observer];
		}
		
		if (getFavoritesRequest == nil)
		{
			NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
			getFavoritesRequest = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
			getFavoritesRequest.delegate = self;
			[getFavoritesRequest getFavorites];
		}
	}
}


- (void)removeObserver:(id<FavoritesObserver>)observer
{
	NSAssert(observer,@"observer can not be nil");
	
	@synchronized(self)
	{
		DDLogVerbose(@"FavoritesManager removeObserver");
		
		NSUInteger indexOfObjectToRemove = [observers indexOfObject:observer];
		if (indexOfObjectToRemove != NSNotFound)
		{
			[observers removeObjectAtIndex:indexOfObjectToRemove];
			
			if ([observers count] == 0)
			{
				// no more observers, so cancel any pending getFavorites request and clear our cached favorites
				DDLogInfo(@"FavoritesManager cleared cache");
                [getFavoritesRequest cancel];
                getFavoritesRequest = nil;
				favorites = nil;
			}
		}
	}
}


- (void)add:(CameraInfoWrapper *)favorite
{
	NSAssert(favorite,@"Favorite to add must be provided");
	NSAssert(favorites,@"Add favorite called when favorites have not been fetched");
	
	@synchronized(self)
	{
		DDLogInfo(@"FavoritesManager add");
		
		// make sure this camera isn't already a favorite
		CameraInfoWrapper * existingFavorite = [self findFavoriteByName:favorite.name];
		NSOperation * favoriteBeingAdded = [favoritesBeingAdded objectForKey:favorite.name];
		
		if (existingFavorite != nil || favoriteBeingAdded != nil)
		{
			DDLogWarn(@"FavoritesManager add called for an existing favorite:%@",favorite.name);
			return;
		}
		
		// create async operation to add favorite
		AddFavoriteOperation * addFavoriteOperation = [[AddFavoriteOperation alloc] init];
		addFavoriteOperation.cameraToFavorite = favorite;
		
		AddFavoriteOperation * addFavoriteOperation_ = addFavoriteOperation;
		[addFavoriteOperation setCompletionBlock:^{ 
			[self addFavoriteComplete:addFavoriteOperation_];
		}];
		
		// add operation to map of favorites being added
		[favoritesBeingAdded setObject:addFavoriteOperation forKey:favorite.name];
		
		// get 'er done
		[operationQueue addOperation:addFavoriteOperation];
	}
}


- (void)remove:(CameraInfoWrapper *)favorite
{
	NSAssert(favorite,@"Favorite to remove must be provided");
	NSAssert(favorites,@"Remove favorite called when favorites have not been fetched");
	
	@synchronized(self)
	{
		DDLogInfo(@"FavoritesManager remove");
		
		NSOperation * favoriteBeingAdded = [favoritesBeingAdded objectForKey:favorite.name];
		
		if (favoriteBeingAdded != nil)
		{
			// user changed their mind ... don't add favorite after all
			DDLogInfo(@"FavoritesManager add operation cancelled for %@",favorite.name);
			[favoritesBeingAdded removeObjectForKey:favorite.name];
			[favoriteBeingAdded cancel];
			return;
		}
		
		// if the camera is not a FavoriteEntry, get the FavoriteEntry with its caption
		if (! favorite.isFavoriteEntry)
		{
			favorite = [self findFavoriteByName:favorite.name];
			NSAssert(favorite.isFavoriteEntry,@"Camera being removed is not a favorite: %@", favorite.name);
		}
		
		FavoriteEntry * favoriteToDelete = favorite.sourceObject;
		
		if (favoriteToDelete != nil)
		{
			NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
			ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
			clientTransaction.delegate = self;
			[clientTransaction deleteFavorite:favoriteToDelete.favoriteId];
			[favorites removeObject:favorite];
		}
	}
	
	// @todo should we wait to notify observers after getting web method result?
	//       for now, notify observers after this call has returned to simulate that behavior
	dispatch_async(dispatch_get_main_queue(), ^{ [self notifyObserversOfFavorites:favorites orError:nil]; });
}


- (BOOL)isAFavorite:(CameraInfoWrapper *)camera
{
	NSAssert(camera,@"Favorite to test must be provided");
	NSAssert(favorites,@"isAFavorite called when favorites have not been fetched");
	
	@synchronized(self)
	{
		return [self findFavoriteByName:camera.name] != nil;
	}
}


- (void)invalidate
{
	@synchronized(self)
	{
		// cancel any pending getFavorites request
		if (getFavoritesRequest != nil)
		{
			[getFavoritesRequest cancel];
			getFavoritesRequest = nil;
		}
        
        [observers removeAllObjects];
		
		favorites = nil;
	}
}


#pragma mark - ClientTransactionDelegate methods

- (void)onGetFavoritesResult:(NSArray *)result error:(NSError *)error
{
	@synchronized(self)
	{
		DDLogInfo(@"FavoritesManager onGetFavoritesResult");
		
		// if invalidate has been called, don't update favorites
		if (getFavoritesRequest == nil)
			return;
		
		getFavoritesRequest = nil;
		
		if ((result == nil) && (error == nil))
		{
			error = [RvError rvErrorWithLocalizedDescription:@"Did not receive the list of favorites."];
		}
		
		if (error == nil)
		{
			favorites = [[NSMutableArray alloc] initWithCapacity:[result count]];
			
			for (FavoriteEntry * favorite in result)
			{
				CameraInfoWrapper * camera = [[CameraInfoWrapper alloc] initWithFavorite:favorite];
				[favorites addObject:camera];
			}
		}
	}
	
	// notify listeners that favorites have been updated
	[self notifyObserversOfFavorites:favorites orError:error];
}


- (void)addFavoriteComplete:(AddFavoriteOperation *)addFavoriteOperation
{
	DDLogVerbose(@"FavoritesManager addFavoriteComplete");
	
	if ([addFavoriteOperation isCancelled])
	{
		return;
	}
	
	@synchronized(self)
	{
		[favoritesBeingAdded removeObjectForKey:addFavoriteOperation.cameraToFavorite.name];
		
		if (addFavoriteOperation.error)
		{
			// @todo should this be passed on to delegate? I can make a good case for handling here.
			DDLogError(@"Error adding favorite for camera %@: %@",
					   addFavoriteOperation.cameraToFavorite.name,
					   addFavoriteOperation.error);
		}
		else if (addFavoriteOperation.addedFavorite != nil)
		{
			CameraInfoWrapper * favorite = [[CameraInfoWrapper alloc] initWithFavorite:addFavoriteOperation.addedFavorite];
			[favorites addObject:favorite];
		}
		else
		{
			NSAssert(NO,@"Operation complete but no addedFavorite");
		}
	}
	
	[self notifyObserversOfFavorites:favorites orError:nil];
}


#pragma mark - Private methods

- (CameraInfoWrapper *)findFavoriteByName:(NSString *)name
{
	for (CameraInfoWrapper * camera in favorites)
	{
		if ([camera.name isEqualToString:name])
		{
			return camera;
		}
	}
	
	return nil;
}


- (void)notifyObserversOfFavorites:(NSArray *)newFavorites orError:(NSError *)error
{
	for (id <FavoritesObserver> observer in observers)
	{
		if ([observer respondsToSelector:@selector(favoritesUpdated:orError:)])
		{
			[observer favoritesUpdated:newFavorites orError:error];
		}
	}
}


#if 0 // @todo debug code
- (void)logCamera:(CameraInfoWrapper *)camera withHeader:(NSString *)header
{
	DDLogVerbose(header];
	DDLogVerbose(@"  Fav Name    : %@",camera.name];
	DDLogVerbose(@"  Fav Desc    : %@",camera.description];
	DDLogVerbose(@"  Server      : %@",camera.cameraInfo.server];
	DDLogVerbose(@"  Port        : %ld",camera.cameraInfo.port];
	DDLogVerbose(@"  URI         : %@",camera.cameraInfo.uri];
	DDLogVerbose(@"  Caption     : %@",camera.cameraInfo.caption];
	DDLogVerbose(@"  Type        : %xd",camera.cameraInfo.cameraType];
	DDLogVerbose(@"  Country     : %@",camera.cameraInfo.country];
	DDLogVerbose(@"  Province    : %@",camera.cameraInfo.province];
	DDLogVerbose(@"  City        : %@",camera.cameraInfo.city];
	DDLogVerbose(@"  Lat         : %f",camera.cameraInfo.latitude];
	DDLogVerbose(@"  Long        : %f",camera.cameraInfo.longitude];
	DDLogVerbose(@"  Description : %@",camera.cameraInfo.description];
	DDLogVerbose(@"  Inactive    : %@",camera.cameraInfo.inactive?@"YES":@"NO"];
	DDLogVerbose(@"  Thumbnail?  : %@",camera.cameraInfo.thumbnail?@"YES":@"NO"];
	DDLogVerbose(@"  Start Time  : %@",camera.cameraInfo.startTime];
}
#endif

@end
