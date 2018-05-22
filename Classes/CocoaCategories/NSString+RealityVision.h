//
//  NSString+RealityVision.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/12/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;


/**
 *  The NmeaLocation category extends NSString to provide custom functionality.
 */
@interface NSString (RealityVision) 

/**
 *  Returns an NMEA GPGGA string for the given location.
 *
 *  @param location The location to convert to a string.
 *  @return The location formatted as a GPGGA string.
 */
+ (NSString *)gpggaStringWithLocation:(CLLocation *)location;

/**
 *  Returns a string showing the given interval as minutes and seconds, i.e. "5:23".
 */
+ (NSString *)stringForTimeInterval:(NSTimeInterval)interval;

@end
