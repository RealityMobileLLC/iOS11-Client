//
//  ViewerInfo.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 5/30/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  A ViewerInfo object describes a video feed being watched by a RealityVision user.
 */
@interface ViewerInfo : NSObject

@property (nonatomic)         int         cameraType;
@property (strong, nonatomic) NSString  * uri;
@property (strong, nonatomic) NSString  * server;
@property (nonatomic)         long long   port;
@property (strong, nonatomic) NSString  * caption;
@property (strong, nonatomic) NSString  * description;
@property (strong, nonatomic) UIImage   * thumbnail;
@property (strong, nonatomic) NSString  * deviceId;
@property (strong, nonatomic) NSString  * deviceName;
@property (strong, nonatomic) NSString  * userName;
@property (strong, nonatomic) NSString  * fullName;
@property (strong, nonatomic) NSDate    * archiveStartTime;
@property (strong, nonatomic) NSDate    * archiveEndTime;

@end
