//
//  CatalogService.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebService.h"
#import "WebServiceResponseHandler.h"


/**
 *  Delegate used by the CatalogService class to indicate when web services
 *  respond.
 */
@protocol CatalogServiceDelegate

@optional

/**
 *  Called when a GetAllCameras call completes.
 *
 *  @param cameras An array of CameraInfo objects returned by any of the GetXXXCameras services.
 *
 *  @param error   An error, if one occurred, or nil if the operation 
 *                 completed successfully.
 */
- (void)onGetCamerasResult:(NSArray *)cameras error:(NSError *)error;

@end


/**
 *  Responsible for managing RealityVision Catalog Service web service 
 *  requests.
 */
@interface CatalogService : WebService 

/**
 *  The delegate that gets notified when a web service responds.
 */
@property (weak) id <CatalogServiceDelegate> delegate;

/**
 *  Initializes a CatalogService object.
 *
 *  @param url      The base URL for RealityVision web services.
 *  @param delegate The delegate to notify when a web service responds.
 *
 *  @return An initialized CatalogService object or nil if the object
 *           could not be initialized.
 */
- (id)initWithUrl:(NSURL *)url andDelegate:(id <CatalogServiceDelegate>)delegate;

/**
 *  Initiates a Get All Cameras request.
 */
- (void)getAllCameras;

/**
 *  Initiates a Get Fixed Cameras request.
 */
- (void)getFixedCameras;

/**
 *  Initiates a Get Screencasts request.
 */
- (void)getScreencasts;

/**
 *  Initiates a Get Video Files request.
 */
- (void)getVideoFiles;

@end
