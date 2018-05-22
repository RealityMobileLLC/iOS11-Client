//
//  MapConfiguration.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 5/13/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "MapConfiguration.h"

// Keys used for serialization
static NSString * const KEY_TRACKING_LOCATION = @"IsTrackingLocation";
static NSString * const KEY_CENTER_ON_CAMERAS = @"IsCenteredOnCameras";
static NSString * const KEY_SHOW_LABELS       = @"ShowLabels";
static NSString * const KEY_SHOW_FAVORITES    = @"ShowFavorites";
static NSString * const KEY_SHOW_TRANSMITTERS = @"ShowTransmitters";
static NSString * const KEY_SHOW_CAMERAS      = @"ShowCameras";
static NSString * const KEY_SHOW_SCREENCASTS  = @"ShowScreencasts";
static NSString * const KEY_SHOW_FILES        = @"ShowFiles";
static NSString * const KEY_SHOW_MY_VIDEOS    = @"ShowMyVideos";
static NSString * const KEY_SHOW_USERS        = @"ShowUsers";


@implementation MapConfiguration
{
    BOOL isTrackingLocation;
	BOOL isCenteredOnCameras;
	BOOL showFavorites;
	BOOL showTransmitters;
	BOOL showCameras;
	BOOL showScreencasts;
	BOOL showFiles;
	BOOL showMyVideos;
}

@synthesize isTrackingLocation;
@synthesize isCenteredOnCameras;
@synthesize showLabels;
@synthesize showFavorites;
@synthesize showTransmitters;
@synthesize showCameras;
@synthesize showScreencasts;
@synthesize showFiles;
@synthesize showMyVideos;
@synthesize showUsers;


- (id)init
{
	self = [super init];
	if (self != nil)
	{
		isTrackingLocation  = NO;
		isCenteredOnCameras = YES;
        showLabels          = YES;
		showFavorites       = YES;
		showTransmitters    = YES;
		showCameras         = YES;
		showScreencasts     = YES;
		showFiles           = YES;
		showMyVideos        = YES;
        showUsers           = YES;
	}
	return self;
}


- (id)initWithCoder:(NSCoder *)coder 
{
	isTrackingLocation  = [coder decodeBoolForKey:KEY_TRACKING_LOCATION];
	isCenteredOnCameras = [coder decodeBoolForKey:KEY_CENTER_ON_CAMERAS];
	showFavorites       = [coder decodeBoolForKey:KEY_SHOW_FAVORITES];
	showTransmitters    = [coder decodeBoolForKey:KEY_SHOW_TRANSMITTERS];
	showCameras         = [coder decodeBoolForKey:KEY_SHOW_CAMERAS];
	showScreencasts     = [coder decodeBoolForKey:KEY_SHOW_SCREENCASTS];
	showFiles           = [coder decodeBoolForKey:KEY_SHOW_FILES];
	showMyVideos        = [coder decodeBoolForKey:KEY_SHOW_MY_VIDEOS];
    showUsers           = [coder containsValueForKey:KEY_SHOW_USERS] ? [coder decodeBoolForKey:KEY_SHOW_USERS] : YES;
    showLabels          = [coder containsValueForKey:KEY_SHOW_LABELS] ? [coder decodeBoolForKey:KEY_SHOW_LABELS] : YES;
    
	return self;
}


- (void)encodeWithCoder:(NSCoder *)coder 
{
	[coder encodeBool:isTrackingLocation  forKey:KEY_TRACKING_LOCATION];
	[coder encodeBool:isCenteredOnCameras forKey:KEY_CENTER_ON_CAMERAS];
	[coder encodeBool:showFavorites       forKey:KEY_SHOW_FAVORITES];
	[coder encodeBool:showTransmitters    forKey:KEY_SHOW_TRANSMITTERS];
	[coder encodeBool:showCameras         forKey:KEY_SHOW_CAMERAS];
	[coder encodeBool:showScreencasts     forKey:KEY_SHOW_SCREENCASTS];
	[coder encodeBool:showFiles           forKey:KEY_SHOW_FILES];
	[coder encodeBool:showMyVideos        forKey:KEY_SHOW_MY_VIDEOS];
    [coder encodeBool:showUsers           forKey:KEY_SHOW_USERS];
    [coder encodeBool:showLabels          forKey:KEY_SHOW_LABELS];
}

@end
