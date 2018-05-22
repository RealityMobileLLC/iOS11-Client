//
//  ClientConfiguration.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  The Client Configuration retrieved from a RealityVision server.
 */
@interface ClientConfiguration : NSObject <NSCoding>

/**
 *  The number of seconds between "checkins" while running in the foreground, to let the
 *  server know the client is still active.
 */
@property (nonatomic,readonly) int clientConnectionActiveRate;

/**
 *  The number of items a client should use when paging through a user's
 *  command history.
 *
 *  On the iPhone client this is used to determine how many commands to
 *  retrieve from the server when the user selects "Older Commands".
 */
@property (nonatomic,readonly) int clientCommandDisplayCount;

/**
 *  The number of meters a client must move before reporting a new location.
 */
@property (nonatomic,readonly) int gpsThresholdDistance;

/**
 *  The number of seconds that must pass before a client reports a new location.
 */
@property (nonatomic,readonly) int maximumGpsTransmissionRate;

/**
 *  The maximum horizontal dilution of precision a client should accept as a 
 *  valid location.
 */
@property (nonatomic,readonly) float maximumGpsHdop;

/**
 *  Indicates whether the client can store the last signed on userid.
 */
@property (nonatomic,readonly) BOOL clientCanStoreUserid;

/**
 *  The number of seconds between attempts to refresh the list of cameras.
 */
@property (nonatomic,readonly) int clientCameraRefreshPeriod;

/**
 *  The number of seconds between attempts to refresh the list of users.
 */
@property (nonatomic,readonly) int tabletMapUserRefreshPeriod;

/**
 *  The maximum number of simultaneous video feeds the client can watch.
 */
@property (nonatomic,readonly) int maximumSimultaneousFeeds;

/**
 *  The maximum consecutive number of seconds to allow a user to talk.
 */
@property (nonatomic,readonly) int maximumPushToTalkTimeSeconds;

/**
 *  Initializes a ClientConfiguration object from a dictionary of name/value
 *  pairs.
 *
 *  @param configValues Dictionary containing configuration values.
 *
 *  @return An initialized ClientConfiguration object or nil if the object
 *           could not be initialized.
 */
- (id)initFromDictionary:(NSDictionary *)configValues;

@end
