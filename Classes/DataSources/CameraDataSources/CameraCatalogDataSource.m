//
//  CameraCatalogDataSource.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CameraCatalogDataSource.h"
#import "ClientConfiguration.h"
#import "CameraInfo.h"
#import "SystemUris.h"
#import "BrowseTreeNode.h"
#import "CameraInfoWrapper.h"
#import "ConfigurationManager.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CameraCatalogDataSource
{
	BrowseTreeNode * browseTree;
	CatalogService * webService;
	BOOL             showCategories;
}


- (id)initWithCameraDelegate:(id <CameraDataSourceDelegate>)myDelegate
{
	self = [super init];
	if (self != nil)
	{
		self.delegate = myDelegate;
	}
	return self;
}

- (id)initWithBrowseTree:(BrowseTreeNode *)myBrowseTree andDelegate:(id <CameraDataSourceDelegate>)myDelegate
{
	self = [self initWithCameraDelegate:myDelegate];
	if (self != nil)
	{
		self.delegate = myDelegate;
		browseTree = myBrowseTree;
		showCategories = YES;
	}
	return self;
}

- (NSString *)title
{
	return (browseTree != nil) ? browseTree.title : NSLocalizedString(@"Cameras",@"Browse cameras title");
}

- (NSString *)loadingCamerasText
{
	return NSLocalizedString(@"Loading Cameras ...",@"Loading cameras");
}

- (NSString *)noCamerasText
{
	return NSLocalizedString(@"No Cameras",@"No cameras");
}

- (NSString *)searchPlaceholderText
{
	return NSLocalizedString(@"Search Cameras",@"Search cameras");
}

- (BOOL)supportsPtz
{
	return YES;
}

- (NSArray *)camerasInCategory
{
	return browseTree.childrenForListView;
}

- (void)getCameras
{
	if (browseTree != nil)
	{
		[self setCameraListAndNotifyDelegateCamerasAdded:nil camerasRemoved:nil camerasUpdated:nil];
	}
	else 
	{
		[self refresh];
	}
}

- (void)refresh
{
	if (! isLoading)
	{
		isLoading = YES;
		NSURL * catalogServiceUrl = [ConfigurationManager instance].systemUris.catalogServiceRest;
		webService = [[CatalogService alloc] initWithUrl:catalogServiceUrl
											 andDelegate:self];
		[webService getFixedCameras];
	}
}

- (void)cancel
{
	if (isLoading)
	{
		isLoading = NO;
		[webService cancel];
		webService = nil;
	}
}

- (void)reset
{
	[super reset];
	webService = nil;
	browseTree = nil;
}

- (void)toggleCategoryView
{
	showCategories = ! showCategories;
	[self setCameraListAndNotifyDelegateCamerasAdded:nil camerasRemoved:nil camerasUpdated:nil];
}

- (BOOL)supportsCategories
{
	return YES;
}

- (BOOL)isShowingCategories
{
	return showCategories;
}

- (BOOL)filterCamerasForSearchText:(NSString *)searchText
{
	if (filteredCameras != nil)
	{
		[filteredCameras removeAllObjects];
		
		for (id browseNode in browseTree.childrenForListView)
		{
			NSAssert([browseNode isKindOfClass:[CameraInfoWrapper class]],@"Browse node must be a camera");
			CameraInfoWrapper * camera = (CameraInfoWrapper *)browseNode;
			NSRange result = [camera.name rangeOfString:searchText
												options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
			
			if (result.location != NSNotFound)
			{
				[filteredCameras addObject:camera];
			}
		}
    }
    
    return  YES;
}


- (void)onGetCamerasResult:(NSArray *)camerasResult error:(NSError *)error
{
	if (isLoading)
	{
		DDLogInfo(@"CameraCatalogDataSource onGetCamerasResult");
		isLoading = NO;
		
		if ((camerasResult == nil) && (error == nil))
		{
			error = [RvError rvErrorWithLocalizedDescription:@"Did not receive the list of cameras from the Catalog Service."];
		}
		
		if (error != nil)
		{
			[self.delegate cameraListDidGetError:error];
			webService.self.delegate = nil;
			webService = nil;
			return;
		}
		
		NSMutableArray * allCameras     = [NSMutableArray arrayWithCapacity:[camerasResult count]];
		NSMutableArray * camerasAdded   = [NSMutableArray arrayWithCapacity:[camerasResult count]];
		NSMutableArray * camerasRemoved = [NSMutableArray arrayWithCapacity:[camerasResult count]];
		NSMutableArray * camerasUpdated = [NSMutableArray arrayWithCapacity:[camerasResult count]];
		
		// create array of cameras from result
		for (CameraInfo * cameraInfo in camerasResult)
		{
			if (! cameraInfo.inactive)
			{
				CameraInfoWrapper * camera = [[CameraInfoWrapper alloc] initWithCamera:cameraInfo];
				[allCameras addObject:camera];
			}
		}
        
		NSArray * newCameras = [self updateCameras:(browseTree == nil) ? nil : browseTree.allCameras 
										 fromArray:allCameras
									  camerasAdded:camerasAdded 
									camerasRemoved:camerasRemoved 
									camerasUpdated:camerasUpdated];
		
		// create a browse tree with the list of cameras
		browseTree = [[BrowseTreeNode alloc] initWithCameras:newCameras 
														  andTitle:NSLocalizedString(@"Cameras",@"Cameras")];
		
		// update the displayable list of cameras for this data source
		[self setCameraListAndNotifyDelegateCamerasAdded:camerasAdded 
										  camerasRemoved:camerasRemoved 
										  camerasUpdated:camerasUpdated];
	}
	
	webService.self.delegate = nil;
	webService = nil;
}


- (void)setCameraListAndNotifyDelegateCamerasAdded:(NSArray *)camerasAdded 
									camerasRemoved:(NSArray *)camerasRemoved 
									camerasUpdated:(NSArray *)camerasUpdated
{
	NSArray * cameraList = (showCategories) ? browseTree.childrenForCategoryView : browseTree.childrenForListView;
	
	cameras = [[NSMutableArray alloc] initWithArray:cameraList];
	
	filteredCameras = [[NSMutableArray alloc] initWithCapacity:[browseTree.allCameras count]];
	
	[self notifyDelegateCamerasAdded:camerasAdded camerasRemoved:camerasRemoved camerasUpdated:camerasUpdated];
}

@end
