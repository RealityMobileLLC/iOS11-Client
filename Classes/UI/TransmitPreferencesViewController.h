//
//  TransmitPreferencesViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/2/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TransmitPreferences.h"


/**
 *  Protocol used to indicate the user has changed one or more of the transmit
 *  preferences.
 */
@protocol TransmitPreferencesDelegate

/**
 *  Called when the transmit preferences have been changed by the user.  This
 *  is only called if one or more of the values have changed.
 */
- (void)transmitPreferencesDidChangeResolution:(BOOL)resolutionChanged 
								   compression:(BOOL)compressionChanged 
									 bandwidth:(BOOL)bandwidthChanged 
								showStatistics:(BOOL)showStatisticsChanged;

@end


/**
 *  View Controller responsible for getting transmit preferences from the user.
 */
@interface TransmitPreferencesViewController : UIViewController 

/**
 *  The delegate to notify when preferences change.
 */
@property (nonatomic,weak) id <TransmitPreferencesDelegate> delegate;

/**
 *  Current preferences.
 */
@property (strong, nonatomic,readonly) TransmitPreferences * preferences;


// Interface builder outlets
@property (weak, nonatomic) IBOutlet UISegmentedControl * resolutionControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl * compressionControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl * bandwidthControl;
@property (weak, nonatomic) IBOutlet UISwitch           * showStatisticsSwitch;

- (IBAction)doneButtonPressed;

@end
