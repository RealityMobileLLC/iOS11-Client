//
//  MapFilterViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "MapFilterViewController.h"
#import "MenuItem.h"
#import "MainMapViewController.h"
#import "VideoSourcesFilterViewController.h"
#import "RealityVisionAppDelegate.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


enum
{
    USERS_MENU_ITEM,
    VIDEO_SOURCES_MENU_ITEM
};


@implementation MapFilterViewController
{
	NSArray * menuItems;
}

@synthesize mapViewController;
@synthesize popoverController;


#pragma mark - Initialization and cleanup

- (void)createMenuItems
{
    MenuItem * users = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Users",
																		 @"Users map filter menu label") 
												 image:nil];
    users.tag = USERS_MENU_ITEM;
	
    MenuItem * videoSources = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Video Sources",
																				@"Video Sources map filter menu label") 
														image:nil];
    videoSources.tag = VIDEO_SOURCES_MENU_ITEM;
	
	menuItems = [NSArray arrayWithObjects:users, videoSources, nil];
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"MapFilterViewController viewDidLoad");
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Filter",@"Filter title");
    [self createMenuItems];
 	
	// @todo this really should be set by the MainMapViewController itself
	RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
	self.mapViewController = (MainMapViewController *)appDelegate.rootViewController;
}


- (void)viewDidUnload 
{
	DDLogVerbose(@"MapFilterViewController viewDidUnload");
    [super viewDidUnload];
    menuItems = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    [self.popoverController setPopoverContentSize:[self contentSizeForViewInPopover] animated:animated];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
									   reuseIdentifier:CellIdentifier];
    }
    
    MenuItem * item = [menuItems objectAtIndex:indexPath.row];
    cell.textLabel.text = item.label;
    
    if (item.tag == USERS_MENU_ITEM)
    {
        if (self.mapViewController.showUsers)
        {
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else
        {
            // setting the accessoryType to None causes the detail text to extend, 
			// so we'll replace the accessoryView with an empty frame
            cell.accessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        }
    }
    else if (item.tag == VIDEO_SOURCES_MENU_ITEM)
    {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        DDLogWarn(@"MapFilterViewController cellForRowAtIndexPath: invalid menu item");
    }
	
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    MenuItem * item = [menuItems objectAtIndex:indexPath.row];
    
    if (item.tag == USERS_MENU_ITEM)
    {
        self.mapViewController.showUsers = ! self.mapViewController.showUsers;
        [self.tableView reloadData];
    }
    else if (item.tag == VIDEO_SOURCES_MENU_ITEM)
    {
        VideoSourcesFilterViewController * viewController = 
            [[VideoSourcesFilterViewController alloc] initWithNibName:@"MapFilterViewController" 
                                                                bundle:nil];
        [self.navigationController pushViewController:viewController animated:YES];
		[theTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else
    {
        DDLogWarn(@"MapFilterViewController didSelectRowAtIndexPath: invalid menu item");
    }
}

@end
