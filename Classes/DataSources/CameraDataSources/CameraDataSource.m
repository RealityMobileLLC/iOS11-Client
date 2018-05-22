//
//  CameraDataSource.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CameraDataSource.h"
#import "CameraInfoWrapper.h"


@implementation CameraDataSource

@synthesize delegate;
@synthesize hidden;
@synthesize isLoading;
@synthesize cameras;


- (id)init
{
	self = [super init];
	if (self != nil)
	{
		cameras = nil;
		filteredCameras = nil;
		hidden = NO;
	}
	return self;
}

- (void)getCameras
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)getMoreCameras
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)refresh
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)cancel
{
	[self doesNotRecognizeSelector:_cmd];
}

- (void)reset
{
	[self cancel];
	cameras = nil;
	filteredCameras = nil;
}

- (void)toggleCategoryView
{
}

- (NSString *)title
{
	return nil;
}

- (NSString *)loadingCamerasText
{
	return nil;
}

- (NSString *)noCamerasText
{
	return nil;
}

- (NSString *)searchPlaceholderText
{
	return nil;
}

- (BOOL)supportsPtz
{
	return NO;
}

- (BOOL)supportsEdit
{
	return NO;
}

- (BOOL)supportsRefresh
{
	return NO;
}

- (BOOL)supportsPaging
{
	return NO;
}

- (BOOL)hasMoreCameras
{
	return NO;
}

- (BOOL)supportsCategories
{
	return NO;
}

- (BOOL)isShowingCategories
{
	return NO;
}

- (int)totalCameras
{
	[self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (NSUInteger)numberOfCameras
{
	return (cameras != nil) ? [cameras count] : 0;
}

- (NSUInteger)numberOfFilteredCameras
{
	return (filteredCameras != nil) ? [filteredCameras count] : 0;
}

- (NSUInteger)numberOfCamerasWithLocation
{
	NSUInteger count = 0;
	
	for (id browseNode in cameras)
	{
		if ([browseNode isKindOfClass:[CameraInfoWrapper class]])
		{
			CameraInfoWrapper * camera = (CameraInfoWrapper *)browseNode;
			if (camera.hasLocation)
			{
				count++;
			}
		}
	}
	
	return count;
}

- (NSArray *)camerasInCategory
{
	return self.cameras;
}

- (NSInteger)numberOfSections
{
	return 1;
}

- (NSInteger)numberOfFilteredSections
{
	return 1;
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
	return self.numberOfCameras;
}

- (NSInteger)numberOfRowsInFilteredSection:(NSInteger)section
{
	return self.numberOfFilteredCameras;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

- (NSString *)titleForHeaderInFilteredSection:(NSInteger)section
{
	return nil;
}

- (id)browseTreeNodeAtIndexPath:(NSIndexPath *)indexPath
{
	return (cameras == nil) ? nil : [cameras objectAtIndex:indexPath.row];
}

- (id)browseTreeNodeAtFilteredIndexPath:(NSIndexPath *)indexPath
{
	return (filteredCameras == nil) ? nil : [filteredCameras objectAtIndex:indexPath.row];
}

- (BOOL)canDeleteRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (BOOL)canDeleteRowAtFilteredIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (BOOL)deleteRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (BOOL)deleteRowAtFilteredIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (BOOL)filterCamerasForSearchText:(NSString *)searchText
{
	if (filteredCameras)
	{
		[filteredCameras removeAllObjects];
		
		for (id browseNode in cameras)
		{
			if ([browseNode isKindOfClass:[CameraInfoWrapper class]])
			{
				CameraInfoWrapper * camera = (CameraInfoWrapper *)browseNode;
				NSRange result = [camera.name rangeOfString:searchText
													options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
				
				if (result.location != NSNotFound)
				{
					[filteredCameras addObject:camera];
				}
			}
		}
    }
    
    return YES;
}

- (void)searchForText:(NSString *)searchText
{
}

- (void)endSearch
{
}

- (NSMutableArray *)updateCameras:(NSArray *)oldList 
						fromArray:(NSArray *)newList
					 camerasAdded:(NSMutableArray *)camerasAdded 
				   camerasRemoved:(NSMutableArray *)camerasRemoved
				   camerasUpdated:(NSMutableArray *)camerasUpdated
{
	NSMutableArray * mergedList = [NSMutableArray arrayWithCapacity:[newList count]];
    
    if (oldList == nil)
    {
        // handle special case where there is no old list
        [camerasAdded addObjectsFromArray:newList];
        [mergedList addObjectsFromArray:newList];
        return mergedList;
    }
	
	NSEnumerator * newEnumerator = [newList objectEnumerator];
	NSEnumerator * oldEnumerator = [oldList objectEnumerator];
	
	CameraInfoWrapper * newItem = [newEnumerator nextObject];
	CameraInfoWrapper * oldItem = [oldEnumerator nextObject];
	
	// copy items until we reach the end of either list
	while ((newItem != nil) && (oldItem != nil))
	{
		if ([newItem isEqual:oldItem])
		{
			// item is in both lists so update it and add it to the new merged list
            if ([oldItem updateCameraInfoFrom:newItem])
			{
				[camerasUpdated addObject:oldItem];
			}
			
			[mergedList addObject:oldItem];
			newItem = [newEnumerator nextObject];
			oldItem = [oldEnumerator nextObject];
		}
		else if (! [oldList containsObject:newItem])
		{
			// item is in new list but not old list so add it
			[camerasAdded addObject:newItem];
			[mergedList addObject:newItem];
			newItem = [newEnumerator nextObject];
		}
		else
		{
			// item is in old list but not new list so skip it
			[camerasRemoved addObject:oldItem];
			oldItem = [oldEnumerator nextObject];
		}
	}
    
	// add remaining items from new list that weren't in old list
	while (newItem != nil)
	{
        [camerasAdded addObject:newItem];
		[mergedList addObject:newItem];
		newItem = [newEnumerator nextObject];
	}
    
    // remove remaining items from old list that aren't in new list
    while (oldItem != nil)
    {
        [camerasRemoved addObject:oldItem];
        oldItem = [oldEnumerator nextObject];
    }
	
	return mergedList;
}

- (void)notifyDelegateCamerasAdded:(NSArray *)camerasAdded 
                    camerasRemoved:(NSArray *)camerasRemoved
					camerasUpdated:(NSArray *)camerasUpdated
{
    if ([self.delegate respondsToSelector:@selector(cameraListUpdatedForDataSource:)])
    {
        [self.delegate cameraListUpdatedForDataSource:self];
    }
	
	if ((camerasRemoved != nil) && ([camerasRemoved count] > 0) && 
        ([self.delegate respondsToSelector:@selector(dataSource:removedCameras:)]))
	{
		[self.delegate dataSource:self removedCameras:camerasRemoved];
	}
	
	if ((camerasAdded != nil) && ([camerasAdded count] > 0) &&
        ([self.delegate respondsToSelector:@selector(dataSource:addedCameras:)]))
	{
		[self.delegate dataSource:self addedCameras:camerasAdded];
	}
	
	if ((camerasUpdated != nil) && ([camerasUpdated count] > 0) &&
		([self.delegate respondsToSelector:@selector(dataSource:updatedCameras:)]))
	{
		[self.delegate dataSource:self updatedCameras:camerasUpdated];
	}
}

@end
