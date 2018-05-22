//
//  BrowseViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "BrowseViewController.h"
#import "ClientConfiguration.h"
#import "SystemUris.h"
#import "CameraInfo.h"
#import "FavoriteEntry.h"
#import "Session.h"
#import "TransmitterInfo.h"
#import "BrowseTreeNode.h"
#import "CameraInfoWrapper.h"
#import "FavoritesManager.h"
#import "ActivityTableViewCell.h"
#import "CameraTableViewCell.h"
#import "SelectableBarButtonItem.h"
#import "MotionJpegMapViewController.h"
#import "CameraDetailViewController.h"
#import "DetailArchiveDataSource.h"
#import "DetailCameraDataSource.h"
#import "DetailTransmitterDataSource.h"
#import "NSString+RealityVision.h"
#import "UIImage+RealityVision.h"
#import "UIView+Layout.h"
#import "CameraMapViewDelegate.h"
#import "RootViewController.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation BrowseViewController
{
	CameraMapViewDelegate * cameraMapDelegate;
}

@synthesize cameraCategory;
@synthesize cameraDataSource;
@synthesize activityTableViewCell;
@synthesize showMapButton;
@synthesize tableView;
@synthesize mapView;


#pragma mark - Initialization and cleanup

- (void)dealloc 
{
	mapView.delegate = nil;
	[cameraDataSource cancel];
}


#pragma mark - View lifecycle

- (void)createToolbarItems
{
	NSMutableArray * items = [NSMutableArray arrayWithCapacity:10];
	
	if (self.cameraDataSource.supportsRefresh)
	{
		[items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
																		target:self 
																		action:@selector(refresh:)]];
	}
	
	[items addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
																	target:nil 
																	action:nil]];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		if (cameraCategory != BC_MyVideos)
		{
			showMapButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Map",@"Map button") 
																   style:UIBarButtonItemStyleBordered 
																  target:self 
																  action:@selector(toggleMap:)];
			[items addObject:showMapButton];
		}
	}
	else
	{
		[items addObject:[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Home",@"Home button") 
														   style:UIBarButtonItemStyleBordered 
														  target:[RealityVisionAppDelegate rootViewController] 
														  action:@selector(showRootView)]];
	}
	
	// if the only item is the flexible space, don't show a toolbar
	if ([items count] > 1)
	{
		self.toolbarItems = items;
	}
}

- (void)viewDidLoad 
{
	NSAssert(self.cameraDataSource!=nil,@"The cameraDataSource property must be set");
	DDLogVerbose(@"BrowseViewController viewDidLoad");
	[super viewDidLoad];
	
	self.title = self.cameraDataSource.title;
	self.searchDisplayController.searchBar.placeholder = self.cameraDataSource.searchPlaceholderText;
	
	[self createToolbarItems];
	self.editButtonItem.enabled = NO;
	showMapButton.enabled = NO;
	cameraMapDelegate = [[CameraMapViewDelegate alloc] init];
	cameraMapDelegate.centerOnCameras = YES;
	self.mapView.delegate = cameraMapDelegate;
	self.mapView.mapType = [RealityVisionClient instance].mapType;
	
	if (self.cameraDataSource.supportsEdit)
	{
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	}
	else if (self.cameraDataSource.supportsCategories)
	{
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[self getCategoryButtonText] 
																				   style:UIBarButtonItemStyleBordered 
																			      target:self 
																			      action:@selector(toggleCategoryView)];
	}

	[self.tableView registerNib:[UINib nibWithNibName:@"CameraTableViewCell" bundle:nil]
		 forCellReuseIdentifier:[CameraTableViewCell reuseIdentifier]];
	
	[self.cameraDataSource getCameras];
}

- (void)viewDidUnload 
{
	DDLogVerbose(@"BrowseViewController viewDidUnload");
	[super viewDidUnload];
	showMapButton = nil;
	tableView = nil;
	mapView.delegate = nil;
	mapView = nil;
	cameraMapDelegate = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	// the main view has to be behind the map view
	[self.view sendSubviewToBack:self.tableView];
}

- (void)viewDidAppear:(BOOL)animated
{
	DDLogVerbose(@"BrowseViewController viewDidAppear");
	[super viewDidAppear:animated];
	[self.tableView reloadData];
	[self.tableView flashScrollIndicators];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	[self.tableView flashScrollIndicators];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated 
{
	[super setEditing:editing animated:animated];
	
	// needed because this is a UIViewController not a UITableViewController
	[self.tableView setEditing:editing animated:animated];
	
	if ((! editing) && (self.cameraDataSource.numberOfCameras == 0))
	{
		// if all cameras have been deleted when the user is done editing, disable the edit button
		self.editButtonItem.enabled = NO;
	}
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView 
{
	BOOL useFilteredSource = (theTableView == self.searchDisplayController.searchResultsTableView);
	NSInteger cameraSections = useFilteredSource ? self.cameraDataSource.numberOfFilteredSections : self.cameraDataSource.numberOfSections;
	return MAX(cameraSections,1);
}

- (NSString *)tableView:(UITableView *)theTableView titleForHeaderInSection:(NSInteger)section
{
	BOOL useFilteredSource = (theTableView == self.searchDisplayController.searchResultsTableView);
	return useFilteredSource ? [self.cameraDataSource titleForHeaderInFilteredSection:section] 
	                         : [self.cameraDataSource titleForHeaderInSection:section];
}

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section 
{
	BOOL useFilteredSource = (theTableView == self.searchDisplayController.searchResultsTableView);
	
	// if it's a paged data source that can get more results, add a row
	NSInteger hasMoreRow = self.cameraDataSource.hasMoreCameras ? 1 : 0;
	
	return useFilteredSource ? [self.cameraDataSource numberOfRowsInFilteredSection:section] 
	                         : MAX([self.cameraDataSource numberOfRowsInSection:section] + hasMoreRow, 1);
}

- (CGFloat)tableView:(UITableView *)theTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const CGFloat CAMERA_ROW_HEIGHT  = 72.0;
	const CGFloat DEFAULT_ROW_HEIGHT = 44.0;
	
	CGFloat rowHeight;
	BOOL useFilteredSource = (theTableView == self.searchDisplayController.searchResultsTableView);
	NSInteger numberOfCameras = useFilteredSource ? [self.cameraDataSource numberOfRowsInFilteredSection:indexPath.section]
	                                              : [self.cameraDataSource numberOfRowsInSection:indexPath.section];
	if (indexPath.row == numberOfCameras)
	{
		// if there are more rows than cameras, then either there are no cameras or this row is the "older videos" row
		rowHeight = (indexPath.row > 0) ? CAMERA_ROW_HEIGHT : DEFAULT_ROW_HEIGHT;
	}
	else 
	{
		// row height depends on whether the row is a camera or a category
		id browseNode = [self getCameraOrCategoryAtIndexPath:indexPath forTableView:theTableView];
		rowHeight = ([browseNode isKindOfClass:[CameraInfoWrapper class]]) ? CAMERA_ROW_HEIGHT : DEFAULT_ROW_HEIGHT;
	}
	
	return rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (self.cameraDataSource.isLoading)
	{
		self.activityTableViewCell = 
			[ActivityTableViewCell activityTableViewCellWithText:self.cameraDataSource.loadingCamerasText 
														andStart:YES];
		
		self.activityTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
		return self.activityTableViewCell;
	}
	
	BOOL useFilteredSource = (theTableView == self.searchDisplayController.searchResultsTableView);
    NSInteger numberOfRows = (useFilteredSource) ? [self.cameraDataSource numberOfRowsInFilteredSection:indexPath.section] 
                                                 : [self.cameraDataSource numberOfRowsInSection:indexPath.section];
    
	if (numberOfRows == 0)
	{
		self.activityTableViewCell = 
			[ActivityTableViewCell activityTableViewCellWithText:self.cameraDataSource.noCamerasText
														andStart:NO];
		
		self.activityTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
		return self.activityTableViewCell;
	}
	
	if (indexPath.row == numberOfRows)
	{
		self.activityTableViewCell = 
			[ActivityTableViewCell activityTableViewCellWithText:NSLocalizedString(@"Older Videos ...",@"Older videos prompt") 
														andStart:NO];
		
		self.activityTableViewCell.textLabel.textColor = [UIColor blueColor];
		self.activityTableViewCell.selectionStyle = UITableViewCellSelectionStyleBlue;
		return self.activityTableViewCell;
	}
	
	id browseNode = [self getCameraOrCategoryAtIndexPath:indexPath forTableView:theTableView];
	return ([browseNode isKindOfClass:[CameraInfoWrapper class]]) ? [self getTableViewCell:theTableView forCamera:browseNode]
	                                                              : [self getTableViewCell:theTableView forCategory:browseNode];
}

- (CameraTableViewCell *)getTableViewCell:(UITableView *)theTableView forCamera:(CameraInfoWrapper *)camera
{
	NSString * cellIdentifier = [CameraTableViewCell reuseIdentifier];
    CameraTableViewCell * cell = (CameraTableViewCell *)[theTableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (! self.cameraDataSource.supportsPtz)
	{
		// shift icons over to remove PTZ icon column
		CGFloat delta = cell.ptzIcon.frame.origin.x - cell.commentsIcon.frame.origin.x;
		[cell.commentsIcon moveOriginXBy:delta];
		[cell.commentsLabel moveOriginXBy:delta];
	}
	
	cell.captionLabel.text = camera.name;
	cell.descriptionLabel.text = camera.description;
	cell.ptzIcon.hidden = ! camera.isPanTiltZoom;
	cell.commentsIcon.hidden = cell.commentsLabel.hidden = (camera.numberOfComments == 0);
	cell.lengthLabel.hidden = camera.length < 0;
	
	// @todo BUG-2692
	cell.thumbnailView.image = (camera.thumbnail != nil)        ? camera.thumbnail : 
	                           (cameraCategory == BC_Favorites) ? [UIImage imageNamed:@"ic_list_empty_thumbnail"] 
	                                                            : [UIImage imageNamed:@"ic_list_inactive_thumbnail"];
	
    if (cameraCategory == BC_MyVideos)
    {
        Session * session = camera.sourceObject;
        cell.locationIcon.hidden = ! session.hasGps;
    }
    else
    {
        cell.locationIcon.hidden = ! camera.hasLocation;
    }
	
	if (camera.numberOfComments > 0)
	{
		cell.commentsLabel.text = [NSString stringWithFormat:@"%d", camera.numberOfComments];
	}
	
	if (camera.length >= 0)
	{
		cell.lengthLabel.text = [NSString stringForTimeInterval:camera.length];
	}
	
	return cell;
}

- (UITableViewCell *)getTableViewCell:(UITableView *)theTableView forCategory:(BrowseTreeNode *)category
{
	NSString * CellIdentifier = @"CategoryCell";
	
	UITableViewCell * cell = [theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) 
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
									   reuseIdentifier:CellIdentifier];
	}
	
	cell.textLabel.text  = category.title;
	cell.imageView.image = [UIImage imageNamed:@"ic_list_empty"];
	cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;
	cell.accessoryView   = nil;
	
	return cell;
}

- (BOOL)tableView:(UITableView *)theTableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
	BOOL useFilteredSource = (theTableView == self.searchDisplayController.searchResultsTableView);
	return useFilteredSource ? [self.cameraDataSource canDeleteRowAtFilteredIndexPath:indexPath]
	                         : [self.cameraDataSource canDeleteRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)theTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (editingStyle == UITableViewCellEditingStyleDelete) 
	{
		// delete the row (and possibly the section) from the data source
		BOOL useFilteredSource = (theTableView == self.searchDisplayController.searchResultsTableView);
		BOOL deleteSection     = (useFilteredSource) ? [self.cameraDataSource deleteRowAtFilteredIndexPath:indexPath]
		                                             : [self.cameraDataSource deleteRowAtIndexPath:indexPath];
		
		// delete the row or section from the table view
		if (deleteSection)
		{
			NSInteger numberOfSections = (useFilteredSource) ? self.cameraDataSource.numberOfFilteredSections
			                                                 : self.cameraDataSource.numberOfSections;
			
			if (numberOfSections == 0)
			{
				// never delete the last section of the table view, just refresh it to show the "no cameras" text
				[theTableView reloadData];
				
				if (! theTableView.editing)
				{
					self.editButtonItem.enabled = NO;
				}
			}
			else
			{
				[theTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] 
							withRowAnimation:UITableViewRowAnimationFade];
			}
		}
		else
		{
            NSInteger numberOfRows = (useFilteredSource) ? [self.cameraDataSource numberOfRowsInFilteredSection:indexPath.section]
                                                         : [self.cameraDataSource numberOfRowsInSection:indexPath.section];
            
            if (numberOfRows == 0)
            {
                // never delete the last row of the table view, just refresh it to show the "no cameras" text
                [theTableView reloadData];
                
                if (! theTableView.editing)
                {
                    self.editButtonItem.enabled = NO;
                }
            }
            else
            {
                [theTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] 
                                    withRowAnimation:UITableViewRowAnimationFade];
            }
		}
	}
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	BOOL useFilteredSource = (theTableView == self.searchDisplayController.searchResultsTableView);
    NSInteger numberOfRows = (useFilteredSource) ? [self.cameraDataSource numberOfRowsInFilteredSection:indexPath.section] 
                                                 : [self.cameraDataSource numberOfRowsInSection:indexPath.section];
    
	if ((indexPath.row > 0) && (indexPath.row == numberOfRows))
	{
		[theTableView deselectRowAtIndexPath:indexPath animated:YES];
		[self.cameraDataSource getMoreCameras];
	}
	else if (numberOfRows > 0)
	{
		id browseNode = [self getCameraOrCategoryAtIndexPath:indexPath forTableView:theTableView];
		
		if ([browseNode isKindOfClass:[CameraInfoWrapper class]])
		{
            RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
			[rootViewController showVideo:browseNode];
		}
		else 
		{
			BrowseTreeNode * browseTree = browseNode;
			BrowseViewController * viewController = 
				[[BrowseViewController alloc] initWithNibName:@"BrowseViewController" 
														bundle:nil];
			
			viewController.cameraCategory = cameraCategory;
			viewController.cameraDataSource = [[CameraCatalogDataSource alloc] initWithBrowseTree:browseTree 
																					   andDelegate:viewController];
			[self.navigationController pushViewController:viewController animated:YES];
		}
		
		[theTableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (void)tableView:(UITableView *)theTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	id browseNode = [self getCameraOrCategoryAtIndexPath:indexPath forTableView:theTableView];
	
	if ([browseNode isKindOfClass:[CameraInfoWrapper class]])
	{
		UIViewController * viewController = [cameraMapDelegate detailViewControllerForCamera:browseNode];
		[self.navigationController pushViewController:viewController animated:YES];
	}
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	// the only alert is an error when trying to load the list of cameras
	[self.tableView reloadData];
}


#pragma mark - UISearchDisplayControllerDelegate methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller 
shouldReloadTableForSearchString:(NSString *)searchString
{
    return [self.cameraDataSource filterCamerasForSearchText:searchString];
}

#ifdef RV_CAMERA_SEARCH_USES_SCOPE
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller 
shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] 
							   scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    
    return YES;
}
#endif

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    DDLogVerbose(@"BrowseViewController didBeginSearch");
	[controller.searchResultsTableView registerNib:[UINib nibWithNibName:@"CameraTableViewCell" bundle:nil]
							forCellReuseIdentifier:[CameraTableViewCell reuseIdentifier]];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    DDLogVerbose(@"BrowseViewController didEndSearch");
    [self.cameraDataSource endSearch];
}


#pragma mark - UISearchBarDelegate methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.cameraDataSource searchForText:searchBar.text];
}


#pragma mark - CameraCatalogDataSource methods

- (void)cameraListUpdatedForDataSource:(CameraDataSource *)dataSource
{
	DDLogVerbose(@"BrowseViewController cameraListUpdated");
	[self.tableView reloadData];
    [self.searchDisplayController.searchResultsTableView reloadData];
	self.editButtonItem.enabled = (dataSource.numberOfCameras > 0);
    
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        // map button is only shown on iPad
        showMapButton.enabled = [cameraMapDelegate addCameras:dataSource.cameras toMap:self.mapView];
    }
}

- (void)cameraListDidGetError:(NSError *)error
{
	DDLogWarn(@"BrowseViewController cameraListDidGetError: %@", error);
	UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could Not Get Camera List",
																			   @"Could not get camera list alert") 
													 message:[error localizedDescription] 
													delegate:self 
										   cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
										   otherButtonTitles:nil];
	[alert show];
}


#pragma mark - Private methods

- (void)refresh:(id)sender
{
	[self.cameraDataSource refresh];
}

- (id)getCameraOrCategoryAtIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)theTableView;
{
	BOOL useFilteredSource = (theTableView == self.searchDisplayController.searchResultsTableView);
	return (useFilteredSource) ? [self.cameraDataSource browseTreeNodeAtFilteredIndexPath:indexPath]
	                           : [self.cameraDataSource browseTreeNodeAtIndexPath:indexPath];
}

- (NSString *)getCategoryButtonText
{
	return (self.cameraDataSource.isShowingCategories) ? NSLocalizedString(@"List",
																		   @"Show camera list label")
	                                                   : NSLocalizedString(@"Categories",
																		   @"Show camera categories label");
}

- (void)toggleCategoryView
{
	[self.cameraDataSource toggleCategoryView];
	self.navigationItem.rightBarButtonItem.title = [self getCategoryButtonText];
}

- (void)toggleMap:(id)sender
{
	if (mapView.hidden)
	{
		CGRect newFrame = self.view.bounds;
		[UIView animateWithDuration:0.3 
						 animations:^{ self.mapView.hidden = NO; self.mapView.frame = newFrame; } 
						 completion:^(BOOL finished){}];	
	}
	else 
	{
		CGRect newFrame = self.mapView.frame;
		newFrame.origin.y = self.view.bounds.size.height;
		[UIView animateWithDuration:0.3 
						 animations:^{ self.mapView.frame = newFrame; } 
						 completion:^(BOOL finished){ self.mapView.hidden = YES; }];	
	}
}

- (void)showVideo:(CameraInfoWrapper *)camera
{
	MotionJpegMapViewController * viewController = 
		[[MotionJpegMapViewController alloc] initWithNibName:@"MotionJpegMapViewController" 
													   bundle:nil];
	viewController.camera = camera;
	[self.navigationController pushViewController:viewController animated:YES];
}

@end
