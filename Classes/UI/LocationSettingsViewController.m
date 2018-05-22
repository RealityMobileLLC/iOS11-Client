//
//  LocationSettingsViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/12/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "LocationSettingsViewController.h"
#import "RealityVisionClient.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation LocationSettingsViewController
{
	NSInteger            locationEnabledSection;
	NSInteger            locationAccuracySection;
	NSInteger            mapSection;
	
    UISwitch           * locationSwitch;
	UISegmentedControl * locationAccuracyControl;
	UISegmentedControl * mapTypeControl;
	
	UITableViewCell    * locationSwitchTableViewCell;
	UITableViewCell    * locationAccuracyTableViewCell;
	UITableViewCell    * mapTypeTableViewCell;
}

@synthesize locationAccuracyDelegate;


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"LocationSettingsViewController viewDidLoad");
    [super viewDidLoad];
	self.title = NSLocalizedString(@"Location Settings",@"Location Settings");
	self.navigationItem.rightBarButtonItem = 
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
													  target:self 
													  action:@selector(done)];
}

- (void)viewDidUnload 
{
	DDLogVerbose(@"LocationSettingsViewController viewDidUnload");
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated 
{
	DDLogVerbose(@"LocationSettingsViewController viewWillAppear");
    [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	DDLogVerbose(@"LocationSettingsViewController viewDidDisappear");
	[super viewDidDisappear:animated];
	
	// remove references to controls when view disappears
	locationSwitch = nil;
	locationAccuracyControl = nil;
	mapTypeControl = nil;
	locationSwitchTableViewCell = nil;
	locationAccuracyTableViewCell = nil;
	mapTypeTableViewCell = nil;
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
	// set section numbers here since this will always be called before getting section and cell info
	NSInteger nextSectionNumber = 0;
	locationEnabledSection = nextSectionNumber++;
	locationAccuracySection = locationAccuracyDelegate.isLocationAware ? nextSectionNumber++ : -1;
	mapSection = nextSectionNumber++;
    return nextSectionNumber;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return (section == locationAccuracySection) ? NSLocalizedString(@"Accuracy",@"Location accuracy label") :
	       (section == mapSection)              ? NSLocalizedString(@"Map Type",@"Map type label")
												: nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath.section == locationEnabledSection ? 44 : 30;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == locationAccuracySection)
	{
		locationAccuracyControl.frame = cell.contentView.bounds;
	}
	else if (indexPath.section == mapSection)
	{
		mapTypeControl.frame = cell.contentView.bounds;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	NSInteger section = indexPath.section;
	return (section == locationEnabledSection)  ? [self locationSwitchTableViewCell] : 
	       (section == locationAccuracySection) ? [self locationAccuracyTableViewCell] :
	       (section == mapSection)              ? [self mapTypeTableViewCell]
												: nil;
}

- (UITableViewCell *)locationSwitchTableViewCell
{
	if (locationSwitchTableViewCell == nil)
	{
		// create location enabled switch
		locationSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0,0,0,0)];
		[locationSwitch addTarget:self 
						   action:@selector(toggleLocationAware) 
				 forControlEvents:UIControlEventValueChanged];
		
		// enable location settings only if user has authorized location services and is signed on
		CLAuthorizationStatus authorized = [CLLocationManager authorizationStatus];
		locationSwitch.enabled = [RealityVisionClient instance].isSignedOn &&
		                         [CLLocationManager locationServicesEnabled] && 
		                         ((authorized == kCLAuthorizationStatusAuthorized) || 
								  (authorized == kCLAuthorizationStatusNotDetermined));
		locationSwitch.on = locationAccuracyDelegate.isLocationAware;
		
		// create table view cell
        locationSwitchTableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
															 reuseIdentifier:nil];
		locationSwitchTableViewCell.textLabel.text = NSLocalizedString(@"Location",@"Enable location services label");
		locationSwitchTableViewCell.accessoryView = locationSwitch;
		locationSwitchTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	return locationSwitchTableViewCell;
}

- (UITableViewCell *)locationAccuracyTableViewCell
{
	if (locationAccuracyTableViewCell == nil)
	{
		// create location accuracy control
		NSArray * accuracyLabels = [NSArray arrayWithObjects:NSLocalizedString(@"3 km",  @"Location accuracy 3 km"),
									                         NSLocalizedString(@"100 m", @"Location accuracy 100 m"), 
									                         NSLocalizedString(@"20 m",  @"Location accuracy 20 m"), nil];
		
		locationAccuracyControl = [[UISegmentedControl alloc] initWithItems:accuracyLabels];
		[locationAccuracyControl addTarget:self
									action:@selector(changeLocationAccuracy)
						  forControlEvents:UIControlEventValueChanged];
		
		//locationAccuracyControl.segmentedControlStyle = UISegmentedControlStyleBar;
		locationAccuracyControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		locationAccuracyControl.selectedSegmentIndex = (NSInteger)locationAccuracyDelegate.locationAccuracy;
		
		// create table view cell
        locationAccuracyTableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
															 reuseIdentifier:nil];
		[locationAccuracyTableViewCell.contentView addSubview:locationAccuracyControl];
		locationAccuracyTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	return locationAccuracyTableViewCell;
}

- (UITableViewCell *)mapTypeTableViewCell
{
	if (mapTypeTableViewCell == nil)
	{
		// create location accuracy control
		NSArray * mapTypeLabels = [NSArray arrayWithObjects:NSLocalizedString(@"Map",       @"Default map type"),
									                        NSLocalizedString(@"Satellite", @"Satellite map type"), 
									                        NSLocalizedString(@"Hybrid",    @"Hybrid map type"), nil];
		
		mapTypeControl = [[UISegmentedControl alloc] initWithItems:mapTypeLabels];
		[mapTypeControl addTarget:self
						   action:@selector(changeMapType)
				 forControlEvents:UIControlEventValueChanged];		
		
		//mapTypeControl.segmentedControlStyle = UISegmentedControlStyleBar;
		mapTypeControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		mapTypeControl.selectedSegmentIndex = (NSInteger)locationAccuracyDelegate.mapType;
		
		// create table view cell
        mapTypeTableViewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
													  reuseIdentifier:nil];
		[mapTypeTableViewCell.contentView addSubview:mapTypeControl];
		mapTypeTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	return mapTypeTableViewCell;
}


#pragma mark - Button actions

- (IBAction)toggleLocationAware
{
	locationAccuracyDelegate.isLocationAware = locationSwitch.on;
	
	[self.tableView beginUpdates];
	
	if (locationAccuracyDelegate.isLocationAware)
	{
		locationAccuracySection = locationEnabledSection + 1;
		mapSection++;
		[self.tableView insertSections:[NSIndexSet indexSetWithIndex:locationAccuracySection] 
		              withRowAnimation:UITableViewRowAnimationFade];
	}
	else 
	{
		[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:locationAccuracySection] 
		              withRowAnimation:UITableViewRowAnimationFade];
		locationAccuracySection = -1;
		mapSection--;
	}
	
	[self.tableView endUpdates];
}


- (IBAction)changeLocationAccuracy
{
	NSInteger selectedAccuracy = locationAccuracyControl.selectedSegmentIndex;
	
	if (selectedAccuracy >= 0)
	{
		locationAccuracyDelegate.locationAccuracy = (RVLocationAccuracy)selectedAccuracy;
	}
}

- (IBAction)changeMapType
{
	NSInteger selectedMap = mapTypeControl.selectedSegmentIndex;
	locationAccuracyDelegate.mapType = (selectedMap == 0) ? MKMapTypeStandard :
	                                   (selectedMap == 1) ? MKMapTypeSatellite :
	                                   (selectedMap == 2) ? MKMapTypeHybrid : MKMapTypeStandard;
}

- (IBAction)done
{
    // @todo notify presenter (delegate) and have it dismiss rather than dismiss ourselves
	[self dismissViewControllerAnimated:YES completion:NULL];
}


@end
