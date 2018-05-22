//
//  CameraDetailViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/17/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "CameraDetailViewController.h"
#import "DetailDataSource.h"
#import "CommentTableViewCell.h"
#import "CameraStatusTableViewCell.h"
#import "ThumbnailTableViewCell.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CameraDetailViewController

@synthesize detailDataSource;


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"CameraDetailViewController viewDidLoad");
    [super viewDidLoad];
	self.title = detailDataSource.title;
	
	[self.tableView registerNib:[UINib nibWithNibName:@"CommentTableViewCell" bundle:nil]
		 forCellReuseIdentifier:[CommentTableViewCell reuseIdentifier]];
	
	[self.tableView registerNib:[UINib nibWithNibName:@"CameraStatusTableViewCell" bundle:nil]
		 forCellReuseIdentifier:[CameraStatusTableViewCell reuseIdentifier]];
	
	[self.tableView registerNib:[UINib nibWithNibName:@"ThumbnailTableViewCell" bundle:nil]
		 forCellReuseIdentifier:[ThumbnailTableViewCell reuseIdentifier]];
}

- (void)viewWillAppear:(BOOL)animated
{
	DDLogVerbose(@"CameraDetailViewController viewWillAppear");
	[super viewWillAppear:animated];
	[FavoritesManager updateAndAddObserver:detailDataSource];
}

- (void)viewDidAppear:(BOOL)animated
{
	DDLogVerbose(@"CameraDetailViewController viewDidAppear");
	[super viewDidAppear:animated];
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	DDLogVerbose(@"CameraDetailViewController viewWillDisappear");
	[super viewWillDisappear:animated];
	[FavoritesManager removeObserver:detailDataSource];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark - Properties

- (DetailDataSource *)detailDataSource
{
	return detailDataSource;
}

- (void)setDetailDataSource:(DetailDataSource *)theDataSource
{
	detailDataSource = theDataSource;
	self.tableView.dataSource = detailDataSource;
	self.tableView.delegate = detailDataSource;
}

@end

