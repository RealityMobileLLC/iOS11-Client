//
//  AddFavoriteOperation.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/17/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import "AddFavoriteOperation.h"
#import "CameraInfoWrapper.h"
#import "Command.h"
#import "FavoriteEntry.h"
#import "ConfigurationManager.h"
#import "FavoritesManager.h"
#import "SystemUris.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation AddFavoriteOperation
{
	ClientTransaction * clientTransaction;
	BOOL executing;
	BOOL finished;
}

@synthesize cameraToFavorite;
@synthesize addedFavorite;
@synthesize error = _error;


#pragma mark - Initialization and cleanup

- (id)init 
{
    self = [super init];
    if (self != nil) 
	{
        executing = NO;
        finished = NO;
    }
    return self;
}



#pragma mark - NSOperation methods

- (BOOL)isConcurrent 
{
	return YES;
}

- (BOOL)isExecuting 
{
	return executing;
}

- (BOOL)isFinished 
{
	return finished;
}

- (void)completeOperation
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    executing = NO;
    finished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)doAddFavorite 
{
	Command * viewCommand = self.cameraToFavorite.viewCameraCommandForFavorite;
	NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
	clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
	clientTransaction.delegate = self;
	[clientTransaction addFavoriteCommand:viewCommand withCaption:self.cameraToFavorite.name];
}

- (void)start 
{
	NSAssert(self.cameraToFavorite,@"Must set cameraToFavorite before starting AddFavoriteOperation");
	
	// must be run on the main thread
	if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start)
                               withObject:nil waitUntilDone:NO];
        return;
    }
	
	if ([self isCancelled])
	{
		[self willChangeValueForKey:@"isFinished"];
		finished = YES;
		[self didChangeValueForKey:@"isFinished"];
		return;
	}
	
	[self willChangeValueForKey:@"isExecuting"];
	executing = YES;
	[self doAddFavorite];
	[self didChangeValueForKey:@"isExecuting"];
}


#pragma mark - ClientTransactionDelegate methods

- (void)onAddFavoriteResult:(NSNumber *)favoriteId error:(NSError *)error
{
	DDLogVerbose(@"AddFavoriteOperation onAddFavoriteResult");
	
	if ([self isCancelled])
	{
		DDLogVerbose(@"Operation cancelled");
		[self completeOperation];
		return;
	}
	
	if ((favoriteId == nil) && (error == nil))
	{
		error = [RvError rvErrorWithLocalizedDescription:@"Did not receive the favorite ID."];
	}
	
	if (error != nil)
	{
		DDLogError([error localizedDescription]);
		_error = error;
		[self completeOperation];
		return;
	}
	
	addedFavorite = [[FavoriteEntry alloc] init];
	addedFavorite.favoriteId = [favoriteId intValue];
	addedFavorite.caption = self.cameraToFavorite.name;
	addedFavorite.openCommand = self.cameraToFavorite.viewCameraCommandForFavorite;
    [self completeOperation];
}

@end
