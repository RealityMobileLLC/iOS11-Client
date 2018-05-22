//
//  OptionsMenuPopoverController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 12/7/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RVLocationAccuracyDelegate.h"
#import "ScheduleViewController.h"


/**
 *  View Controller used to display the RealityVision Options menu in a popover.
 */
@interface OptionsMenuPopoverController : UIViewController <ScheduleDelegate>

/**
 *  Popover controller responsible for presenting the OptionsMenuPopoverController.
 */
@property (weak, nonatomic) UIPopoverController * popoverController;

/**
 *  Delegate to notify when the user changes the location accuracy setting.
 */
@property (weak, nonatomic) id <RVLocationAccuracyDelegate> locationAccuracyDelegate;


// Interface Builder outlets
@property (weak, nonatomic) IBOutlet UIView * aboutView;
@property (weak, nonatomic) IBOutlet UIView * locationView;
//@property (nonatomic,retain) IBOutlet UIView * scheduleView;

@property (weak, nonatomic) IBOutlet UIButton * aboutButton;
@property (weak, nonatomic) IBOutlet UIButton * locationButton;
@property (weak, nonatomic) IBOutlet UIButton * scheduleButton;

@property (weak, nonatomic) IBOutlet UILabel * productLabel;
@property (weak, nonatomic) IBOutlet UILabel * versionLabel;
@property (weak, nonatomic) IBOutlet UILabel * copyrightLabel;
@property (weak, nonatomic) IBOutlet UILabel * supportUrlLabel;
@property (weak, nonatomic) IBOutlet UILabel * userLabel;
@property (weak, nonatomic) IBOutlet UILabel * deviceIdLabel;

@property (weak, nonatomic) IBOutlet UISwitch           * locationSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl * locationAccuracyControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl * mapTypeControl;

- (IBAction)didChangeLocationSwitch;
- (IBAction)didChangeLocationAccuracy;
- (IBAction)didChangeMapType;
- (IBAction)showAboutDialog:(id)sender;
- (IBAction)showLocationSettings:(id)sender;
- (IBAction)showSchedule:(id)sender;

@end
