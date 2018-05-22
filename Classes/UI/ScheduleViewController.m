//
//  ScheduleViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ScheduleViewController.h"
#import "Schedule.h"
#import "ScheduleDaysAndTimeViewController.h"
#import "SwitchTableViewCell.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


// table view section number constants
enum 
{
	kScheduleEnabledSection,
	kScheduleDateAndTimeSection
};

// table view row number constants for kScheduleDateAndTimeSection section
enum
{
	kScheduleSignOnTimeRow,
	kScheduleSignOffTimeRow
};


@implementation ScheduleViewController
{
    UISwitch * enabledSwitch;
}

@synthesize schedule;
@synthesize scheduleDelegate;


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"ScheduleViewController viewDidLoad");
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Sign On/Off Schedule", @"Sign On/Off Schedule");
	self.contentSizeForViewInPopover = CGSizeMake(320, 310);
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
        // set view color to match color of iPad OptionsMenuPopoverController
		UIView * backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 310)];
		backgroundView.backgroundColor = [UIColor lightGrayColor];
		self.tableView.backgroundView = backgroundView;
	}
	
	self.navigationItem.rightBarButtonItem = 
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
													   target:self 
													   action:@selector(save)];
    
	enabledSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0,0,0,0)];
	enabledSwitch.on = self.schedule.enabled;
	[enabledSwitch addTarget:self action:@selector(toggleEnabled:) forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidUnload 
{
	DDLogVerbose(@"ScheduleViewController viewDidUnload");
    [super viewDidUnload];
	enabledSwitch = nil;
}

- (void)viewWillAppear:(BOOL)animated 
{
	DDLogVerbose(@"ScheduleViewController viewWillAppear");
    [super viewWillAppear:animated];
	[self.tableView reloadData];
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
    return self.schedule.enabled ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return (section == kScheduleEnabledSection) ? 1 : 2;
}

- (UITableViewCell *)tableViewCellWithSwitch
{
	static NSString * CellIdentifier = @"SwitchCell";
	
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
									   reuseIdentifier:CellIdentifier];
    }
    
	cell.textLabel.text = NSLocalizedString(@"Enable",@"Enable auto sign on label");
	cell.accessoryView = enabledSwitch;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	return cell;
}

- (UITableViewCell *)tableViewCellWithText:(NSString *)text forDays:(DaysOfWeek)days andTime:(NSDate *)date
{
	static NSString * CellIdentifier = @"Cell";
	
    UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
									   reuseIdentifier:CellIdentifier];
    }
    
	cell.textLabel.text = text;
	
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	NSString * timeString = [dateFormatter stringFromDate:date];
	NSString * daysString = [Schedule stringForScheduledDaysOfWeek:days];
	
	cell.detailTextLabel.text = (days == DaysNone) ? daysString
												   : [NSString stringWithFormat:@"%@ @ %@",daysString,timeString];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	UITableViewCell * cell = nil;
	
	if (indexPath.section == kScheduleEnabledSection)
	{
		cell = [self tableViewCellWithSwitch];
	}
	else if (indexPath.row == kScheduleSignOnTimeRow)
	{
		cell = [self tableViewCellWithText:NSLocalizedString(@"Sign on",@"Scheduled sign on button") 
								   forDays:self.schedule.signOnDays 
								   andTime:[[NSCalendar currentCalendar] dateFromComponents:self.schedule.signOnTime]];
	}
	else
	{
		cell = [self tableViewCellWithText:NSLocalizedString(@"Sign off",@"Scheduled sign off button") 
								   forDays:self.schedule.signOffDays 
								   andTime:[[NSCalendar currentCalendar] dateFromComponents:self.schedule.signOffTime]];
	}
	
    return cell;
}


#pragma mark - Table view delegate

- (ScheduleDaysAndTimeViewController *)daysAndTimeViewControllerForSignOnTime:(BOOL)signOnTime
																	   onDays:(DaysOfWeek)days 
																	  andTime:(NSDateComponents *)time 
{
	ScheduleDaysAndTimeViewController * viewController = 
		[[ScheduleDaysAndTimeViewController alloc] initWithNibName:@"ScheduleDaysAndTimeViewController" 
															 bundle:nil];
	
	viewController.delegate = self;
	viewController.getSignOnTime = signOnTime;
	viewController.daysOfWeek = days;
	viewController.time = [[NSCalendar currentCalendar] dateFromComponents:time];
	
	return viewController;
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	ScheduleDaysAndTimeViewController * viewController = nil;
	
	if (indexPath.section == kScheduleEnabledSection)
	{
		return;
	}
	
	if (indexPath.row == kScheduleSignOnTimeRow)
	{
		viewController = [self daysAndTimeViewControllerForSignOnTime:YES
															   onDays:self.schedule.signOnDays
															  andTime:self.schedule.signOnTime];
	}
	else
	{
		viewController = [self daysAndTimeViewControllerForSignOnTime:NO
															   onDays:self.schedule.signOffDays
															  andTime:self.schedule.signOffTime];
	}
	
	[self.navigationController pushViewController:viewController animated:YES];
	[theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)setSignOnDays:(DaysOfWeek)daysOfWeek andTime:(NSDate *)time
{
	[self.schedule setSignOnDays:daysOfWeek andTime:time];
}

- (void)setSignOffDays:(DaysOfWeek)daysOfWeek andTime:(NSDate *)time
{
	[self.schedule setSignOffDays:daysOfWeek andTime:time];
}


#pragma mark - User interface callbacks

- (void)toggleEnabled:(id)sender
{
	self.schedule.enabled = enabledSwitch.on;
	
	[self.tableView beginUpdates];

	if (self.schedule.enabled)
	{
		[self.tableView insertSections:[NSIndexSet indexSetWithIndex:kScheduleDateAndTimeSection] 
		              withRowAnimation:UITableViewRowAnimationFade];
	}
	else 
	{
		[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:kScheduleDateAndTimeSection] 
		              withRowAnimation:UITableViewRowAnimationFade];
	}

	[self.tableView endUpdates];
}

- (IBAction)save
{
	[scheduleDelegate scheduleChanged:self.schedule];
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end

