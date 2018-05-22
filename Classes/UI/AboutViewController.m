//
//  AboutViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/10/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "AboutViewController.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"


@implementation AboutViewController

@synthesize productLabel;
@synthesize deviceIdLabel;
@synthesize productLogoView;
@synthesize supportUrlLabel;
@synthesize userLabel;
@synthesize copyrightLabel;
@synthesize versionLabel;


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
    [super viewDidLoad];
	self.productLabel.text     = [NSString stringWithFormat:@"%@ for iPhone", [RealityVisionAppDelegate appName]];
    self.versionLabel.text     = [NSString stringWithFormat:@"Version: %@", [RealityVisionAppDelegate versionString]];
    self.copyrightLabel.text   = [RealityVisionAppDelegate infoValueForKey:@"NSHumanReadableCopyright"];
	self.supportUrlLabel.text  = [RealityVisionAppDelegate infoValueForKey:@"RVSupportURL"];
	self.deviceIdLabel.text    = [RealityVisionClient instance].deviceId;
	self.userLabel.text        = [NSString stringWithFormat:@"User: %@", [RealityVisionClient instance].userId];
	self.productLogoView.image = [UIImage imageNamed:[RealityVisionAppDelegate infoValueForKey:@"RVAboutLogo"]];
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    self.productLabel = nil;
    self.versionLabel = nil;
    self.copyrightLabel = nil;
    self.supportUrlLabel = nil;
    self.userLabel = nil;
    self.deviceIdLabel = nil;
    self.productLogoView = nil;
}

- (BOOL)shouldAutorotate
{
	return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
	return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
	return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - IBAction methods

- (IBAction)dismissAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
