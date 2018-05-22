//
//  ScheduleDaysAndTimeViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/12/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Schedule.h"

@class SelectDaysOfWeekViewController;


/**
 *  Delegate used by the ScheduleDaysAndTimeViewController to indicate
 *  that the user has selected new sign on or off days and time.
 */
@protocol ScheduleDaysAndTimeDelegate

- (void)setSignOnDays:(DaysOfWeek)daysOfWeek andTime:(NSDate *)time;

- (void)setSignOffDays:(DaysOfWeek)daysOfWeek andTime:(NSDate *)time;

@end


/**
 *  View Controller used to get either the sign on or the sign off schedule.
 *  The only difference between the two is which ScheduleDaysAndTimeDelegate 
 *  method is called.
 *  
 *  Note that the delegate, getSignOnTime, daysOfWeek, and time properties
 *  must all be set by the caller before loading this view controller.
 */
@interface ScheduleDaysAndTimeViewController : UIViewController

/**
 *  Delegate to notify when the user is done changing the schedule.
 */
@property (nonatomic,weak) id <ScheduleDaysAndTimeDelegate> delegate;

/**
 *  Indicates whether the view controller is being used to get the sign on
 *  schedule or the sign off schedule.  If YES, the view controller will
 *  call the setSignOnDays:andTime: delegate method when done.  If NO, the
 *  view controller will instead call the setSignOffDays:andTime: delegate 
 *  method.
 */
@property (nonatomic) BOOL getSignOnTime;

/**
 *  The days of the week the user wishes to automatically sign on or off.
 */
@property (nonatomic) DaysOfWeek daysOfWeek;

/**
 *  The time of day the user wishes to automatically sign on or off.
 */
@property (strong, nonatomic) NSDate * time;


// Interface Builder outlets
@property (weak, nonatomic) IBOutlet UIDatePicker * timePicker;
@property (weak, nonatomic) IBOutlet UITableView  * tableView;

@end
