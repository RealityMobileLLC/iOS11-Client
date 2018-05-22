//
//  MapConfiguration.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 5/13/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Serializable configuration settings for the MainMapViewController.
 */
@interface MapConfiguration : NSObject <NSCoding>

@property (nonatomic) BOOL isTrackingLocation;
@property (nonatomic) BOOL isCenteredOnCameras;
@property (nonatomic) BOOL showLabels;
@property (nonatomic) BOOL showFavorites;
@property (nonatomic) BOOL showTransmitters;
@property (nonatomic) BOOL showCameras;
@property (nonatomic) BOOL showScreencasts;
@property (nonatomic) BOOL showFiles;
@property (nonatomic) BOOL showMyVideos;
@property (nonatomic) BOOL showUsers;

@end
