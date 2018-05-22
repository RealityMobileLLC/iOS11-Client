//
//  CameraArchivesDataSource.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/12/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "CameraArchivesDataSource.h"
#import "ClientConfiguration.h"
#import "SystemUris.h"
#import "CameraInfo.h"
#import "CameraInfoWrapper.h"
#import "ConfigurationManager.h"
#import "Session.h"
#import "SessionResult.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CameraArchivesDataSource
{
	ClientTransaction * webRequest;
    BOOL                showFilteredResults;
    
	BOOL                hasMoreCameras;
	int                 totalCameras;
	int                 nextOffset;
    
    // @todo this really should be implemented by using separate data sources for filtered vs non-filtered
    BOOL                filteredHasMoreCameras;
    int                 filteredTotalCameras;
    int                 filteredNextOffset;
    NSString          * filteredSearchText;
}


- (id)initWithCameraDelegate:(id <CameraDataSourceDelegate>)myDelegate
{
	self = [super init];
	if (self != nil)
	{
		self.delegate = myDelegate;
	}
	return self;
}


- (void)dealloc
{
	webRequest.delegate = nil;
}


- (NSString *)title
{
	return NSLocalizedString(@"My Video History",@"Browse my video history title");
}


- (NSString *)loadingCamerasText
{
	return NSLocalizedString(@"Loading My Video History ...",@"Loading my video history");
}


- (NSString *)noCamerasText
{
	return NSLocalizedString(@"No Videos",@"No video history");
}


- (NSString *)searchPlaceholderText
{
	return NSLocalizedString(@"Search Comments",@"Search video history comments");
}


- (BOOL)supportsPaging
{
	return YES;
}


- (BOOL)hasMoreCameras
{
	return showFilteredResults ? filteredHasMoreCameras : hasMoreCameras;
}


- (void)setHasMoreCameras:(BOOL)newHasMoreCameras
{
	if (showFilteredResults)
	{
		filteredHasMoreCameras = newHasMoreCameras;
	}
	else
	{
		hasMoreCameras = newHasMoreCameras;
	}
}


- (int)totalCameras
{
	return showFilteredResults ? filteredTotalCameras : totalCameras;
}


- (void)setTotalCameras:(int)newTotalCameras
{
	if (showFilteredResults)
	{
		filteredTotalCameras = newTotalCameras;
	}
	else
	{
		totalCameras = newTotalCameras;
	}
}


- (int)nextOffset
{
	return showFilteredResults ? filteredNextOffset : nextOffset;
}


- (void)setNextOffset:(int)newNextOffset
{
	if (showFilteredResults)
	{
		filteredNextOffset = newNextOffset;
	}
	else
	{
		nextOffset = newNextOffset;
	}
}


- (void)getCameras
{
	DDLogVerbose(@"CameraArchivesDataSource getCameras");
	
	if (! isLoading)
	{
		isLoading = YES;
		showFilteredResults = NO;
		nextOffset = 0;
		[self searchVideoHistoryFor:@"null" fromOffset:self.nextOffset];
	}
}


- (void)getMoreCameras
{
	NSAssert(self.hasMoreCameras,@"No more cameras to retrieve");
	DDLogVerbose(@"CameraArchivesDataSource getMoreCameras");
	
	if (! isLoading)
	{
		isLoading = YES;
		NSString * searchText = showFilteredResults ? filteredSearchText : @"null";
		[self searchVideoHistoryFor:searchText fromOffset:nextOffset];
	}
}


- (void)searchVideoHistoryFor:(NSString *)text fromOffset:(int)offset
{
	NSAssert(isLoading,@"isLoading flag must be set before this method is called");
	
	NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
	webRequest = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
	webRequest.delegate = self;
	[webRequest searchVideoHistoryFor:text offset:offset count:20];
}


- (void)refresh
{
	// archives aren't cached, so just call getCameras again to get new list
	[self getCameras];
}


- (void)cancel
{
	if (isLoading)
	{
		isLoading = NO;
		webRequest.delegate = nil;
		[webRequest cancel];
		webRequest = nil;
	}
}


- (BOOL)filterCamerasForSearchText:(NSString *)searchText
{
	// if we have existing search results, clear them when user starts entering new search text
	BOOL newSearchText = [filteredCameras count] > 0;
	
	if (newSearchText)
	{
		[filteredCameras removeAllObjects];
	}
	
	return newSearchText;
}


- (void)searchForText:(NSString *)searchText
{
	if (! isLoading)
	{
		isLoading = YES;
		showFilteredResults = YES;
		filteredSearchText = searchText;
		nextOffset = 0;
		[self searchVideoHistoryFor:searchText fromOffset:self.nextOffset];
	}
}


- (void)endSearch
{
	[self cancel];
	showFilteredResults = NO;
	[filteredCameras removeAllObjects];
}


- (void)onVideoHistoryResult:(SessionResult *)sessions error:(NSError *)error
{
	DDLogInfo(@"CameraArchivesDataSource onVideoHistoryResult");
	isLoading = NO;
	
	if ((sessions == nil) && (error == nil))
	{
		error = [RvError rvErrorWithLocalizedDescription:@"Did not receive the list of video sessions."];
	}
	
	if (error != nil)
	{
		[self.delegate cameraListDidGetError:error];
		webRequest.delegate = nil;
		webRequest = nil;
		return;
	}
	
	NSMutableArray * __strong * cameraArray = showFilteredResults ? &filteredCameras : &cameras;
    
	// if we are getting a fresh list of cameras, remove cameras from old list
	if (nextOffset == 0)
	{
		if (*cameraArray == nil)
		{
			*cameraArray = [[NSMutableArray alloc] initWithCapacity:[sessions.sessions count]];
		}
		else
		{
			[*cameraArray removeAllObjects];
		}
	}
	
	for (Session * session in sessions.sessions)
	{
		CameraInfoWrapper * camera = [[CameraInfoWrapper alloc] initWithSession:session];
		[*cameraArray addObject:camera];
	}
	
	[self setHasMoreCameras:sessions.hasMoreResults];
	[self setTotalCameras:sessions.totalResults];
	nextOffset += [sessions.sessions count];
	
	[self.delegate cameraListUpdatedForDataSource:self];
	
	webRequest.delegate = nil;
	webRequest = nil;
}

@end
