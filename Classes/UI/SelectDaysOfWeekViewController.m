//
//  SelectDaysOfWeekViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "SelectDaysOfWeekViewController.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


static DaysOfWeek menuItems[] =
{
	DaysMonday,
	DaysTuesday,
	DaysWednesday,
	DaysThursday,
	DaysFriday,
	DaysSaturday,
	DaysSunday
};


@implementation SelectDaysOfWeekViewController

@synthesize selectedDays;
@synthesize requireOneOrMoreDays;


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"SelectDaysOfWeekViewController viewDidLoad");
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Select Days",@"Select Days");
	self.contentSizeForViewInPopover = CGSizeMake(320, 310);
}


- (void)viewDidUnload 
{
	DDLogVerbose(@"SelectDaysOfWeekViewController viewDidUnload");
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return 7;
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
    
	DaysOfWeek day = menuItems[indexPath.row];
	cell.textLabel.text = [Schedule stringForDayOfWeek:day];
	cell.accessoryType = (day & selectedDays) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	selectedDays ^= menuItems[indexPath.row];
	
	if ((requireOneOrMoreDays) && (selectedDays == DaysNone))
	{
		selectedDays = menuItems[indexPath.row];
		UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Days Selected",@"No days selected alert text") 
														  message:NSLocalizedString(@"At least one sign off day must be selected.",@"At least one sign off day must be selected alert text") 
														 delegate:nil 
												cancelButtonTitle:NSLocalizedString(@"OK",@"OK") 
												otherButtonTitles:nil];
		[alert show];
	}
	
	[theTableView reloadData];
}

@end

