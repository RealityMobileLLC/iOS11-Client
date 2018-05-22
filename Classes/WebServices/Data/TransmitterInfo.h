//
//  TransmitterInfo.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/24/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GpsLockStatus;


/**
 *  Information about an active RealityVision transmit session.
 */
@interface TransmitterInfo : NSObject 

@property (strong, nonatomic) NSString      * deviceId;
@property (strong, nonatomic) NSString      * deviceName;
@property (strong, nonatomic) NSString      * description;
@property (strong, nonatomic) NSString      * userName;
@property (strong, nonatomic) NSString      * fullName;
@property (nonatomic)         double          latitude;
@property (nonatomic)         double          longitude;
@property (strong, nonatomic) UIImage       * thumbnail;
@property (strong, nonatomic) NSDate        * startTime;
@property (nonatomic)         BOOL            isGpsActive;
@property (strong, nonatomic) GpsLockStatus * gpsLockStatus;
@property (strong, nonatomic) NSDate        * lastGpsTime;

@end
