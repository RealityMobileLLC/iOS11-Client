//
//  MapFindViewController.m
//  RealityVision
//
//  Created by Valerie Smith on 4/10/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "MapFindViewController.h"
#import "CameraInfo.h"
#import "CameraInfoWrapper.h"
#import "Device.h"
#import "MenuItem.h"
#import "MainMapViewController.h"
#import "VideoSourcesFilterViewController.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"
#import <MapKit/MKAnnotation.h>
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


// @todo Is there a problem if the camera sources get updated by the server when we have this view open?  

@implementation MapFindViewController
{
	NSArray * allUserItems;
	NSArray * allCameraItems;
	NSArray * allScreencastItems;
	NSArray * allVideoFileItems;
	
	NSMutableArray * userItems;
	NSMutableArray * cameraItems;
	NSMutableArray * screencastItems;
	NSMutableArray * videoFileItems;
}

static NSString * kUserHeader;
static NSString * kCameraHeader;
static NSString * kScreencastHeader;
static NSString * kVideoFileHeader;

@synthesize mapViewController;
@synthesize popoverController;
@synthesize searchBar;


+ (void)initialize
{
	if (self == [MapFindViewController class])
	{
		kUserHeader = NSLocalizedString(@"Users",@"User section header in find button");
		kCameraHeader = NSLocalizedString(@"Cameras",@"Camera section header in find button");
		kScreencastHeader = NSLocalizedString(@"Screencasts",@"Screencast section header in find button");
		kVideoFileHeader = NSLocalizedString(@"Video Files",@"Video File section header in find button");
	}
}

- (void)viewDidLoad
{
	DDLogVerbose(@"%@ %@", THIS_FILE, THIS_METHOD);
    [super viewDidLoad];	
    self.title = NSLocalizedString(@"Find",@"Find title");
	self.searchBar.placeholder = NSLocalizedString(@"Find user or video source",@"Find user or video source search bar placeholder text");
	
	allUserItems = [self.mapViewController userMapObjects];
	allCameraItems = [self.mapViewController cameraMapObjects];
	allScreencastItems = [self.mapViewController screencastMapObjects];
	allVideoFileItems = [self.mapViewController videoFileMapObjects];
	
	userItems = [NSMutableArray arrayWithArray:allUserItems];
	cameraItems = [NSMutableArray arrayWithArray:allCameraItems];
	screencastItems = [NSMutableArray arrayWithArray:allScreencastItems];
	videoFileItems = [NSMutableArray arrayWithArray:allVideoFileItems];
	
	int allItemsCount = allUserItems.count + allCameraItems.count + allScreencastItems.count + allVideoFileItems.count;
	int rowsToDisplay = MIN(7,allItemsCount) + 2;
	CGFloat contentHeight = self.tableView.rowHeight * rowsToDisplay;
	self.contentSizeForViewInPopover = CGSizeMake(330, contentHeight);
}

- (void)viewDidAppear:(BOOL)animated
{
	DDLogVerbose(@"%@ %@", THIS_FILE, THIS_METHOD);
	if ([[RealityVisionClient instance].searchText length] > 0)
	{
		[self.searchDisplayController setActive:YES animated:YES];
		self.searchDisplayController.searchBar.text = [RealityVisionClient instance].searchText;
	}
}

- (void)viewWillDisappear:(BOOL)animated
{	
	DDLogVerbose(@"%@ %@", THIS_FILE, THIS_METHOD);
	RealityVisionClient * client = [RealityVisionClient instance];
	if (client.isSignedOn)
	{
		client.searchText = self.searchDisplayController.searchBar.text;
	}
}

- (void)viewDidUnload
{	
	DDLogVerbose(@"%@ %@", THIS_FILE, THIS_METHOD);
    [super viewDidUnload];
	userItems = nil;
	cameraItems = nil;
	screencastItems = nil;
	videoFileItems = nil;
	allUserItems = nil;
	allCameraItems = nil;
	allScreencastItems = nil;
	allVideoFileItems = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark - Table view data source

- (NSArray *)arrayForSection:(NSInteger)section inTableView:(UITableView *)tableView
{
	return (tableView == self.tableView) ? [self arrayForSection:section] : [self arrayForFilteredSection:section];
}

- (NSArray *)arrayForSection:(NSInteger)section
{
	switch(section)
	{
		case 0: return allUserItems;
		case 1: return allCameraItems;
		case 2: return allScreencastItems;
		case 3: return allVideoFileItems;
			
		default: return nil;
	}
}

- (NSMutableArray *)arrayForFilteredSection:(NSInteger)section
{
	switch(section)
	{
		case 0: return userItems;
		case 1: return cameraItems;
		case 2: return screencastItems;
		case 3: return videoFileItems;
			
		default: return nil;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self arrayForSection:section inTableView:tableView].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
									  reuseIdentifier:CellIdentifier];
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
	NSArray * sectionItems = [self arrayForSection:indexPath.section inTableView:tableView];
	id<MapObject> mapObject = [sectionItems objectAtIndex:indexPath.row];
	cell.textLabel.text = [NSString stringWithFormat:@"  %@", [self nameOfMapObject:mapObject]];
	
    return cell;
}


#pragma mark - Table view delegate (UITableViewDelegate)

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.mapViewController.isCenteredOnCameras)
		self.mapViewController.isCenteredOnCameras = NO;
	
	if (self.mapViewController.isTrackingLocation)
		self.mapViewController.isTrackingLocation = NO;
	
	NSArray * sectionItems = [self arrayForSection:indexPath.section inTableView:tableView];
	if (sectionItems.count)
	{
		id<MapObject> selected = [sectionItems objectAtIndex:indexPath.row];
		
		if (indexPath.section == 0)
		{
			if (!self.mapViewController.showUsers)
			{
				// if this source type is non-visible, make visible in the Filter list
				self.mapViewController.showUsers = YES;
			}
		}
		else 
		{
			BrowseCameraCategory category = [self categoryForSection:indexPath.section];
			if ([self.mapViewController cameraDataSourceForCategory:category].hidden)
			{
				// if this source type is non-visible, make visible in the Filter list
				[self.mapViewController filterCamerasOfType:category show:YES];
			}
		}
		
		MKCoordinateRegion mapRegion = MKCoordinateRegionMake(selected.coordinate,
															  MKCoordinateSpanMake(2.0/69.0, 2.0/69.0));
		
		[self.mapViewController.mapView setRegion:mapRegion animated:YES];
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case 0: return kUserHeader;
		case 1: return kCameraHeader;
		case 2: return kScreencastHeader;
		case 3: return kVideoFileHeader;
			
		default: return nil;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return ([self tableView:tableView numberOfRowsInSection:section] == 0) ? 0 : self.tableView.rowHeight * 0.8f;
}


#pragma mark - UISearchDisplayControllerDelegate methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	NSUInteger	oldUserItemsCount		= userItems.count,
				oldCameraItemsCount		= cameraItems.count,
				oldScreencastItemsCount = screencastItems.count,
				oldVideoFileItemsCount	= videoFileItems.count;

	[self filterMapObjectsForSearchString:searchString];
	
	return (   oldUserItemsCount       != userItems.count
			|| oldCameraItemsCount     != cameraItems.count
			|| oldScreencastItemsCount != screencastItems.count
			|| oldVideoFileItemsCount  != videoFileItems.count);
}


#pragma mark - Private methods

- (void)filterMapObjectsForSearchString:(NSString *)searchString
{
	[self filterMapObjects:allUserItems       forSearchString:searchString toArray:&userItems];
	[self filterMapObjects:allCameraItems     forSearchString:searchString toArray:&cameraItems];
	[self filterMapObjects:allScreencastItems forSearchString:searchString toArray:&screencastItems];
	[self filterMapObjects:allVideoFileItems  forSearchString:searchString toArray:&videoFileItems];
}

- (void)filterMapObjects:(NSArray *)mapObjects
		 forSearchString:(NSString *)text
				 toArray:(NSMutableArray * __strong *)filteredMapObjects
{
	[*filteredMapObjects removeAllObjects];
	
	if ([text length] == 0)
	{
		*filteredMapObjects = [NSMutableArray arrayWithArray:mapObjects];
	}
	else
	{
		for (id browseNode in mapObjects)
		{
			NSString * name = [self nameOfMapObject:browseNode];
			NSRange result = [name rangeOfString:text options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
			if (result.location != NSNotFound)
			{
				[*filteredMapObjects addObject:browseNode];
			}
		}
	}
}
						
- (NSString *)nameOfMapObject:(id<MapObject>)mapObject
{
	if ([mapObject isKindOfClass:[UserDevice class]])
		return ((UserDevice *)mapObject).device.fullName;
	
	if ([mapObject isKindOfClass:[CameraInfoWrapper class]])
		return ((CameraInfoWrapper *)[mapObject camera]).name;
	
	return nil;
}

- (BrowseCameraCategory)categoryForSection:(NSInteger)section
{
	// This only applies to CameraDataSource objects that don't represent Users
	switch(section)
	{
		case 1: return BC_Cameras;
		case 2: return BC_Screencasts;
		case 3: return BC_Files;
			
		default: return -1;
	}	
}

@end
