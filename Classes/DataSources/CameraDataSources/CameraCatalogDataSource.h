//
//  CameraCatalogDataSource.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CameraDataSource.h"
#import "CatalogService.h"

@class BrowseTreeNode;


/**
 *  Object used to asynchronously retrieve the list of cameras from the
 *  RealityVision Catalog Service.  When finished, the camera list is
 *  provided to the delegate.
 */
@interface CameraCatalogDataSource : CameraDataSource <CatalogServiceDelegate>

/**
 *  Initializes a CameraCatalogDataSource object.
 *
 *  @param delegate The delegate to notify when the cameras have been retrieved.
 */
- (id)initWithCameraDelegate:(id <CameraDataSourceDelegate>)delegate;

/**
 *  Initializes a CameraCatalogDataSource with an existing BrowseTreeNode.
 *  
 *  @param browseTree Initialized camera browse tree.
 *  @param delegate   The delegate to notify when the cameras have been retrieved.
 */
- (id)initWithBrowseTree:(BrowseTreeNode *)browseTree andDelegate:(id <CameraDataSourceDelegate>)delegate;

@end
