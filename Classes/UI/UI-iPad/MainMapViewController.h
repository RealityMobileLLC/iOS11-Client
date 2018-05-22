//
//  MainMapViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MotionJpegMiniPlayerView.h"
#import "BrowseCameraCategory.h"
#import "CameraDataSource.h"
#import "UserDataSource.h"
#import "CameraSideMapViewDelegate.h"
#import "RecipientSelectionViewController.h"
#import "ViewedFeedsViewController.h"
#import "PttChannelSelectViewController.h"
#import "RootViewController.h"

#define RV_CAMERA_FILTER_INCLUDES_FILES_AND_SCREENCASTS

@class CameraCatalogDataSource;
@class CameraFilesDataSource;
@class CameraScreencastsDataSource;
@class CameraFavoritesDataSource;
@class CameraTransmittersDataSource;


/**
 *  View Controller for RealityVision's main map of camera locations.
 *
 *  This is the root view controller for the iPad.
 */
@interface MainMapViewController : RootViewController < CameraDataSourceDelegate, 
                                                        UserDataSourceDelegate,
                                                        MotionJpegMiniPlayerViewDelegate,
                                                        VideoSharingDelegate,
                                                        ViewedFeedsDelegate,
                                                        PttChannelSelectionDelegate,
                                                        UIPopoverControllerDelegate, 
                                                        UIGestureRecognizerDelegate,
                                                        //UISplitViewControllerDelegate,
                                                        MKMapViewDelegate >

/**
 *  Shows or hides users.
 */
@property (nonatomic) BOOL showUsers;

/**
 *  An auxiliary mapview delegate that should get updates from all data sources (users and cameras).
 */
@property (nonatomic,weak) CameraSideMapViewDelegate * auxiliaryMapDelegate;

/**
 *  Shows or hides cameras of the given category.
 *  
 *  @param category Category of cameras to show or hide.
 *  @param show YES to show cameras or NO to hide them.
 */
- (void)filterCamerasOfType:(BrowseCameraCategory)category show:(BOOL)show;

/**
 *  Gets the data source for cameras of the given category.
 *  
 *  @param category Category identifying desired data source.
 *  @return Camera data source
 */
- (CameraDataSource *)cameraDataSourceForCategory:(BrowseCameraCategory)category;

/**
 *  Returns an array containing all of the MapObjects representing users on the map.
 */
- (NSArray *)userMapObjects;

/**
 *  Returns an array containing all of the MapObjects representing cameras on the map.
 */
- (NSArray *)cameraMapObjects;

/**
 *  Returns an array containing all of the MapObjects representing screencasts on the map.
 */
- (NSArray *)screencastMapObjects;

/**
 *  Returns an array containing all of the MapObjects representing video files on the map.
 */
- (NSArray *)videoFileMapObjects;


// Interface Builder outlets
@property (nonatomic,weak) IBOutlet MKMapView * mapView;

@end
