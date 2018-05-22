//
//  Device.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/28/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GpsLockStatus.h"


/**
 *  State information for a RealityVision Client device.
 */
@interface Device : NSObject 

@property (strong, nonatomic) NSDate        * lastHeardFrom;
@property (strong, nonatomic) NSString      * deviceName;
@property (strong, nonatomic) NSString      * deviceId;
@property (nonatomic)         double          latitude;
@property (nonatomic)         double          longitude;
@property (nonatomic)         BOOL            isCamera;
@property (nonatomic)         BOOL            isViewer;
@property (nonatomic)         BOOL            isPanic;
@property (nonatomic)         int             userId;
@property (strong, nonatomic) NSString      * userName;
@property (strong, nonatomic) NSString      * fullName;
@property (strong, nonatomic) NSDate        * lastVideoTime;
@property (strong, nonatomic) NSDate        * lastGpsTime;
@property (strong, nonatomic) GpsLockStatus * gpsLockStatus;
@property (nonatomic)         BOOL            isGps;
@property (nonatomic)         BOOL            isSignedOn;
@property (strong, nonatomic) NSArray       * viewers;

@end
