//
//  MotionJpegMiniPlayerView.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/7/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "MapObject.h"
#import "MotionJpegStream.h"

@class MotionJpegMiniPlayerView;


/**
 *  Protocol used by the MotionJpegMiniPlayerView to notify a delegate that a video player should 
 *  be dismissed.
 */
@protocol MotionJpegMiniPlayerViewDelegate <NSObject>

/**
 *  Called when the video player should be dismissed.
 */
- (void)dismissVideoPlayer:(MotionJpegMiniPlayerView *)player;

@end


/**
 *  View used to display a Motion-JPEG feed on a map.
 */
@interface MotionJpegMiniPlayerView : UIView <MotionJpegStreamDelegate>

/**
 *  The delegate to notify when the player should be dismissed.
 */
@property (nonatomic,weak) id <MotionJpegMiniPlayerViewDelegate> delegate;

/**
 *  Camera whose feed is being displayed.
 */
@property (nonatomic,readonly,strong) CameraInfoWrapper * camera;

/**
 *  Map object used to anchor this view.
 */
@property (nonatomic,readonly,strong) NSObject<MapObject> * viewer;

/**
 *  Map annotation view used to show this view.
 */
@property (nonatomic,readonly,weak) MKAnnotationView * mapAnnotationView;

/**
 *  Initializes and returns a MotionJpegMiniPlayerView object.
 *  
 *  @param camera         Video feed to display.
 *  @param viewer         RealityVision map object used to anchor this view.
 *  @param annotationView Map annotation view associated with this view. May be nil.
 *  @param map            Map view on which receiver will be displayed.
 *
 *  @return An initialized MotionJpegMiniPlayerView object or nil if the object could not be initialized.
 */
- (id)initWithCamera:(CameraInfoWrapper *)camera
		   forViewer:(NSObject<MapObject> *)viewer
   mapAnnotationView:(MKAnnotationView *)annotationView
			   onMap:(MKMapView *)map;

/**
 *  Updates the view's frame to match the viewer's location on the map.
 */
- (void)updateLocation;

@end
