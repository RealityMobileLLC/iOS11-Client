//
//  PanTiltZoomControlsView.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 5/17/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CameraInfoWrapper;


/**
 *  The HideControlsTimer protocol provides a mechanism for resetting a timer when a control
 *  is pressed.
 */
@protocol HideControlsTimer <NSObject>

/**
 *  Notifies the receiver that a control was pressed and the timer for hiding the controls 
 *  should be reset.
 */
- (void)resetControlsTimer;

@end


/**
 *  A PanTiltZoomControlsView object is a UIView that contains controls for sending Pan-Tilt-View
 *  commands to a camera.  The view's background is transparent so that it can be placed on top of 
 *  a UIImageView showing the current camera image.
 */
@interface PanTiltZoomControlsView : UIView

/**
 *  The camera being controlled.
 */
@property (nonatomic,strong) CameraInfoWrapper * camera;

/**
 *  The delegate to notify when a control is pressed.
 */
@property (nonatomic,weak) id <HideControlsTimer> hideControlsTimerDelegate;

/**
 *  Returns an initialized PantTiltZoomControlsView object.
 */
- (id)initWithFrame:(CGRect)frame;

@end
