//
//  RealityVisionMapAnnotationView.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/6/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MkAnnotationView.h>


/**
 *  An annotation view to display a RealityVision source on a map.  Each RealityVision source
 *  has an image and a name.  The static showSourceNames property determines whether the name
 *  is shown next to the image for ALL RealityVisionMapAnnotationViews.
 *  
 *  RealityVisionMapAnnotationViews are also updatable.  If the underlying source object's
 *  state has changed in a way that should affect its view on the map, the update method can
 *  be called to effect that change.
 *  
 *  Note that this class is intended to be abstract.  It implements the code for maintaining
 *  the showSourceNames state and for drawing the image and, optionally, name.  Descendent
 *  classes must implement the properties that return the image and name.
 */
@interface RealityVisionMapAnnotationView : MKAnnotationView

/**
 *  The image to be shown on the map.
 *  Must be implemented by subclass.
 */
@property (strong, nonatomic,readonly) UIImage * sourceImage;

/**
 *  The name to be shown on the map.
 *  Must be implemented by subclass.
 */
@property (strong, nonatomic,readonly) NSString * sourceName;

/**
 *  Called to indicate the underlying source object has changed and its map annotation view
 *  needs to be updated.
 *  
 *  The default implementation merely calls -(void)setNeedsDisplay.  If more needs to be done,
 *  the descendent classes should override and then call [super update].
 */
- (void)update;

/**
 *  Indicates whether names are displayed on the map.
 */
+ (BOOL)showSourceNames;

/**
 *  Specifies whether names are displayed on the map.
 */
+ (void)setShowSourceNames:(BOOL)showSourceNames;

@end
