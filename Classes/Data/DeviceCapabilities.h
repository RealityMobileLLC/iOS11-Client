//
//  DeviceCapabilities.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/9/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Key used to get the client platform.
 */
extern NSString * const KEY_PLATFORM;

/**
 *  Key used to get the client OS version.
 */
extern NSString * const KEY_OS_VERSION;

/**
 *  Key used to get the RealityVision version.
 */
extern NSString * const KEY_APP_VERSION;

/**
 *  Key used to get the client phone number.
 */
extern NSString * const KEY_PHONE_NUMBER;

/**
 *  Key used to get the name of the client device.
 */
extern NSString * const KEY_DEVICE_NAME;

/**
 *  Key used to get the client device's manufacturer.
 */
extern NSString * const KEY_MANUFACTURER;

/**
 *  Key used to get the client device's cellular network provider.
 */
extern NSString * const KEY_CARRIER;

/**
 *  Key used to determine whether the client device supports location services.
 */
extern NSString * const KEY_SUPPORT_GPS;

/**
 *  Key used to determine whether the client device is capable of transmitting video.
 */
extern NSString * const KEY_SUPPORT_VIDEO;

/**
 *  Key used to determine whether the client device is able to make phone calls.
 */
extern NSString * const KEY_SUPPORT_PHONE;

/**
 *  Key used to determine whether the client device supports RealityVision commands.
 */
extern NSString * const KEY_SUPPORT_COMMANDS;

/**
 *  Key used to determine which push notification service the client uses.
 */
extern NSString * const KEY_PUSH_SERVICE;

/**
 *  Key used to get the client device's push notification token.
 */
extern NSString * const KEY_PUSH_TOKEN;


/**
 *  Defines the device capabilities for the client device.
 */
@interface DeviceCapabilities : NSObject 

/**
 *  The device capabilities in a dictionary of key/value pairs.
 */
@property (strong, nonatomic,readonly) NSDictionary * values;

/**
 *  Sets the value for the given key.  If the key doesn't already exist in the
 *  device capabilities, it is added.
 *
 *  @param value New value for key.
 *  @param key   Key whose value is to be set.
 */
- (void)setValue:(NSString *)value forKey:(NSString *)key;

/**
 *  Returns a dictionary of key/value pairs identifying the push notification
 *  service and token.
 */
- (NSDictionary *)pushNotificationValues;

/**
 *  Indicates whether the device supports transmitting video.
 */
+ (BOOL)supportsVideo;

/**
 *  Indicates whether the device supports phone calls.
 */
+ (BOOL)supportsPhone;

@end
