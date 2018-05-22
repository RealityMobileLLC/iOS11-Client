//
//  UpdatableMapAnnotation.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/27/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Protocol that defines the methods that a MKAnnotationView subclass must implement to
 *  allow it to be updated by the CameraMapViewDelegate.
 */
@protocol UpdatableMapAnnotation <NSObject>

- (void)update;

@end
