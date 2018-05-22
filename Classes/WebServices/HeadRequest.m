//
//  HeadRequest.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "HeadRequest.h"
#import "WebService.h"


@implementation HeadRequest

@synthesize delegate;


- (id)initWithUrl:(NSURL *)url 
		 delegate:(id <HeadRequestDelegate>)headRequestDelegate;
{
	self = [super initService:nil withUrl:url];
	if (self != nil)
	{
		delegate = headRequestDelegate;
	}
	return self;
}

- (void)send
{
	[super headRequest];
}

- (void)didGetResponse:(NSData *)data orError:(NSError *)error
{
	// dispatch delegate callback asynchronously on the main thread
	dispatch_async(dispatch_get_main_queue(), 
				   ^{
					   [delegate headRequestDidGetResponseOrError:error];
				   });
}

@end
