//
//  TransmitterInfo.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/24/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "TransmitterInfo.h"
#import "GpsLockStatus.h"


@implementation TransmitterInfo

@synthesize deviceId;
@synthesize deviceName;
@synthesize description;
@synthesize userName;
@synthesize fullName;
@synthesize latitude;
@synthesize longitude;
@synthesize thumbnail;
@synthesize startTime;
@synthesize isGpsActive;
@synthesize gpsLockStatus;
@synthesize lastGpsTime;




#pragma mark -
#pragma mark Equality overrides

- (BOOL)isEqualToTransmitterInfo:(TransmitterInfo *)transmitterInfo 
{
	return [self.deviceId  isEqualToString:transmitterInfo.deviceId]  && 
	       [self.userName  isEqualToString:transmitterInfo.userName]  && 
	       [self.startTime isEqualToDate:transmitterInfo.startTime];
}


- (BOOL)isEqual:(id)other 
{
	if (other == self)
		return YES;
	
	if ((other == nil) || (! [other isKindOfClass:[self class]]))
		return NO;
    
	return [self isEqualToTransmitterInfo:other];
}


// hash algorithm from http://stackoverflow.com/questions/254281/best-practices-for-overriding-isequal-and-hash

- (NSUInteger)hash 
{
	static const NSUInteger prime = 31;
	NSUInteger result = 1;
	
	result = prime * result + (deviceId  ? [deviceId hash]  : 0);
	result = prime * result + (userName  ? [userName hash]  : 0);
	result = prime * result + (startTime ? [startTime hash] : 0);
	
	return result;
} 

@end
