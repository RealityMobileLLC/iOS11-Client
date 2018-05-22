//
//  RVPressGestureRecognizer.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/27/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  RVPressGestureRecognizer is a concrete subclass of UIGestureRecognizer that simply looks
 *  for the user touching the view.  It is intended to be used with RVReleaseGestureRecognizer
 *  to easily detect both the press and release.
 */
@interface RVPressGestureRecognizer : UIGestureRecognizer

@end
