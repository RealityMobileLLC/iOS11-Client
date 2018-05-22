//
//  LocationStatusBarButtonItem.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/16/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GpsLockStatus.h"


/**
 *  Protocol used to get the current location status.
 */
@protocol LocationStatusProvider

/**
 *  Indicates whether location updating is on.
 */
@property (nonatomic,readonly) BOOL locationOn;

/**
 *  Indicates whether the client currently has, or has had, a location lock.
 */
@property (nonatomic,readonly) GpsLockStatusEnum locationLock;

/**
 *  Toggles whether location updating is on or off.
 */
- (void)toggleLocationAware;

@end


/**
 *  A custom UIBarButtonItem that displays an image representing the current location status.
 */
@interface LocationStatusBarButtonItem : UIBarButtonItem

/**
 *  The object responsible for providing the location status.
 */
@property (nonatomic,weak) NSObject <LocationStatusProvider> * locationProvider;

/**
 *  Initializes a new LocationStatusBarButtonItem with a location provider.  When the 
 *  LocationStatusBarButtonItem is selected, the location provider is sent a 
 *  toggleLocationAware message.
 */
- (id)initWithLocationProvider:(NSObject <LocationStatusProvider> *)theLocationProvider;

@end
