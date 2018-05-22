//
//  ScheduleViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScheduleDaysAndTimeViewController.h"

@class Schedule;


/**
 *  Delegate used by the ScheduleViewController to indicate when the 
 *  user has changed their auto sign on/off schedule.
 */
@protocol ScheduleDelegate

/** 
 *  Called when the sign on/off schedule has changed.
 *  
 *  @param schedule The new schedule saved by the user.
 */
- (void)scheduleChanged:(Schedule *)schedule;

@end


/**
 *  View Controller used to allow the user to select automatic sign on and 
 *  sign off times.
 */
@interface ScheduleViewController : UITableViewController <ScheduleDaysAndTimeDelegate>

/**
 *  The currently defined schedule.  This must be set before the view 
 *  controller is loaded.
 */
@property (nonatomic,copy) Schedule * schedule;

/**
 *  The delegate to notify when the schedule has changed.
 */
@property (nonatomic,weak) id <ScheduleDelegate> scheduleDelegate;


// Interface Builder outlets
- (IBAction)save;

@end
