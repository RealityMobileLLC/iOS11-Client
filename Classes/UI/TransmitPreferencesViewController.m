//
//  TransmitPreferencesViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/2/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "TransmitPreferencesViewController.h"
#import "RealityVisionAppDelegate.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation TransmitPreferencesViewController

@synthesize delegate;
@synthesize preferences;
@synthesize resolutionControl;
@synthesize compressionControl;
@synthesize bandwidthControl;
@synthesize showStatisticsSwitch;


#pragma mark - Initialization and cleanup

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self != nil)
	{
		// Restore transmit preferences from file, if it exists.
		NSString * prefsFile = [self getPrefsFilename];
		preferences = [[NSFileManager defaultManager] fileExistsAtPath:prefsFile] ?
							[NSKeyedUnarchiver unarchiveObjectWithFile:prefsFile] : 
							[[TransmitPreferences alloc] init];
	}
	return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"TransmitPreferencesViewController viewDidLoad");
    [super viewDidLoad];
}

- (void)viewDidUnload 
{
	DDLogVerbose(@"TransmitPreferencesViewController viewDidUnload");
    [super viewDidUnload];
	resolutionControl = nil;
	compressionControl = nil;
	bandwidthControl = nil;
	showStatisticsSwitch = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	DDLogVerbose(@"TransmitPreferencesViewController viewWillAppear");
	[super viewWillAppear:animated];
	self.resolutionControl.selectedSegmentIndex = preferences.cameraResolution;
	self.compressionControl.selectedSegmentIndex = preferences.jpegCompression;
	self.bandwidthControl.selectedSegmentIndex = preferences.bandwidthLimit;
	self.showStatisticsSwitch.on = preferences.showStatistics;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // force landscape orientation (ios5)
	return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationLandscapeRight;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskLandscapeRight;
}


#pragma mark - Button callbacks

- (IBAction)doneButtonPressed
{
	BOOL resolutionChanged = self.resolutionControl.selectedSegmentIndex != preferences.cameraResolution;
	BOOL compressionChanged = self.compressionControl.selectedSegmentIndex != preferences.jpegCompression;
	BOOL bandwidthChanged = self.bandwidthControl.selectedSegmentIndex != preferences.bandwidthLimit;
	BOOL showStatisticsChanged = self.showStatisticsSwitch.on != preferences.showStatistics;
	
	if (resolutionChanged || compressionChanged || bandwidthChanged || showStatisticsChanged)
	{
		preferences.cameraResolution = self.resolutionControl.selectedSegmentIndex;
		preferences.jpegCompression = self.compressionControl.selectedSegmentIndex;
		preferences.bandwidthLimit = self.bandwidthControl.selectedSegmentIndex;
		preferences.showStatistics = self.showStatisticsSwitch.on;
		[self savePreferences];
	}
    
    [self.delegate transmitPreferencesDidChangeResolution:resolutionChanged 
                                              compression:compressionChanged 
                                                bandwidth:bandwidthChanged 
                                           showStatistics:showStatisticsChanged];
}


#pragma mark - Private methods

- (NSString *)getPrefsFilename
{
	return [[RealityVisionAppDelegate documentDirectory] stringByAppendingPathComponent:@"Transmit.prefs"];	
}

- (void)savePreferences
{
	NSString *prefsFile = [self getPrefsFilename];
	if (! [NSKeyedArchiver archiveRootObject:preferences toFile:prefsFile])
	{
		DDLogError(@"Could not save transmit preferences");
	}
}

@end
