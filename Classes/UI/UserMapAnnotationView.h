//
//  UserMapAnnotationView.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/22/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MkAnnotationView.h>
#import "RealityVisionMapAnnotationView.h"

@class UserDevice;


/**
 *  An annotation view to display a RealityVision user on a map.  The icon used to
 *  display the source is based on the user's device state.
 */
@interface UserMapAnnotationView : RealityVisionMapAnnotationView

/**
 *  The annotation property returned as a UserDevice.
 */
@property (strong, nonatomic,readonly) UserDevice * userDevice;

/**
 *  Initializes a UserMapAnnotationView using the user as its annotation.
 *  
 *  @param userDevice The user object to associate with the new view.
 *  @param useCalloutAccessories If YES, adds left and right callout accessory buttons.
 *  @param reuseIdentifier If you plan to reuse the annotation view for similar types of 
 *                         annotations, pass a string to identify it. Although you can pass nil 
 *                         if you do not intend to reuse the view, reusing annotation views is 
 *                         generally recommended.
 */
-      (id)initWithUser:(UserDevice *)userDevice 
  andCalloutAccessories:(BOOL)useCalloutAccessories 
		reuseIdentifier:(NSString *)reuseIdentifier;

@end
