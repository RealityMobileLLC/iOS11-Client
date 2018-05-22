//
//  VideoSourcesFilterViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 12/22/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import "VideoSourcesFilterViewController.h"
#import "BrowseCameraCategory.h"
#import "BrowseViewController.h"
#import "MainMapViewController.h"
#import "CameraArchivesDataSource.h"
#import "CameraCatalogDataSource.h"
#import "CameraFavoritesDataSource.h"
#import "CameraFilesDataSource.h"
#import "CameraScreencastsDataSource.h"
#import "CameraTransmittersDataSource.h"
#import "RealityVisionAppDelegate.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


static NSArray * menuItems;


@interface MenuFilter : NSObject

@property (nonatomic,strong) NSString * text;
@property (nonatomic)        BrowseCameraCategory category;
@property (nonatomic)        BOOL show;

+ (id)mapFilterWithText:(NSString *)text andCategory:(BrowseCameraCategory)category;

@end


@implementation MenuFilter

@synthesize text;
@synthesize category;
@synthesize show;

+ (id)mapFilterWithText:(NSString *)text andCategory:(BrowseCameraCategory)category
{
    MenuFilter * filter = [[MenuFilter alloc] init];
    if (filter != nil)
    {
        filter.text = text;
        filter.category = category;
        filter.show = YES;
    }
    return filter;
}

@end



@implementation VideoSourcesFilterViewController

@synthesize mapViewController;


#pragma mark - Initialization and cleanup

+ (void)initialize
{
    if (self == [VideoSourcesFilterViewController class])
    {
        MenuFilter * favorites = 
            [MenuFilter mapFilterWithText:NSLocalizedString(@"Favorites",@"Favorites") 
                                                    andCategory:BC_Favorites];
        
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
        MenuFilter * roving = 
            [MenuFilter mapFilterWithText:NSLocalizedString(@"User Feeds",@"User Feeds") 
                                                    andCategory:BC_Transmitters];
#endif
		
        MenuFilter * catalog = 
            [MenuFilter mapFilterWithText:NSLocalizedString(@"Cameras",@"Cameras") 
                                                    andCategory:BC_Cameras];
        
#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
		MenuFilter * files = 
            [MenuFilter mapFilterWithText:NSLocalizedString(@"Video Files",@"Video Files") 
                                                    andCategory:BC_Files];
		
		MenuFilter * screencasts = 
            [MenuFilter mapFilterWithText:NSLocalizedString(@"Screencasts",@"Screencasts") 
                                                    andCategory:BC_Screencasts];
#endif
        
        menuItems = [[NSArray alloc] initWithObjects:favorites,
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
                                                     roving,
#endif
                                                     catalog,
#ifdef RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS
                                                     screencasts,
                                                     files,
#endif
                                                     nil];
    }
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"VideoSourcesFilterViewController viewDidLoad");
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Video Sources",@"Video Sources filter title");
	
	// @todo mainmapviewcontroller should be setting this
	RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
	self.mapViewController = (MainMapViewController *)appDelegate.rootViewController;
}


- (void)viewDidUnload 
{
	DDLogVerbose(@"VideoSourcesFilterViewController viewDidUnload");
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


- (CGSize)contentSizeForViewInPopover
{
    CGSize size = CGSizeMake(310, self.tableView.rowHeight * [menuItems count]);
    return size;
}


#pragma mark -k Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [menuItems count];
}


- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString * CellIdentifier = @"Cell";
	
    UITableViewCell * cell = [theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
									   reuseIdentifier:CellIdentifier];
		
		UILongPressGestureRecognizer * longPressGesture = 
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
		
		[cell addGestureRecognizer:longPressGesture];
    }
    
    MenuFilter * filter = [menuItems objectAtIndex:indexPath.row];
	CameraDataSource * dataSource = [self.mapViewController cameraDataSourceForCategory:filter.category];
	filter.show = ! dataSource.hidden;
	cell.tag = indexPath.row;
	cell.textLabel.text = filter.text;
	
	if (dataSource.numberOfCameras > 0)
	{
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%d / %d    ", dataSource.numberOfCamerasWithLocation, dataSource.numberOfCameras];
	}
	
	if (filter.show)
	{
		cell.accessoryView = nil;
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else
	{
		// setting the accessoryType to None causes the detail text to extend, so we'll replace the accessoryView with an empty frame
		cell.accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
	}
    
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
    // disable the user feeds (transmitters) row if users are shown
    BOOL rowEnabled = (filter.category != BC_Transmitters) || (! self.mapViewController.showUsers);
    cell.textLabel.enabled = cell.detailTextLabel.enabled = rowEnabled;
    cell.selectionStyle = (rowEnabled) ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
#endif
	
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	MenuFilter * filter = [menuItems objectAtIndex:indexPath.row];
    
#ifdef RV_CAMERA_FILTER_INCLUDES_USER_FEEDS
    // disable the user feeds (transmitters) row if users are shown
    BOOL rowEnabled = (filter.category != BC_Transmitters) || (! self.mapViewController.showUsers);
    if (! rowEnabled)
    {
        return;
    }
#endif
    
    filter.show = ! filter.show;
    [self.mapViewController filterCamerasOfType:filter.category show:filter.show];
    [self.tableView reloadData];
}


#pragma mark - Private methods

- (CameraDataSource *)cameraDataSourceForCategory:(BrowseCameraCategory)category withDelegate:(id)delegate
{
	switch (category)
	{
		case BC_MyVideos:
			return [[CameraArchivesDataSource alloc] initWithCameraDelegate:delegate];
			
		case BC_Favorites:
			return [[CameraFavoritesDataSource alloc] initWithCameraDelegate:delegate];
			
		case BC_Cameras:
			return [[CameraCatalogDataSource alloc] initWithCameraDelegate:delegate];
			
		case BC_Screencasts:
			return [[CameraScreencastsDataSource alloc] initWithCameraDelegate:delegate];
			
		case BC_Files:
			return [[CameraFilesDataSource alloc] initWithCameraDelegate:delegate];
			
		case BC_Transmitters:
			return [[CameraTransmittersDataSource alloc] initWithCameraDelegate:delegate];
			
		default:
			return nil;
	}
}


- (void)longPress:(UILongPressGestureRecognizer *)gesture
{
	if (gesture.state == UIGestureRecognizerStateBegan)
	{
		UITableViewCell * cell = (UITableViewCell *)gesture.view;
		MenuFilter * filter = [menuItems objectAtIndex:cell.tag];
		
		BrowseViewController * browseViewController = 
            [[BrowseViewController alloc] initWithNibName:@"BrowseViewController" 
                                                    bundle:nil];
		
		browseViewController.cameraCategory = filter.category;
		browseViewController.cameraDataSource = [self cameraDataSourceForCategory:browseViewController.cameraCategory 
																	 withDelegate:browseViewController];
		
		if (browseViewController.cameraDataSource != nil)
		{
			RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
			[appDelegate.navigationController pushViewController:browseViewController animated:YES];
		}
	}
}

@end
