//
//  CameraFavoritesDataSource.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CameraFavoritesDataSource.h"
#import "CameraInfoWrapper.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CameraFavoritesDataSource

- (id)initWithCameraDelegate:(id <CameraDataSourceDelegate>)myDelegate
{
	self = [super init];
	if (self != nil)
	{
		self.delegate = myDelegate;
	}
	return self;
}


- (NSString *)title
{
	return NSLocalizedString(@"Favorites",@"Browse favorites title");
}


- (NSString *)loadingCamerasText
{
	return NSLocalizedString(@"Loading Favorites ...",@"Loading favorites");
}


- (NSString *)noCamerasText
{
	return NSLocalizedString(@"No Favorites",@"No favorites");
}


- (NSString *)searchPlaceholderText
{
	return NSLocalizedString(@"Search Favorites",@"Search favorites");
}


- (BOOL)supportsPtz
{
	return YES;
}


- (BOOL)supportsEdit
{
	return YES;
}


- (void)getCameras
{
	isLoading = YES;
	[FavoritesManager updateAndAddObserver:self];
}


- (void)refresh
{
	if (! isLoading)
	{
		[FavoritesManager invalidate];
		[self getCameras];
	}
}


- (void)cancel
{
	isLoading = NO;
	[FavoritesManager removeObserver:self];
}


- (BOOL)canDeleteRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row < [cameras count];
}


- (BOOL)canDeleteRowAtFilteredIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row < [filteredCameras count];
}


- (BOOL)deleteCamera:(CameraInfoWrapper *)cameraToDelete 
		 atIndexPath:(NSIndexPath *)indexPath 
{
    [FavoritesManager remove:cameraToDelete];
    [cameras removeObject:cameraToDelete];
    return NO;
}


- (BOOL)deleteRowAtIndexPath:(NSIndexPath *)indexPath
{
	CameraInfoWrapper * cameraToDelete = [cameras objectAtIndex:indexPath.row];
	return [self deleteCamera:cameraToDelete atIndexPath:indexPath];
}


- (BOOL)deleteRowAtFilteredIndexPath:(NSIndexPath *)indexPath
{
	CameraInfoWrapper * cameraToDelete = [filteredCameras objectAtIndex:indexPath.row];
	return [self deleteCamera:cameraToDelete atIndexPath:indexPath];
}


- (void)favoritesUpdated:(NSArray *)favorites orError:(NSError *)error
{
	DDLogInfo(@"CameraFavoritesDataSource didUpdateFavorites");
	isLoading = NO;
	
	if (error != nil)
	{
		[self.delegate cameraListDidGetError:error];
		return;
	}
	
	NSMutableArray * camerasAdded   = [NSMutableArray arrayWithCapacity:[favorites count]];
	NSMutableArray * camerasRemoved = [NSMutableArray arrayWithCapacity:[favorites count]];
	NSMutableArray * camerasUpdated = [NSMutableArray arrayWithCapacity:[favorites count]];
    
    cameras = [self updateCameras:cameras 
						fromArray:[favorites sortedArrayUsingSelector:@selector(compareNameAndStartTime:)]
					 camerasAdded:camerasAdded 
				   camerasRemoved:camerasRemoved
				   camerasUpdated:camerasUpdated];
	
	filteredCameras = [[NSMutableArray alloc] initWithCapacity:[cameras count]];
    
	[self notifyDelegateCamerasAdded:camerasAdded camerasRemoved:camerasRemoved camerasUpdated:camerasUpdated];
}

@end
