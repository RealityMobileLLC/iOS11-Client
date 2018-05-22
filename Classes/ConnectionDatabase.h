//
//  ConnectionDatabase.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ConnectionProfile;


/**
 *  Provides access to the connection profile stored in the app's Settings.
 */
@interface ConnectionDatabase : NSObject

/**
 *  Gets the active connection profile.
 */
+ (ConnectionProfile *)activeProfile;

/**
 *  Sets the active connection profile.
 */
+ (void)setActiveProfile:(ConnectionProfile *)profile;

@end
