//
//  Schedule.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/15/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Days of week bitmask.
 */
typedef enum 
{
	DaysNone      = 0,
	DaysMonday    = 1 << 0,
	DaysTuesday   = 1 << 1,
	DaysWednesday = 1 << 2,
	DaysThursday  = 1 << 3,
	DaysFriday    = 1 << 4,
	DaysSaturday  = 1 << 5,
	DaysSunday    = 1 << 6,
	DaysWeekdays  = DaysMonday | DaysTuesday | DaysWednesday | DaysThursday | DaysFriday,
	DaysWeekends  = DaysSaturday | DaysSunday,
	DaysAll       = DaysWeekdays | DaysWeekends
} DaysOfWeek;


/**
 *  Maps ordinal day values to DaysOfWeek values.  Entries in the array are in 
 *  the same order as used by NSDateComponents.  To get the  ordinal 
 *  value used for a given day in NSDateComponents, add 1 to the array index. 
 *  
 *  Sunday is at index 0 in the array and represented as 1 in NSDateComponents.
 *  Saturday is at index 6 in the array and represented as 7 in NSDateComponents.
 */
extern const DaysOfWeek dayValues[];


/**
 *  A schedule of sign on and sign off times for a user.
 */
@interface Schedule : NSObject <NSCoding, NSCopying>

/**
 *  Indicates whether auto sign on/off is enabled.
 */
@property (nonatomic) BOOL enabled;

/**
 *  The days of the week that the user should be automatically signed on.
 *  On each of these days, the user will be prompted to sign on at the 
 *  signOnTime.
 */
@property (nonatomic,readonly) DaysOfWeek signOnDays;

/**
 *  The time of day that the user should be automatically signed on.  Only
 *  the time components (hours and minutes) are used.
 */
@property (nonatomic,readonly) NSDateComponents * signOnTime;

/**
 *  The days of the week that the user should be automatically signed off.
 *  On each of these days, the user will be prompted to sign off at the 
 *  signOffTime.
 */
@property (nonatomic,readonly) DaysOfWeek signOffDays;

/**
 *  The time of day that the user should be automatically signed off.  Only
 *  the time components (hours and minutes) are used.
 */
@property (nonatomic,readonly) NSDateComponents * signOffTime;

/**
 *  Initializes a schedule for manual sign on and off.
 */
- (id)init;

/**
 *  Changes the sign on time.
 */
- (void)setSignOnDays:(DaysOfWeek)signOnDays andTime:(NSDate *)signOnTime;

/**
 *  Changes the sign off time.
 */
- (void)setSignOffDays:(DaysOfWeek)signOffDays andTime:(NSDate *)signOffTime;

/**
 *  Indicates whether the Schedule is equal to the given object.
 */
- (BOOL)isEqual:(id)other;

/**
 *  Abbreviated localized string representation of the given day of the week.  
 *  If more than one day is represented in the DaysOfWeek value, returns 
 *  "multiple".
 */
+ (NSString *)stringAbbreviationForDayOfWeek:(DaysOfWeek)day;

/**
 *  Localized string representation of the given day of the week.  If more
 *  than one day is represented in the DaysOfWeek value, returns "multiple".
 */
+ (NSString *)stringForDayOfWeek:(DaysOfWeek)day;

/**
 *  Localized string representation of the sign on or off schedule for multiple
 *  days of the week.
 */
+ (NSString *)stringForScheduledDaysOfWeek:(DaysOfWeek)daysOfWeek;

@end
