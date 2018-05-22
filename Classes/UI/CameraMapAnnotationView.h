//
//  CameraMapAnnotationView.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/13/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RealityVisionMapAnnotationView.h"

@class CameraInfoWrapper;


/**
 *  An annotation view to display a RealityVision video source on a map.  The icon used to
 *  display the source is based on the camera type and state.
 */
@interface CameraMapAnnotationView : RealityVisionMapAnnotationView

/**
 *  The annotation property returned as a CameraInfoWrapper.
 */
@property (strong, nonatomic,readonly) CameraInfoWrapper * camera;

/**
 *  Initializes a CameraMapAnnotationView using the camera as its annotation.
 *  
 *  @param camera The camera object to associate with the new view.
 *  @param useCalloutAccessories If YES, adds left and right callout accessory buttons.
 *  @param reuseIdentifier If you plan to reuse the annotation view for similar types of 
 *                         annotations, pass a string to identify it. Although you can pass nil 
 *                         if you do not intend to reuse the view, reusing annotation views is 
 *                         generally recommended.
 */
-    (id)initWithCamera:(CameraInfoWrapper *)camera 
  andCalloutAccessories:(BOOL)useCalloutAccessories 
		reuseIdentifier:(NSString *)reuseIdentifier;

@end
