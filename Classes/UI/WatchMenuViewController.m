//
//  WatchMenuViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "WatchMenuViewController.h"
#import "BrowseTreeNode.h"
#import "BrowseViewController.h"
#import "MenuItem.h"
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


@implementation WatchMenuViewController
{
	NSArray * menuItems;
	BOOL      keepFavoritesOnDisappear;
}


#pragma mark - Initialization and cleanup

- (void)createMenu
{
	MenuItem * myVideos = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"My Video History",@"My video history menu label") 
													image:@"category_user"];
	myVideos.tag = BC_MyVideos;
	
	MenuItem * favorites = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Favorites",@"Favorites menu label") 
													 image:@"category_favorites"];
	favorites.tag = BC_Favorites;
	
	MenuItem * cameras = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Cameras",@"Cameras menu label")
												   image:@"category_cameras"];
	cameras.tag = BC_Cameras;
	
	MenuItem * screencasts = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Screencasts",@"Screencasts menu label")
													   image:@"category_screencasts"];
	screencasts.tag = BC_Screencasts;
	
	MenuItem * videoFiles = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Video Files",@"Video files menu label")
													  image:@"category_files"];
	videoFiles.tag = BC_Files;
	
	MenuItem * roving = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"User Feeds",@"User feeds menu label")
												  image:@"category_live"];
	roving.tag = BC_Transmitters;
	
	menuItems = [NSArray arrayWithObjects:favorites, roving, cameras, screencasts, videoFiles, myVideos, nil];
	
}


- (void)createToolbarItems
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		UIBarButtonItem * flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
																					target:nil 
																					action:nil];
		
		UIBarButtonItem * homeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Home",@"Home button") 
																		style:UIBarButtonItemStyleBordered 
																	   target:[RealityVisionAppDelegate rootViewController] 
																	   action:@selector(showRootView)];
		
		self.toolbarItems = [NSArray arrayWithObjects:flexSpace, homeButton, nil];
		
	}
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"WatchMenuViewController viewDidLoad");
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Watch", @"Watch");
	[self createMenu];
	[self createToolbarItems];
}


- (void)viewDidUnload 
{
	DDLogVerbose(@"WatchMenuViewController viewDidUnload");
    [super viewDidUnload];
	menuItems = nil;
}


- (void)viewWillAppear:(BOOL)animated 
{
	DDLogVerbose(@"WatchMenuViewController viewWillAppear");
    [super viewWillAppear:animated];
	
	// cache favorites until we leave the navigation stack
	[FavoritesManager updateAndAddObserver:self];
	[self.tableView reloadData];
}


- (void)viewDidDisappear:(BOOL)animated
{
	if (! keepFavoritesOnDisappear)
	{
		[FavoritesManager removeObserver:self];
	}
	else
	{
		keepFavoritesOnDisappear = NO;
	}
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark - Table view data source

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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
									   reuseIdentifier:CellIdentifier];
    }
    
	MenuItem * item      = [menuItems objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:item.image];
	cell.textLabel.text  = item.label;
	cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	MenuItem * item = [menuItems objectAtIndex:indexPath.row];
	DDLogInfo(@"WatchMenuViewController: User selected %@", item.label);

	BrowseViewController * browseViewController = 
		[[BrowseViewController alloc] initWithNibName:@"BrowseViewController" 
												bundle:nil];
	
	browseViewController.cameraCategory   = item.tag;
	browseViewController.cameraDataSource = [self cameraDataSourceForCategory:browseViewController.cameraCategory 
																 withDelegate:browseViewController];
	
	if (browseViewController.cameraDataSource != nil)
	{
		keepFavoritesOnDisappear = YES;
		[self.navigationController pushViewController:browseViewController animated:YES];
	}
	
	[theTableView deselectRowAtIndexPath:indexPath animated:YES];
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

@end
