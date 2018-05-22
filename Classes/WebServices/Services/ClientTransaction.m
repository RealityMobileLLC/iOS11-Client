//
//  ClientTransaction.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ClientTransaction.h"
#import "XmlFactory.h"
#import "QueryString.h"
#import "ClientStatus.h"
#import "Command.h"
#import "DirectiveType.h"
#import "GpsLockStatus.h"
#import "Session.h"
#import "CommandHistoryResult.h"
#import "SessionResult.h"
#import "ArrayHandler.h"
#import "AddFavoriteResultHandler.h"
#import "CommandCountResultHandler.h"
#import "CommandHandler.h"
#import "CommandHistoryResultHandler.h"
#import "FavoriteEntryHandler.h"
#import "SessionHandler.h"
#import "SessionResultHandler.h"
#import "TransmitterInfoHandler.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation ClientTransaction
{
	id <WebServiceResponseHandler> responseHandler;
    BOOL isAddFrameComment;
    BOOL isAddSessionComment;
}

@synthesize delegate;


#pragma mark - Initialization and cleanup

- (id)initWithUrl:(NSURL *)url
{
	self = [super initService:@"ClientTransaction" withUrl:url];
    if (self != nil)
    {
        isAddSessionComment = NO;
        isAddFrameComment = NO;
    }
	return self;
}


#pragma mark - Public methods

- (void)acceptCommand:(NSString *)commandId forDevice:(NSString *)deviceId withResponse:(NSString *)response 
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"commandId" stringValue:commandId];
	[query append:@"deviceId"  stringValue:deviceId];
	[query append:@"response"  stringValue:response];
	
	responseHandler = nil;
	[super getFromMethod:@"AcceptCommand" query:query.query];
}

- (void)addComment:(NSString *)comment toLastSessionforDevice:(NSString *)deviceId
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"deviceId" stringValue:deviceId];
	[query append:@"comment"  stringValue:comment];
	
	// this method returns a response but we're ignoring it for now
	responseHandler = nil;
	[super getFromMethod:@"AddCommentToLastSession" query:query.query];
}

- (void)addComment:(NSString *)comment forSession:(int)sessionId  
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"sessionId" intValue:sessionId];
	[query append:@"comment"   stringValue:comment];
	
	// this method returns a response but we only acknowledge receipt; we don't process it
	responseHandler = nil;
    isAddSessionComment = YES;
	[super getFromMethod:@"AddSessionComment" query:query.query];
}

- (void)addComment:(NSString *)comment forSession:(int)sessionId andFrame:(int)frameId 
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"sessionId" intValue:sessionId];
	[query append:@"frameId"   intValue:frameId];
	[query append:@"comment"   stringValue:comment];
	
	// this method returns a response but we only acknowledge receipt; we don't process it
	responseHandler = nil;
    isAddFrameComment = YES;
	[super getFromMethod:@"AddSessionFrameComment" query:query.query];
}

- (void)addFavoriteCommand:(Command *)command withCaption:(NSString *)caption
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"caption"     stringValue:caption];
	[query append:@"openCommand" stringValue:@""];
	
	NSData * data = [XmlFactory dataWithCommandElementNamed:@"openCommand" command:command];
	
	responseHandler = [[AddFavoriteResultHandler alloc] init];
	[super postToMethod:@"AddFavorite" query:query.query data:data];
}

- (void)addFavoriteEntries:(ArrayOfFavoriteEntry *)entries
{
	// not implemented since not used by client
	[self doesNotRecognizeSelector:_cmd];
}

- (void)deleteFavorite:(int)favoriteId 
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"favoriteId" intValue:favoriteId];
	
	responseHandler = nil;
	[super getFromMethod:@"DeleteFavorite" query:query.query];
}

- (void)deleteFavorites:(NSArray *)favoriteIds
{
	// not implemented since not used by client
	[self doesNotRecognizeSelector:_cmd];
}

- (void)dismissCommand:(NSString *)commandId forDevice:(NSString *)deviceId
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"commandId" stringValue:commandId];
	[query append:@"deviceId"  stringValue:deviceId];
	
	responseHandler = nil;
	[super getFromMethod:@"DismissCommand" query:query.query];
}

- (void)getCommandForDevice:(NSString *)deviceId 
{
	// not implemented since iPhone is not using CNS
	[self doesNotRecognizeSelector:_cmd];
}

- (void)getCommandById:(NSString *)commandId
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"commandId" stringValue:commandId];
	
	responseHandler = [[CommandHandler alloc] init];
	[super getFromMethod:@"GetCommandByID" query:query.query];
}

- (void)getDeviceInfoForDevice:(NSString *)deviceId 
{
	// not implemented since not used by client
	[self doesNotRecognizeSelector:_cmd];
}

- (void)getFavorites
{
	responseHandler = [[ArrayHandler alloc] initWithElementName:@"FavoriteEntry" 
												 andParserClass:[FavoriteEntryHandler class]];
	[super getFromMethod:@"GetFavorites" query:nil];
}

- (void)getNewHistoryCount
{
	// not implemented since iPhone is not using CNS
	[self doesNotRecognizeSelector:_cmd];
}

- (void)getReceivedCommandsAfterCommand:(NSString *)commandId count:(int)count
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"commandId" stringValue:commandId];
	[query append:@"count" intValue:count];
	
	responseHandler = [[CommandHistoryResultHandler alloc] init];
	[super getFromMethod:@"GetReceivedCommands" query:query.query];
}

- (void)getSentCommandsOfType:(DirectiveType *)directiveType 
                 afterCommand:(NSString *)commandId 
                        count:(int)count
{
	QueryString * query = [[QueryString alloc] init];
    [query append:@"commandType" intValue:directiveType.value];
	[query append:@"commandId" stringValue:commandId];
	[query append:@"count" intValue:count];
	
	responseHandler = [[CommandHistoryResultHandler alloc] init];
	[super getFromMethod:@"GetSentCommandsOfType" query:query.query];
}

- (void)getSession:(int)sessionId
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"sessionId" intValue:sessionId];
	
	responseHandler = [[SessionHandler alloc] init];
	[super getFromMethod:@"GetSession" query:query.query];
}

- (void)getTransmitters
{
	responseHandler = [[ArrayHandler alloc] initWithElementName:@"TransmitterInfo" andParserClass:[TransmitterInfoHandler class]];
	[super getFromMethod:@"GetTransmitters" query:nil];
}

- (void)getUnreadCommandCount
{
	responseHandler = [[CommandCountResultHandler alloc] init];
	[super getFromMethod:@"GetUnreadCommandCount" query:nil];
}

- (void)ping
{
	// not implemented since not used by client
	[self doesNotRecognizeSelector:_cmd];
}

- (void)postCapabilities:(NSDictionary *)capabilities forDevice:(NSString *)deviceId
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"deviceId"     stringValue:deviceId];
	[query append:@"capabilities" stringValue:@""];
	
	NSData * data = [XmlFactory dataWithArrayOfNameValueElementNamed:@"capabilities" dictionary:capabilities];

	responseHandler = nil;
	[super postToMethod:@"PostCapabilities" query:query.query data:data];
}

- (void)postGpsLocation:(NSString *)nmeaString forDevice:(NSString *)deviceId
{
	// not implemented since not used by client
	[self doesNotRecognizeSelector:_cmd];
}

- (void)postGpsOn:(BOOL)gpsIsOn 
	   lockStatus:(GpsLockStatus *)lockStatus 
			 nmea:(NSString *)nmeaString 
		forDevice:(NSString *)deviceId
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"deviceId"      stringValue:deviceId];
	[query append:@"isGpsOn"       boolValue:gpsIsOn];
	[query append:@"gpsLockStatus" stringValue:[lockStatus stringValue]];
	[query append:@"rawGpgga"      stringValue:nmeaString];
	
	responseHandler = nil;
	[super getFromMethod:@"PostGpsStatus" query:query.query];
}

- (void)postStatus:(ClientStatus *)status forDevice:(NSString *)deviceId
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"deviceId" stringValue:deviceId];
	[query append:@"status"   stringValue:[status stringValue]];
	
	responseHandler = nil;
	[super getFromMethod:@"PostStatus" query:query.query];
}

- (void)receivedCommand:(NSString *)commandId forDevice:(NSString *)deviceId 
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"commandId" stringValue:commandId];
	[query append:@"deviceId"  stringValue:deviceId];
	
	responseHandler = nil;
	[super getFromMethod:@"ReceivedCommand" query:query.query];
}

- (void)receivedNewHistoryCount
{
	// not implemented since iPhone is not using CNS
	[self doesNotRecognizeSelector:_cmd];
}

- (void)searchVideoHistoryFor:(NSString *)text offset:(int)offset count:(int)count
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"searchText" stringValue:text];
	[query append:@"offset"     intValue:offset];
	[query append:@"count"      intValue:count];
	
	responseHandler = [[SessionResultHandler alloc] init];
	[super getFromMethod:@"SearchVideoHistory" query:query.query];
}

- (void)updateConnectionTimeForDevice:(NSString *)deviceId
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"deviceId" stringValue:deviceId];
	
	responseHandler = nil;
	[super getFromMethod:@"UpdateConnectionTime" query:query.query];
}

- (void)updateFavorite:(int)favoriteId withCommand:(Command *)command andCaption:(NSString *)caption 
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"favoriteId"  intValue:favoriteId];
	[query append:@"caption"     stringValue:caption];
	[query append:@"openCommand" stringValue:@""];
	
	NSData * data = [XmlFactory dataWithCommandElementNamed:@"openCommand" command:command];
	
	responseHandler = nil;
	[super postToMethod:@"UpdateFavorite" query:query.query data:data];
}

- (void)waitForCommandForDevice:(NSString *)deviceId 
{
	// not implemented since iPhone is not using CNS
	[self doesNotRecognizeSelector:_cmd];
}


#pragma mark - WebService response callback

- (void)didGetResponse:(NSData *)data orError:(NSError *)error
{
	if (responseHandler == nil)
	{
		// no response expected so just log error, if any
		if (error != nil)
		{
			DDLogWarn(@"ClientTransaction error response: %@", error);
		}
        
        if (isAddSessionComment || isAddFrameComment)
        {
            // dispatch delegate callback asynchronously on the main thread
            dispatch_async(dispatch_get_main_queue(), 
                           ^{
                               [delegate onAddComment:error fromClientTransaction:self];
                           });
        }
	}
	else if ([responseHandler isKindOfClass:[CommandHistoryResultHandler class]])
	{
		CommandHistoryResult * commandHistory = nil;
		
		if (error == nil)
		{
			commandHistory = [responseHandler parseResponse:data];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onCommandHistoryResult:commandHistory error:error];
					   });
	}
    else if ([responseHandler isKindOfClass:[SessionHandler class]])
    {
        Session * session = nil;
        
        if (error == nil)
        {
            session = [responseHandler parseResponse:data];
        }
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onGetSessionResult:session error:error];
					   });
    }
	else if ([responseHandler isKindOfClass:[SessionResultHandler class]])
	{
		SessionResult * videoHistory = nil;
		
		if (error == nil)
		{
			videoHistory = [responseHandler parseResponse:data];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onVideoHistoryResult:videoHistory error:error];
					   });
	}
	else if ([responseHandler isKindOfClass:[AddFavoriteResultHandler class]])
	{
		NSNumber * favoriteId = nil;
		
		if (error == nil)
		{
			favoriteId = [responseHandler parseResponse:data];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onAddFavoriteResult:favoriteId error:error];
					   });
	}
	else if ([responseHandler isKindOfClass:[ArrayHandler class]] && 
			 [[(ArrayHandler *)responseHandler elementName] isEqualToString:@"FavoriteEntry"])
	{
		NSArray * favorites = nil;
		
		if (error == nil)
		{
			favorites = [responseHandler parseResponse:data];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onGetFavoritesResult:favorites error:error];
					   });
	}
	else if ([responseHandler isKindOfClass:[ArrayHandler class]] && 
			 [[(ArrayHandler *)responseHandler elementName] isEqualToString:@"TransmitterInfo"])
	{
		NSArray * transmitters = nil;
		
		if (error == nil)
		{
			transmitters = [responseHandler parseResponse:data];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onGetTransmittersResult:transmitters error:error];
					   });
	}
	else if ([responseHandler isKindOfClass:[CommandCountResultHandler class]])
	{
		NSNumber * commandCount = nil;
		
		if (error == nil)
		{
			commandCount = [responseHandler parseResponse:data];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onGetUnreadCommandCountResult:commandCount error:error];
					   });
	}
	else if ([responseHandler isKindOfClass:[CommandHandler class]])
	{
		Command * command = nil;
		
		if (error == nil)
		{
			command = [responseHandler parseResponse:data];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onGetCommandResult:command error:error];
					   });
	}
}

@end
