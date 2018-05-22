//
//  RVReleaseGestureRecognizer.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/27/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  RVReleaseGestureRecognizer is a concrete subclass of UIGestureRecognizer that simply looks
 *  for the user releasing a touch in the view.  It is intended to be used with 
 *  RVPressGestureRecognizer to easily detect both the press and release.
 */
@interface RVReleaseGestureRecognizer : UIGestureRecognizer

@end
