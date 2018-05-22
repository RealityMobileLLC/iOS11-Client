//
//  ScheduleDaysAndTimeViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/12/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ScheduleDaysAndTimeViewController.h"
#import "SelectDaysOfWeekViewController.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation ScheduleDaysAndTimeViewController
{
	SelectDaysOfWeekViewController * daysOfWeekViewController;
}

@synthesize delegate;
@synthesize getSignOnTime;
@synthesize time;
@synthesize timePicker;
@synthesize tableView;


#pragma mark - Initialization and cleanup

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle
{
	self = [super initWithNibName:nibName bundle:bundle];
	if (self != nil)
	{
		daysOfWeekViewController = [[SelectDaysOfWeekViewController alloc] initWithNibName:@"SelectDaysOfWeekViewController" 
																					bundle:nil];
		if (daysOfWeekViewController == nil)
		{
			self = nil;
		}
	}
	return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"ScheduleDaysAndTimeViewController viewDidLoad");
	[super viewDidLoad];
	[self.timePicker setDate:self.time animated:NO];
	self.title = (getSignOnTime) ? NSLocalizedString(@"Sign On Time",@"Sign On Time title")	
	                             : NSLocalizedString(@"Sign Off Time",@"Sign Off Time title");
	self.contentSizeForViewInPopover = CGSizeMake(320, 310);
}


- (void)viewDidUnload 
{
	DDLogVerbose(@"ScheduleDaysAndTimeViewController viewDidUnload");
    [super viewDidUnload];
	timePicker = nil;
	tableView = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
	DDLogVerbose(@"ScheduleDaysAndTimeViewController viewWillAppear");
	[super viewWillAppear:animated];
	[self.tableView reloadData];
}


- (void)viewWillDisappear:(BOOL)animated
{
	DDLogVerbose(@"ScheduleDaysAndTimeViewController viewWillDisappear");
	if (getSignOnTime)
	{
		[delegate setSignOnDays:self.daysOfWeek andTime:self.timePicker.date];
	}
	else
	{
		[delegate setSignOffDays:self.daysOfWeek andTime:self.timePicker.date];
	}
}


#pragma mark - Properties

- (DaysOfWeek)daysOfWeek
{
	return daysOfWeekViewController.selectedDays;
}


- (void)setDaysOfWeek:(DaysOfWeek)days
{
	daysOfWeekViewController.selectedDays = days;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    return 1;
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
	
	cell.textLabel.text = NSLocalizedString(@"Repeat",@"Scheduled repeat days button");
	cell.detailTextLabel.text = [Schedule stringForScheduledDaysOfWeek:self.daysOfWeek];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[self.navigationController pushViewController:daysOfWeekViewController animated:YES];
}

@end
