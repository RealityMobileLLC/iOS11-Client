//
//  UserDevice.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/22/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "UserDevice.h"
#import "Device.h"
#import "TransmitterInfo.h"
#import "CameraInfoWrapper.h"
#import "ViewerInfo.h"


@implementation UserDevice

@synthesize camera;
@synthesize cameraViewer;
@synthesize device;
@synthesize coordinate;


#pragma mark - Initialization and cleanup

- (id)initWithDevice:(Device *)theDevice;
{
    self = [super init];
    if (self) 
    {
        device = theDevice;
        [self initLocation];
    }
    
    return self;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey 
{
	// indicate the properties for which we implement manual KVO
	if ([theKey isEqualToString:@"subtitle"])
		return NO;
	
	return [super automaticallyNotifiesObserversForKey:theKey];
}


#pragma mark - Public methods

- (BOOL)hasLocation
{
    return device.isGps && RVLocationCoordinate2DIsValid(coordinate);
}

- (BOOL)updateDeviceInfoFrom:(UserDevice *)userDevice
{
    NSAssert(userDevice,@"userDevice is required");

    // don't do anything if userDevice and self are the same object, or if they refer to different devices
    if ((userDevice == self) || (! [userDevice isEqual:self]))
        return NO;
    
    // always update underlying device info but only indicate it has changed if key state data changes
    BOOL hasChanged = NO;
    
    if ((device.latitude != userDevice.device.latitude) ||
        (device.longitude != userDevice.device.longitude) ||
        (device.isCamera != userDevice.device.isCamera) ||
        (device.isViewer != userDevice.device.isViewer) ||
        (device.isPanic != userDevice.device.isPanic) ||
        (device.isGps != userDevice.device.isGps) ||
        (device.gpsLockStatus.value != userDevice.device.gpsLockStatus.value) ||
		([device.viewers count] > 0) || ([userDevice.device.viewers count] > 0))
    {
        hasChanged = YES;
        
        // update location but don't set it to kCLLocationCoordinate2DInvalid (see BUG-3424)
		self.coordinate = CLLocationCoordinate2DMake(userDevice.device.latitude, userDevice.device.longitude);
		
		// notify observers that subtitle has changed (even though it might not have)
		// this will update map callout as well as any ViewedFeedsViewController popovers
		//
		// NOTE: Removing the association between a UserDevice's subtitle and its viewed feeds
		//       may require changes to ViewedFeedsViewController
		//
		[self willChangeValueForKey:@"subtitle"];
    }
    
    device = userDevice.device;
	
	if (hasChanged)
	{
		[self didChangeValueForKey:@"subtitle"];
	}
    
    return hasChanged;
}

- (CameraInfoWrapper *)camera
{
    if (! device.isCamera) 
        return nil;
    
    TransmitterInfo * transmitter = [[TransmitterInfo alloc] init];
    transmitter.deviceId = device.deviceId;
    transmitter.deviceName = device.deviceName;
    transmitter.description = device.description;
    transmitter.userName = device.userName;
    transmitter.fullName = device.fullName;
    transmitter.latitude = device.latitude;
    transmitter.longitude = device.longitude;
    transmitter.isGpsActive = device.isGps;
    transmitter.gpsLockStatus = device.gpsLockStatus;
    transmitter.lastGpsTime = device.lastGpsTime;
    transmitter.startTime = nil;
    transmitter.thumbnail = nil;
    
    return [[CameraInfoWrapper alloc] initWithTransmitter:transmitter];
}


#pragma mark - MKAnnotation methods

- (NSString *)title
{
	return device.fullName;
}

- (NSString *)subtitle
{
	if ([device.viewers count] == 0)
		return nil;
	
	if ([device.viewers count] > 1)
		return NSLocalizedString(@"Watching Multiple Feeds",@"Watching Multiple Feeds");
	
	ViewerInfo * viewer = [device.viewers objectAtIndex:0];
	return ([[viewer caption] length] > 0) ? [viewer caption] : [viewer fullName];
}


#pragma mark - Equality overrides

- (BOOL)isEqualToUserDevice:(UserDevice *)userDevice 
{
	return [device.deviceId isEqual:userDevice.device.deviceId];
}

- (BOOL)isEqual:(id)other 
{
    if (other == self)
        return YES;
    
    if ((other == nil) || (! [other isKindOfClass:[self class]]))
        return NO;
    
	return [self isEqualToUserDevice:other];
}

// hash algorithm from http://stackoverflow.com/questions/254281/best-practices-for-overriding-isequal-and-hash
- (NSUInteger)hash 
{
	return [device.deviceId hash];
}


#pragma mark - Private methods

- (void)initLocation
{
	CLLocationCoordinate2D location = kCLLocationCoordinate2DInvalid;
	
    if (device.isGps)
    {
        location.latitude  = device.latitude;
        location.longitude = device.longitude;
    }
	
	coordinate = location;
}

@end
