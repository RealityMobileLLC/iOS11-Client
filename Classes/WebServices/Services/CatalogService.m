//
//  CatalogService.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CatalogService.h"
#import "ArrayHandler.h"
#import "CameraInfoHandler.h"


@implementation CatalogService

@synthesize delegate;


#pragma mark - Initialization and cleanup

- (id)initWithUrl:(NSURL *)url andDelegate:(id <CatalogServiceDelegate>)catalogServiceDelegate
{
	self = [super initService:@"CatalogStatusService" withUrl:url];
	if (self != nil)
	{
		delegate = catalogServiceDelegate;
	}
	return self;
}


#pragma mark - Public methods

- (void)getAllCameras;
{
	[super getFromMethod:@"GetAllCameras" query:nil];
}


- (void)getFixedCameras
{
	[super getFromMethod:@"GetFixedCameras" query:nil];
}


- (void)getScreencasts
{
	[super getFromMethod:@"GetScreencasts" query:nil];
}


- (void)getVideoFiles
{
	[super getFromMethod:@"GetVideoFiles" query:nil];
}


#pragma mark - WebService response callback

- (void)didGetResponse:(NSData *)data orError:(NSError *)error
{
	NSArray * cameras = nil;
	
	if (error == nil)
	{
		ArrayHandler * responseHandler = [[ArrayHandler alloc] initWithElementName:@"CameraInfo" 
																	andParserClass:[CameraInfoHandler class]];
		cameras = [responseHandler parseResponse:data];
	}
	
	// dispatch delegate callback asynchronously on the main thread
	dispatch_async(dispatch_get_main_queue(), 
				   ^{
					   [delegate onGetCamerasResult:cameras error:error];
				   });
}

@end
