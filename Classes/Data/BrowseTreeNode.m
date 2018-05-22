//
//  BrowseTreeNode.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/24/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "BrowseTreeNode.h"
#import "CameraInfo.h"
#import "CameraInfoWrapper.h"


#ifdef RV_USES_GET_ALL_CAMERAS
NSString * const RootCategoryCameras     = @"Cameras";
NSString * const RootCategoryScreencasts = @"Screencasts";
NSString * const RootCategoryFiles       = @"Files";
#endif


//@interface BrowseTreeNode()
//- (void)makeTreeFromArray:(NSArray *)arrayOfCameras;
//@end


@implementation BrowseTreeNode
{
	NSMutableArray * categories;
	NSMutableArray * cameras;
}

@synthesize parent;
@synthesize title;
@synthesize allCameras;


#pragma mark - Initialization and cleanup

- (id)initWithCameras:(NSArray *)arrayOfCameras andTitle:(NSString *)rootTitle
{
	self = [super init];
	if (self != nil)
	{
		parent = nil;
		title = rootTitle;
		allCameras = arrayOfCameras;
		categories = [NSMutableArray array];
		cameras = [NSMutableArray array];
		[self makeTreeFromArray:arrayOfCameras];
	}
	return self;
}


- (id)initWithParent:(BrowseTreeNode *)myParent title:(NSString *)myTitle cameras:(NSArray *)arrayOfCameras
{
	self = [super init];
	if (self != nil)
	{
        // do NOT retain parent
		parent = myParent;
		title = myTitle;
		allCameras = arrayOfCameras;
		categories = [NSMutableArray array];
		cameras = [NSMutableArray array];
	}
	return self;
}


#pragma mark - Public properties and methods

- (NSArray *)childrenForCategoryView
{
	NSUInteger childCount = [categories count] + [cameras count];
	NSMutableArray * children = [NSMutableArray arrayWithCapacity:childCount];
	[children addObjectsFromArray:[categories sortedArrayUsingSelector:@selector(compare:)]];
	[children addObjectsFromArray:[cameras sortedArrayUsingSelector:@selector(compare:)]];
	return children;
}


- (NSArray *)unsortedChildrenForListView
{
	NSUInteger childCount = [allCameras count];
	NSMutableArray * children = [NSMutableArray arrayWithCapacity:childCount];
	[children addObjectsFromArray:cameras];
	
	for (BrowseTreeNode * category in categories)
	{
		[children addObjectsFromArray:[category unsortedChildrenForListView]];
	}
	
	return children;
}


- (NSArray *)childrenForListView
{
	// recurse through child nodes and return the sorted result
	return (parent == nil) ? allCameras : [[self unsortedChildrenForListView] sortedArrayUsingSelector:@selector(compare:)];
}


- (BrowseTreeNode *)getCategory:(NSString *)category
{
	for (BrowseTreeNode * node in categories)
	{
		if ([node.title isEqualToString:category])
		{
			return node;
		}
	}
	
	return nil;
}


- (NSComparisonResult)compare:(BrowseTreeNode *)camera
{
	return [self.title localizedCaseInsensitiveCompare:camera.title];
}


#pragma mark - Private methods

- (BrowseTreeNode *)getOrCreateCategory:(NSString *)category
{
	BrowseTreeNode * node = [self getCategory:category];
	
	if (node == nil)
	{
		node = [[BrowseTreeNode alloc] initWithParent:self title:category cameras:allCameras];
		if (node != nil)
		{
			[categories addObject:node];
		}
	}
	
	return node;
}


- (void)addCamera:(CameraInfoWrapper *)camera
{
	[cameras addObject:camera];
}


- (void)makeTreeFromArray:(NSArray *)arrayOfCameras
{
#ifdef RV_USES_GET_ALL_CAMERAS
	BrowseTreeNode * cameraTree     = [self getOrCreateCategory:RootCategoryCameras];
	BrowseTreeNode * screencastTree = [self getOrCreateCategory:RootCategoryScreencasts];
	BrowseTreeNode * videofileTree  = [self getOrCreateCategory:RootCategoryFiles];
#endif
	
	for (CameraInfoWrapper * camera in arrayOfCameras) 
	{
		CameraInfo * cameraInfo = camera.cameraInfo;
		
#ifdef RV_USES_GET_ALL_CAMERAS
		BrowseTreeNode * tree = camera.isScreencast ? screencastTree : camera.isVideoFile ? videofileTree : cameraTree;
#else
        BrowseTreeNode * tree = self;
#endif
		NSString * tier1Category = [cameraInfo.country  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSString * tier2Category = [cameraInfo.province stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		NSString * tier3Category = [cameraInfo.city     stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		if (([tier1Category length] > 0) && ([tier2Category length] > 0) && ([tier3Category length] > 0)) 
		{
			BrowseTreeNode * tier1Node = [tree      getOrCreateCategory:tier1Category];
			BrowseTreeNode * tier2Node = [tier1Node getOrCreateCategory:tier2Category];
			BrowseTreeNode * tier3Node = [tier2Node getOrCreateCategory:tier3Category];
			[tier3Node addCamera:camera];
		}
		else if (([tier1Category length] > 0) && ([tier2Category length] > 0)) 
		{
			BrowseTreeNode * tier1Node = [tree      getOrCreateCategory:tier1Category];
			BrowseTreeNode * tier2Node = [tier1Node getOrCreateCategory:tier2Category];
			[tier2Node addCamera:camera];
		}
		else if ([tier1Category length] > 0) 
		{
			BrowseTreeNode * tier1Node = [tree getOrCreateCategory:tier1Category];
			[tier1Node addCamera:camera];
		}
		else 
		{
			[tree addCamera:camera];
		}
	}
}

@end
