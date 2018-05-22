//
//  ScheduleManager.m
//  RealityVision
//
//  Created by Thomas ti on 11/15/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ScheduleManager.h"
#import "ScheduleDaysAndTimeViewController.h"
#import "MainMenuViewController.h"
#import "RealityVisionAppDelegate.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation ScheduleManager

@synthesize schedule;


#pragma mark - Initialization and cleanup

static ScheduleManager * instance;

+ (id)instance
{
	if (instance == nil)
	{
		instance = [[ScheduleManager alloc] init];
	}
	return instance;
}

- (id)init
{
	NSAssert(instance==nil,@"ScheduleManager should only be instantiated once");
	self = [super init];
	if (self != nil)
	{
		// Restore schedule from file, if it exists.
		NSString * filename = [self scheduleFilename];
		BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filename];
		
		schedule = fileExists ? [NSKeyedUnarchiver unarchiveObjectWithFile:filename] 
							  : [[Schedule alloc] init];
	}
	return self;
}


#pragma mark - Schedule and notification methods

- (NSDate *)nextDateForTime:(NSDateComponents *)time andCalendarDay:(NSInteger)calendarDay
{
	NSAssert(time!=nil,@"time parameter must not be nil");
	NSAssert((calendarDay>0)&&(calendarDay<=7),@"calendarDay must be between 1 (Sunday) and 7 (Saturday)");
	
	// get the date and time right now
	NSDate * now = [NSDate date];
	
	// break down the individual date components and set the desired time
	NSCalendar * calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents * dateComponents = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekdayCalendarUnit) fromDate:now];
	[dateComponents setHour:[time hour]];
	[dateComponents setMinute:[time minute]];
	
	// get today's date updated with the new time
	NSDate * date = [calendar dateFromComponents:dateComponents];
	
	// find the offset to the desired calendar day for this week
	NSDateComponents * calendarDayOffset = [[NSDateComponents alloc] init];
	[calendarDayOffset setDay:(calendarDay - [dateComponents weekday])];

	// get the date and time updated to the desired calendar day of this week
	date = [calendar dateByAddingComponents:calendarDayOffset toDate:date options:0];	
	
	// if the date is in the past, add a week
	if ([date earlierDate:now] == date)
	{
		static const NSTimeInterval weekInSeconds = 7 * 24 * 60 * 60;
		date = [date dateByAddingTimeInterval:weekInSeconds];
	}
	
	return date;
}

- (void)scheduleNotification:(NSString *)action 
						text:(NSString *)text 
					  atTime:(NSDateComponents *)time 
			   onCalendarDay:(NSInteger)calendarDay
{
    UILocalNotification * notification = [[UILocalNotification alloc] init];
	
    notification.fireDate       = [self nextDateForTime:time andCalendarDay:calendarDay];
    notification.timeZone       = [NSTimeZone defaultTimeZone];
	notification.repeatInterval = NSWeekCalendarUnit;
    notification.alertBody      = text;
    notification.alertAction    = action;
    notification.soundName      = UILocalNotificationDefaultSoundName;
	
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}

- (void)createNotifications:(NSString *)action text:(NSString *)text onDays:(DaysOfWeek)daysOfWeek atTime:(NSDateComponents *)time
{
	for (NSInteger day = 0; day < 7; day++)
	{
		if (daysOfWeek & dayValues[day])
		{
			[self scheduleNotification:action 
								  text:text 
								atTime:time 
						 onCalendarDay:day+1];
		} 
	}
}

- (void)scheduleChanged:(Schedule *)newSchedule
{
	if (! [schedule isEqual:newSchedule])
	{
		DDLogInfo(@"Creating notifications for new schedule");
		
		schedule = newSchedule;
		
		[[UIApplication sharedApplication] cancelAllLocalNotifications];
		
		if (schedule.enabled)
		{
			[self createNotifications:NSLocalizedString(@"Sign On",@"Sign On") 
								 text:NSLocalizedString(@"Sign on",@"Scheduled sign on prompt") 
							   onDays:schedule.signOnDays 
							   atTime:schedule.signOnTime];
			
			[self createNotifications:NSLocalizedString(@"Sign Off",@"Sign Off") 
								 text:NSLocalizedString(@"Sign off",@"Scheduled sign off prompt") 
							   onDays:schedule.signOffDays 
							   atTime:schedule.signOffTime];
		}
		
		[self saveSchedule];
	}
}


#pragma mark - Private methods

- (NSString *)scheduleFilename
{
	return [[RealityVisionAppDelegate documentDirectory] stringByAppendingPathComponent:@"Schedule.prefs"];	
}

- (void)saveSchedule
{
	NSString * filename = [self scheduleFilename];
	if (! [NSKeyedArchiver archiveRootObject:schedule toFile:filename])
	{
		DDLogError(@"Could not save schedule preferences");
	}
}

@end
