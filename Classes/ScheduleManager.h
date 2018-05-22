//
//  ScheduleManager.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/15/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ScheduleViewController.h"

@class Schedule;


/**
 *  Maintains the user's auto sign-on/off schedule.
 */
@interface ScheduleManager : NSObject <ScheduleDelegate>

/**
 *  Currently defined schedule for the device.
 */
@property (strong, nonatomic,readonly) Schedule * schedule;

/**
 *  Gets singleton instance of ScheduleManager.
 */
+ (id)instance;

@end
