//
//  SelectDaysOfWeekViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Schedule.h"


/**
 *  View Controller used to select one or more days of the week.
 */
@interface SelectDaysOfWeekViewController : UITableViewController 

/**
 *  The currently selected days of the week.
 */
@property (nonatomic) DaysOfWeek selectedDays;

/**
 *  Indicates whether to allow the user must select at least one day.
 *  Defaults to NO, meaning the user can choose to not select any days.
 */
@property (nonatomic) BOOL requireOneOrMoreDays;

@end
