//
//  UserDevice.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/22/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapObject.h"

@class Device;


/**
 *  A user signed on to a particular device that can be displayed on a map.
 */
@interface UserDevice : NSObject <MapObject>

/**
 *  The underlying Device object.
 */
@property (strong, nonatomic,readonly) Device * device;

/**
 *  Used to position the user on a map.
 */
@property (nonatomic) CLLocationCoordinate2D coordinate;

/**
 *  Initializes a UserDevice object.
 */
- (id)initWithDevice:(Device *)device;

/**
 *  Updates the device data.  The receiver and newDevice objects must refer
 *  to the same device.  That is, the type of the sourceObject for both the
 *  receiver and the newDevice object must be the same, and any unique
 *  identifiers for the two objects must also be the same.  All other data
 *  will be updated with the values from newDevice.
 *  
 *  @param newDevice Object whose values are used to update the receiver.
 *  @return YES if receiver's values changed because of the updated.
 */
- (BOOL)updateDeviceInfoFrom:(UserDevice *)newDevice;

@end
