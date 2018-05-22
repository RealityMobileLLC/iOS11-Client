//
//  GpsLockStatus.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/4/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//


/**
 *  The GPS lock status.
 */
typedef enum
{
	GL_NoLock,     /**< The client has not had a lock this session.           */
	GL_LostLock,   /**< The client had a lock but is no longer in lock state. */
	GL_Lock        /**< The client has a lock.                                */
} GpsLockStatusEnum;


/**
 *  Wrapper around the GpsLockStatusEnum allowing for easy
 *  conversion to and from an NSString.
 */
@interface GpsLockStatus : NSObject 

/**
 *  Value as a GpsLockStatusEnum.
 */
@property (nonatomic) GpsLockStatusEnum value;

/**
 *  Initializes a GpsLockStatus object from the given string.  If the string
 *  does not map to a valid GpsLockStatusEnum, the returned object is 
 *  initialized with the value 0.
 *
 *  @param stringValue String representation of one of the GpsLockStatusEnum values.
 *  @return initialized GpsLockStatus
 */
- (id)initWithString:(NSString *)stringValue;

/**
 *  Initializes a GpsLockStatus object with the given value.
 *  
 *  @param gpsLockStatus Initial value
 *  @return initialized GpsLockStatus
 */
- (id)initWithValue:(GpsLockStatusEnum)gpsLockStatus;

/**
 *  Value as a string.
 */
- (NSString *)stringValue;

/**
 *  Gets the string value for the given GpsLockStatusEnum.
 */
+ (NSString *)stringValueForEnum:(GpsLockStatusEnum)gpsLockStatus;

@end
