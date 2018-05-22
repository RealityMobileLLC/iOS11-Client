//
//  Session.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/29/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Information about a RealityVision video session.
 */
@interface Session : NSObject 

@property (nonatomic)         int              sessionId;
@property (strong, nonatomic) NSString       * deviceId;
@property (strong, nonatomic) NSString       * deviceDescription;
@property (strong, nonatomic) NSDate         * startTime;
@property (strong, nonatomic) NSDate         * stopTime;
@property (strong, nonatomic) NSDate         * gpsStartTime;
@property (strong, nonatomic) NSDate         * gpsStopTime;
@property (strong, nonatomic) NSMutableArray * comments;
@property (strong, nonatomic) NSString       * userFullName;
@property (strong, nonatomic) NSString       * username;
@property (nonatomic)         BOOL             hasGps;
//@todo @property (nonatomic,retain) GeoRegion * region;
@property (nonatomic)         int              frameCount;
@property (strong, nonatomic) UIImage        * thumbnail;

@end
