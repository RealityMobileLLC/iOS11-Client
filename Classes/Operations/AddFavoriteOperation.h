//
//  AddFavoriteOperation.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/17/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ClientTransaction.h"

@class CameraInfoWrapper;
@class FavoriteEntry;


/**
 *  The AddFavoriteOperation class provides an implementation of NSOperation for sending an
 *  AddFavorite Client Transaction request to the server.  When finished, the addedFavorite
 *  property will contain the newly added FavoriteEntry object or the error property will
 *  contain the reason for it failed.
 */
@interface AddFavoriteOperation : NSOperation <ClientTransactionDelegate>

/**
 *  The camera to add as a favorite.
 */
@property (strong) CameraInfoWrapper * cameraToFavorite;

/**
 *  When the operation is finished, addedFavorite will contain the newly added FavoriteEntry,
 *  or nil if an error occurred.
 */
@property (readonly) FavoriteEntry * addedFavorite;

/**
 *  When the operation is finished but was not successful, error will contain the reason for
 *  the failure.
 */
@property (readonly,strong) NSError * error;

@end
