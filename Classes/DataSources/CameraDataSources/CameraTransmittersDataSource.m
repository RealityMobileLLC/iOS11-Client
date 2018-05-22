//
//  CameraTransmittersDataSource.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/24/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CameraTransmittersDataSource.h"
#import "ClientConfiguration.h"
#import "SystemUris.h"
#import "CameraInfo.h"
#import "CameraInfoWrapper.h"
#import "TransmitterInfo.h"
#import "ConfigurationManager.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CameraTransmittersDataSource
{
	ClientTransaction * webRequest;
}


- (id)initWithCameraDelegate:(id <CameraDataSourceDelegate>)myDelegate
{
	self = [super init];
	if (self != nil)
	{
		self.delegate = myDelegate;
	}
	return self;
}

- (NSString *)title
{
	return NSLocalizedString(@"User Feeds",@"Browse user feeds title");
}

- (NSString *)loadingCamerasText
{
	return NSLocalizedString(@"Loading User Feeds ...",@"Loading user feeds");
}

- (NSString *)noCamerasText
{
	return NSLocalizedString(@"No User Feeds",@"No user feeds");
}

- (NSString *)searchPlaceholderText
{
	return NSLocalizedString(@"Search User Feeds",@"Search user feeds");
}

- (BOOL)supportsRefresh
{
	return YES;
}

- (void)getCameras
{
	if (! isLoading)
	{
		isLoading = YES;
		NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
		webRequest = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
		webRequest.delegate = self;
		[webRequest getTransmitters];
	}
}

- (void)refresh
{
	// transmitters aren't cached, so just call getCameras again to get new list
	[self getCameras];
}

- (void)cancel
{
	if (isLoading)
	{
		isLoading = NO;
		[webRequest cancel];
		webRequest = nil;
	}
}

- (void)reset
{
	[super reset];
	webRequest = nil;
}

- (void)onGetTransmittersResult:(NSArray *)transmitters error:(NSError *)error
{
	DDLogInfo(@"CameraTransmittersDataSource onGetTransmittersResult");
	isLoading = NO;
	
	if ((transmitters == nil) && (error == nil))
	{
		error = [RvError rvErrorWithLocalizedDescription:@"Did not receive the list of transmitters."];
	}
	
	if (error != nil)
	{
		[self.delegate cameraListDidGetError:error];
		webRequest = nil;
		return;
	}
    
	NSMutableArray * allCameras     = [NSMutableArray arrayWithCapacity:[transmitters count]];
	NSMutableArray * camerasAdded   = [NSMutableArray arrayWithCapacity:[transmitters count]];
	NSMutableArray * camerasRemoved = [NSMutableArray arrayWithCapacity:[transmitters count]];
	NSMutableArray * camerasUpdated = [NSMutableArray arrayWithCapacity:[transmitters count]];
	
	for (TransmitterInfo * transmitter in transmitters)
	{
		[allCameras addObject:[[CameraInfoWrapper alloc] initWithTransmitter:transmitter]];
	}
    
	cameras = [self updateCameras:cameras 
											fromArray:[allCameras sortedArrayUsingSelector:@selector(compareNameAndStartTime:)] 
										 camerasAdded:camerasAdded 
									   camerasRemoved:camerasRemoved 
									   camerasUpdated:camerasUpdated];

	filteredCameras = [[NSMutableArray alloc] initWithCapacity:[cameras count]];
	[self notifyDelegateCamerasAdded:camerasAdded camerasRemoved:camerasRemoved camerasUpdated:camerasUpdated];
	
	webRequest = nil;
}

@end
