//
//  LocationSettingsViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/12/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RVLocationAccuracyDelegate.h"


@interface LocationSettingsViewController : UITableViewController

/**
 *  Delegate to notify when the user changes the location accuracy setting.
 */
@property (nonatomic,weak) id <RVLocationAccuracyDelegate> locationAccuracyDelegate;

@end
