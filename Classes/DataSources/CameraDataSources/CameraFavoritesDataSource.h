//
//  CameraFavoritesDataSource.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CameraDataSource.h"
#import "FavoritesManager.h"


/**
 *  Object used to asynchronously retrieve the user's list of favorite cameras.  
 *  When finished, the camera list is provided to the delegate.
 */
@interface CameraFavoritesDataSource : CameraDataSource <FavoritesObserver>

/**
 *  Initializes a CameraFavoritesDataSource object.
 *
 *  @param delegate the delegate to notify when the cameras have been retrieved
 */
- (id)initWithCameraDelegate:(id <CameraDataSourceDelegate>)delegate;

@end
