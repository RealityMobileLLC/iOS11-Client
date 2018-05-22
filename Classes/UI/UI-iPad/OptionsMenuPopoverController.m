//
//  OptionsMenuPopoverController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 12/7/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "OptionsMenuPopoverController.h"
#import "RootViewController.h"
#import "ScheduleViewController.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"
#import "ScheduleManager.h"


@implementation OptionsMenuPopoverController
{
	UIViewController * optionsMenuViewController;
}

@synthesize popoverController;
@synthesize aboutView;
@synthesize locationView;
@synthesize aboutButton;
@synthesize locationButton;
@synthesize scheduleButton;
@synthesize productLabel;
@synthesize versionLabel;
@synthesize copyrightLabel;
@synthesize supportUrlLabel;
@synthesize userLabel;
@synthesize deviceIdLabel;
@synthesize locationSwitch;
@synthesize locationAccuracyControl;
@synthesize locationAccuracyDelegate;
@synthesize mapTypeControl;


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
    [super viewDidLoad];
	self.contentSizeForViewInPopover = self.view.bounds.size;
	
	NSString * versionString = [RealityVisionAppDelegate infoValueForKey:@"RVAboutVersion"];
	if (NSStringIsNilOrEmpty(versionString))
	{
		versionString = [NSString stringWithFormat:@"%@ (internal)", [RealityVisionAppDelegate infoValueForKey:@"CFBundleShortVersionString"]];
	}
	
	self.productLabel.text = [NSString stringWithFormat:@"%@ for iPhone", [RealityVisionAppDelegate appName]];
    self.versionLabel.text = [NSString stringWithFormat:@"Version: %@", versionString];
    self.copyrightLabel.text = [RealityVisionAppDelegate infoValueForKey:@"NSHumanReadableCopyright"];
	self.supportUrlLabel.text = [RealityVisionAppDelegate infoValueForKey:@"RVSupportURL"];
	self.deviceIdLabel.text = [RealityVisionClient instance].deviceId;
	self.userLabel.text = [NSString stringWithFormat:@"User: %@", [RealityVisionClient instance].userId];
}


- (void)viewDidUnload 
{
	[super viewDidUnload];
	aboutView = nil;
	locationView = nil;
	aboutButton = nil;
	locationButton = nil;
	scheduleButton = nil;
	productLabel = nil;
	versionLabel = nil;
	copyrightLabel = nil;
	supportUrlLabel = nil;
	userLabel = nil;
	deviceIdLabel = nil;
	locationSwitch = nil;
	locationAccuracyControl = nil;
	mapTypeControl = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	self.locationSwitch.on = self.locationAccuracyDelegate.isLocationAware;
	self.locationAccuracyControl.selectedSegmentIndex = (NSInteger)self.locationAccuracyDelegate.locationAccuracy;
	self.locationButton.enabled = [RealityVisionClient instance].isSignedOn;
	self.scheduleButton.enabled = [RealityVisionClient instance].isSignedOn;
	
    [[RealityVisionClient instance] addObserver:self
                                     forKeyPath:@"locationOn"
                                        options:NSKeyValueObservingOptionNew
                                        context:NULL];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[[RealityVisionClient instance] removeObserver:self forKeyPath:@"locationOn"];
}


#pragma mark - IBAction methods

- (IBAction)didChangeLocationSwitch
{
	locationAccuracyDelegate.isLocationAware = locationSwitch.on;
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)didChangeLocationAccuracy
{
	NSInteger selectedAccuracy = locationAccuracyControl.selectedSegmentIndex;
	
	if (selectedAccuracy >= 0)
	{
		locationAccuracyDelegate.locationAccuracy = (RVLocationAccuracy)selectedAccuracy;
	}
}

- (IBAction)didChangeMapType
{
	NSInteger selectedMap = mapTypeControl.selectedSegmentIndex;
	
	if (selectedMap == 0)
	{
		locationAccuracyDelegate.mapType = MKMapTypeStandard;
	}
	else if (selectedMap == 1)
	{
		locationAccuracyDelegate.mapType = MKMapTypeSatellite;
	}
	else if (selectedMap == 2)
	{
		locationAccuracyDelegate.mapType = MKMapTypeHybrid;
	}
	
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)showAboutDialog:(id)sender
{
	self.aboutView.hidden = NO;
	self.locationView.hidden = YES;
	
	self.aboutButton.selected = YES;
	self.locationButton.selected = NO;
	self.scheduleButton.selected = NO;
}

- (IBAction)showLocationSettings:(id)sender
{
	self.aboutView.hidden = YES;
	self.locationView.hidden = NO;
	
	self.aboutButton.selected = NO;
	self.locationButton.selected = YES;
	self.scheduleButton.selected = NO;
}

- (IBAction)showSchedule:(id)sender
{
	// save off current popover content view controller before changing it
	optionsMenuViewController = self.popoverController.contentViewController;
	
	ScheduleManager * scheduleManager = [ScheduleManager instance];
	
	ScheduleViewController * viewController = [[ScheduleViewController alloc] initWithNibName:@"ScheduleViewController" 
																					   bundle:nil];
	viewController.scheduleDelegate = self;
	viewController.schedule = scheduleManager.schedule;
	
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	[self.popoverController setContentViewController:navigationController animated:YES];
	
}


#pragma mark - ScheduleDelegate

- (void)scheduleChanged:(Schedule *)newSchedule
{
	[[ScheduleManager instance] scheduleChanged:newSchedule];
	[self.popoverController setContentViewController:optionsMenuViewController animated:YES];
	optionsMenuViewController = nil;
}


#pragma mark - Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	self.locationSwitch.on = self.locationAccuracyDelegate.isLocationAware;
}

@end
