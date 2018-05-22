//
//  CameraInfo.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A viewable video feed.
 */
@interface CameraInfo : NSObject 

/**
 *  Derived value that indicates whether the camera responded to a heartbeat
 *  message.
 *
 *  @return YES if lastHeartbeat is not nil and its value is YES
 */
@property (nonatomic,readonly) BOOL hasHeartbeat;

@property (strong, nonatomic) NSString  * server;
@property (nonatomic)         long long   port;
@property (strong, nonatomic) NSString  * uri;
@property (strong, nonatomic) NSString  * caption;
@property (nonatomic)         int         cameraType;
@property (strong, nonatomic) NSString  * country;
@property (strong, nonatomic) NSString  * province;
@property (strong, nonatomic) NSString  * city;
@property (nonatomic)         double      latitude;
@property (nonatomic)         double      longitude;
@property (strong, nonatomic) NSString  * description;
@property (nonatomic)         double      range;
@property (nonatomic)         double      tilt;
@property (nonatomic)         double      heading;
@property (strong, nonatomic) NSString  * controlStub;
@property (strong, nonatomic) NSString  * controlRight;
@property (strong, nonatomic) NSString  * controlLeft;
@property (strong, nonatomic) NSString  * controlUp;
@property (strong, nonatomic) NSString  * controlDown;
@property (strong, nonatomic) NSString  * controlHome;
@property (strong, nonatomic) NSString  * controlZoomIn;
@property (strong, nonatomic) NSString  * controlZoomOut;
@property (strong, nonatomic) NSString  * controlPan;
@property (strong, nonatomic) NSString  * controlTilt;
@property (strong, nonatomic) NSValue   * lastHeartbeat;         // BOOL
@property (strong, nonatomic) NSDate    * lastHeartbeatTime;
@property (nonatomic)         BOOL        inactive;
@property (strong, nonatomic) UIImage   * thumbnail;
@property (strong, nonatomic) NSDate    * startTime;

@end
