//
//  CameraArchivesDataSource.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/12/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CameraDataSource.h"
#import "ClientTransaction.h"


/**
 *  Object used to asynchronously retrieve the list of RealityVision
 *  transmitting (roving) cameras.  When finished, the camera list is
 *  provided to the delegate.
 */
@interface CameraArchivesDataSource : CameraDataSource <ClientTransactionDelegate>

/**
 *  Initializes a CameraArchivesDataSource object.
 *
 *  @param delegate the delegate to notify when the cameras have been retrieved
 */
- (id)initWithCameraDelegate:(id <CameraDataSourceDelegate>)delegate;

@end
