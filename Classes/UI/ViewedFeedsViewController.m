//
//  ViewedFeedsViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/1/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "ViewedFeedsViewController.h"
#import "CameraInfoWrapper.h"
#import "Device.h"
#import "UserDevice.h"
#import "ViewerInfo.h"
#import "UserMapAnnotationView.h"
#import "CameraTableViewCell.h"
#import "RootViewController.h"
#import "RealityVisionAppDelegate.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

// content height to display x viewer rows, with a maximum of 3 rows
#define CONTENT_HEIGHT_FOR_VIEWERS(x) (72 * MIN((x),3))


@implementation ViewedFeedsViewController

@synthesize userMapAnnotationView;
@synthesize delegate;
@synthesize popoverController;


#pragma mark - View lifecycle

- (void)viewDidLoad
{
	DDLogVerbose(@"ViewedFeedsViewController viewDidLoad");
    [super viewDidLoad];
    self.contentSizeForViewInPopover = CGSizeMake(320, CONTENT_HEIGHT_FOR_VIEWERS([self.userDevice.device.viewers count]));
	[self.tableView registerNib:[UINib nibWithNibName:@"CameraTableViewCell" bundle:nil]
		 forCellReuseIdentifier:[CameraTableViewCell reuseIdentifier]];
}

- (void)viewDidUnload
{
	DDLogVerbose(@"ViewedFeedsViewController viewDidUnload");
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
	DDLogVerbose(@"ViewedFeedsViewController viewWillAppear");
	[super viewWillAppear:animated];
	
	//
	// NOTE: The subtitle property for a user that is watching is based on the feeds being watched.
	//       Currently the UserDevice object fires the subtitle changed event if there are any
	//       changes that might affect the subtitle. That means we may get notified for changes that
	//       aren't actually due to changes in the viewed feeds. It also means that changes to when
	//       that event fires may require changes here.
	//
	[(UserDevice *)userMapAnnotationView.annotation addObserver:self
													 forKeyPath:@"subtitle"
														options:NSKeyValueObservingOptionNew
														context:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	DDLogVerbose(@"ViewedFeedsViewController viewWillDisappear");
	[super viewWillDisappear:animated];
	[(UserDevice *)userMapAnnotationView.annotation removeObserver:self forKeyPath:@"subtitle"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark - Properties

- (UserDevice *)userDevice
{
	return (UserDevice *)userMapAnnotationView.annotation;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.userDevice.device.viewers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString * cellIdentifier = [CameraTableViewCell reuseIdentifier];
	CameraTableViewCell * cell = (CameraTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	CameraInfoWrapper * camera = [[CameraInfoWrapper alloc] initWithViewer:[self.userDevice.device.viewers objectAtIndex:indexPath.row]];
	cell.captionLabel.text = camera.name;
	cell.descriptionLabel.text = camera.description ? camera.description : @"";
	cell.thumbnailView.image = camera.thumbnail ? camera.thumbnail : [UIImage imageNamed:@"ic_list_empty_thumbnail"];
	cell.ptzIcon.hidden = YES;
	cell.commentsIcon.hidden = YES;
	cell.locationIcon.hidden = YES;
	cell.lengthLabel.hidden = YES;
	cell.accessoryType = UITableViewCellAccessoryNone;
	
	return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray * viewedFeeds = self.userDevice.device.viewers;
	if (indexPath.row >= [viewedFeeds count])
	{
		// shouldn't happen but if it does, don't crash
		DDLogWarn(@"ViewedFeedsViewController: User selected row %d but there are only %d viewed feeds", indexPath.row, [viewedFeeds count]);
		return;
	}
	
	ViewerInfo * camera = [self.userDevice.device.viewers objectAtIndex:indexPath.row];
	[delegate showViewedVideo:camera forAnnotationView:userMapAnnotationView];
}


#pragma mark - Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"subtitle"])
	{
		if ([self.userDevice.device.viewers count] == 0)
		{
			[delegate dismissViewedFeedsView:self];
			return;
		}
		
		// update the content size to reflect the new number of viewers, if necessary
		CGFloat newHeight = CONTENT_HEIGHT_FOR_VIEWERS([self.userDevice.device.viewers count]);
		CGFloat oldHeight = self.popoverController.popoverContentSize.height;
		
		if (newHeight != self.popoverController.popoverContentSize.height)
			[self.popoverController setPopoverContentSize:CGSizeMake(320, newHeight) animated:YES];
		
        // refresh the list of viewers being displayed
        [self.tableView reloadData];
    }
}

@end
