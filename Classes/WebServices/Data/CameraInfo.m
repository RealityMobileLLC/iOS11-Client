//
//  CameraInfo.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CameraInfo.h"


@implementation CameraInfo

@synthesize server;
@synthesize port;
@synthesize uri;
@synthesize caption;
@synthesize cameraType;
@synthesize country;
@synthesize province;
@synthesize city;
@synthesize latitude;
@synthesize longitude;
@synthesize description;
@synthesize range;
@synthesize tilt;
@synthesize heading;
@synthesize controlStub;
@synthesize controlRight;
@synthesize controlLeft;
@synthesize controlUp;
@synthesize controlDown;
@synthesize controlHome;
@synthesize controlZoomIn;
@synthesize controlZoomOut;
@synthesize controlPan;
@synthesize controlTilt;
@synthesize lastHeartbeat;
@synthesize lastHeartbeatTime;
@synthesize inactive;
@synthesize thumbnail;
@synthesize startTime;


- (BOOL)hasHeartbeat
{
	if (lastHeartbeat == nil)
		return NO;
	
	BOOL lastHeartbeatValue = NO;
	[lastHeartbeat getValue:&lastHeartbeatValue];
	return lastHeartbeatValue;
}


#pragma mark - Equality overrides

- (BOOL)isEqualToCameraInfo:(CameraInfo *)cameraInfo 
{
	return ([self.caption isEqual:cameraInfo.caption]);
}


- (BOOL)isEqual:(id)other 
{
    if (other == self)
        return YES;
	
    if ((other == nil) || (! [other isKindOfClass:[self class]]))
        return NO;
    
	return [self isEqualToCameraInfo:other];
}


// hash algorithm from http://stackoverflow.com/questions/254281/best-practices-for-overriding-isequal-and-hash

- (NSUInteger)hash 
{
    return [self.caption hash];
}

@end
