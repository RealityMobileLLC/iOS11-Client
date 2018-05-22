//
//  NSString+RealityVision.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/12/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "NSString+RealityVision.h"
#import <CoreLocation/CoreLocation.h>


static double getNmeaDegreesMinutes(double val)
{
	val = fabs(val);
	double degrees = floor(val);
	double minutes = (val - degrees) * 60.0;
	return (degrees * 100.0) + minutes;
}


@implementation NSString (NmeaLocation) 

+ (NSString *)gpggaStringWithLocation:(CLLocation *)location
{
	static NSString * const gpggaFormat = @"$GPGGA,%@,%.4f,%c,%.4f,%c,%d,%d,%.1f,%f,M,%f,M,,";
	static NSDateFormatter * dateFormatter = nil;
	
	if (dateFormatter == nil)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"HHmmss.S"];
	}
	
	NSString * timeString = [dateFormatter stringFromDate:location.timestamp];
	
	double latitudeInNmea = getNmeaDegreesMinutes(location.coordinate.latitude);
	double longitudeInNmea = getNmeaDegreesMinutes(location.coordinate.longitude);
	
	char northOrSouth = location.coordinate.latitude >= 0 ? 'N' : 'S';
	char eastOrWest = location.coordinate.longitude >= 0 ? 'E' : 'W';
	
	int fixType = 2;     // GPS
	int satCount = 4;    // CLLocation doesn't have satellite count
	float hdop = 0.0;    // or hdop
	
	float altSeaLevel = (location.verticalAccuracy >= 0) ? location.altitude : 0.0;
	float altEllipsoid = 0.0;
	
    return [NSString stringWithFormat:gpggaFormat, 
								      timeString, 
									  latitudeInNmea, northOrSouth, 
			                          longitudeInNmea, eastOrWest, 
			                          fixType, satCount, hdop, altSeaLevel, altEllipsoid];
}

+ (NSString *)stringForTimeInterval:(NSTimeInterval)interval
{
	int minutes = (int)interval / 60;
	int seconds = (int)interval % 60;
	return [NSString stringWithFormat:@"%d:%.2d", minutes, seconds];
}

@end
