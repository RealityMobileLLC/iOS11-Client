//
//  Schedule.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/15/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "Schedule.h"


const DaysOfWeek dayValues[] = 
{ 
	DaysSunday, 
	DaysMonday, 
	DaysTuesday, 
	DaysWednesday, 
	DaysThursday, 
	DaysFriday, 
	DaysSaturday 
};


// Keys used for serialization
static NSString * const KEY_ENABLED       = @"Enabled";
static NSString * const KEY_SIGN_ON_DAYS  = @"SignOnDays";
static NSString * const KEY_SIGN_ON_TIME  = @"SignOnTime";
static NSString * const KEY_SIGN_OFF_DAYS = @"SignOffDays";
static NSString * const KEY_SIGN_OFF_TIME = @"SignOffTime";


@implementation Schedule
{
	BOOL               enabled;
	NSDateComponents * signOnTime;
	NSDateComponents * signOffTime;
}

@synthesize enabled;
@synthesize signOnDays;
@synthesize signOnTime;
@synthesize signOffDays;
@synthesize signOffTime;


#pragma mark -
#pragma mark Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		enabled = NO;
		signOnDays = signOffDays = DaysWeekdays;
		
		signOnTime = [[NSDateComponents alloc] init];
		[signOnTime setHour:8];
		[signOnTime setMinute:0];
		
		signOffTime = [[NSDateComponents alloc] init];
		[signOffTime setHour:17];
		[signOffTime setMinute:0];
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder 
{
	enabled     = [coder containsValueForKey:KEY_ENABLED] ? [coder decodeBoolForKey:KEY_ENABLED] : YES;
	signOnDays  = [coder decodeIntForKey:KEY_SIGN_ON_DAYS];
	signOffDays = [coder decodeIntForKey:KEY_SIGN_OFF_DAYS];
	signOnTime  = [coder decodeObjectForKey:KEY_SIGN_ON_TIME];
	signOffTime = [coder decodeObjectForKey:KEY_SIGN_OFF_TIME];
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder 
{
	[coder encodeBool:enabled       forKey:KEY_ENABLED];
	[coder encodeInt:signOnDays     forKey:KEY_SIGN_ON_DAYS];
    [coder encodeInt:signOffDays    forKey:KEY_SIGN_OFF_DAYS];
	[coder encodeObject:signOnTime  forKey:KEY_SIGN_ON_TIME];
	[coder encodeObject:signOffTime forKey:KEY_SIGN_OFF_TIME];
}


- (id)initWithSchedule:(Schedule *)schedule
{
	self = [super init];
	if (self != nil)
	{
		enabled     = schedule.enabled;
		signOnDays  = schedule.signOnDays;
		signOffDays = schedule.signOffDays;
		signOnTime  = [schedule.signOnTime copy];
		signOffTime = [schedule.signOffTime copy];
	}
	return self;
}


- (id)copyWithZone:(NSZone *)zone
{
	return [[Schedule allocWithZone:zone] initWithSchedule:self];
}




#pragma mark -
#pragma mark Public methods

- (void)setSignOnDays:(DaysOfWeek)newSignOnDays andTime:(NSDate *)newSignOnTime
{
	signOnDays = newSignOnDays;
	[self setSignOnTimeFromDate:newSignOnTime];
}


- (void)setSignOffDays:(DaysOfWeek)newSignOffDays andTime:(NSDate *)newSignOffTime
{
	signOffDays = newSignOffDays;
	[self setSignOffTimeFromDate:newSignOffTime];
}


#pragma mark -
#pragma mark Class methods

+ (NSString *)stringForDayOfWeek:(DaysOfWeek)day fromArray:(NSArray *)daysOfWeek
{
	NSString * text;
	
	switch (day) 
	{
		case DaysSunday:
			text = [daysOfWeek objectAtIndex:0];
			break;
			
		case DaysMonday:
			text = [daysOfWeek objectAtIndex:1];
			break;
		
		case DaysTuesday:
			text = [daysOfWeek objectAtIndex:2];
			break;
		
		case DaysWednesday:
			text = [daysOfWeek objectAtIndex:3];
			break;
		
		case DaysThursday:
			text = [daysOfWeek objectAtIndex:4];
			break;
		
		case DaysFriday:
			text = [daysOfWeek objectAtIndex:5];
			break;
		
		case DaysSaturday:
			text = [daysOfWeek objectAtIndex:6];
			break;
		
		default:
			text = NSLocalizedString(@"multiple",@"multiple days of week");
	}
	
	return text;
}


+ (NSString *)stringAbbreviationForDayOfWeek:(DaysOfWeek)day
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	NSString * dayOfWeekString = [self stringForDayOfWeek:day fromArray:[dateFormatter shortWeekdaySymbols]];
	return dayOfWeekString;
}


+ (NSString *)stringForDayOfWeek:(DaysOfWeek)day
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	NSString * dayOfWeekString = [self stringForDayOfWeek:day fromArray:[dateFormatter weekdaySymbols]];
	return dayOfWeekString;
}


+ (NSString *)stringForScheduledDaysOfWeek:(DaysOfWeek)daysOfWeek
{
	if (daysOfWeek == DaysNone)
	{
		return NSLocalizedString(@"Manual",@"Sign on/off manual");
	}
	
	if (daysOfWeek == DaysWeekdays)
	{
		return NSLocalizedString(@"Weekdays",@"Sign on/off weekdays");
	}
	
	if (daysOfWeek == DaysWeekends)
	{
		return NSLocalizedString(@"Weekends",@"Sign on/off weekends");
	}
	
	if (daysOfWeek == DaysAll)
	{
		return NSLocalizedString(@"Daily",@"Sign on/off daily");
	}
	
	NSMutableString * daysOfWeekText = [NSMutableString stringWithCapacity:30];
	
	for (DaysOfWeek day = DaysMonday; day <= DaysSunday; day <<= 1)
	{
		if (daysOfWeek & day)
		{
			[daysOfWeekText appendFormat:@"%@ ",[self stringAbbreviationForDayOfWeek:day]];
		}
	}
	
	return daysOfWeekText;
}


#pragma mark -
#pragma mark Equality overrides

- (BOOL)isEqualToSchedule:(Schedule *)schedule 
{
	return ((self.enabled     == schedule.enabled)         &&
			(self.signOnDays  == schedule.signOnDays)      &&
			(self.signOffDays == schedule.signOffDays)     &&
	        [self.signOnTime  isEqual:schedule.signOnTime] &&
	        [self.signOffTime isEqual:schedule.signOffTime]);
}


- (BOOL)isEqual:(id)other 
{
    if (other == self)
        return YES;
	
    if ((other == nil) || (! [other isKindOfClass:[self class]]))
        return NO;
    
	return [self isEqualToSchedule:other];
}


// hash algorithm from http://stackoverflow.com/questions/254281/best-practices-for-overriding-isequal-and-hash

- (NSUInteger)hash 
{
	static const NSUInteger prime = 31;
    NSUInteger result = 1;
	
	result = prime * result + (enabled ? 1231 : 1237);
	result = prime * result + signOnDays;
	result = prime * result + [signOnTime hash];
	result = prime * result + signOffDays;
	result = prime * result + [signOffTime hash];
	
    return result;
}


#pragma mark -
#pragma mark Private methods

- (void)setSignOnTimeFromDate:(NSDate *)date
{
	signOnTime = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit) 
												  fromDate:date];
}


- (void)setSignOffTimeFromDate:(NSDate *)date
{
	signOffTime = [[NSCalendar currentCalendar] components:(NSHourCalendarUnit | NSMinuteCalendarUnit) 
												   fromDate:date];
}

@end
