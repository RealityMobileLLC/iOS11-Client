//
//  UserStatusService.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/28/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "UserStatusService.h"
#import "ArrayHandler.h"
#import "DeviceHandler.h"
#import "GroupHandler.h"
#import "UserHandler.h"
#import "QueryString.h"



@implementation UserStatusService
{
	id <WebServiceResponseHandler> responseHandler;
}

@synthesize delegate;


#pragma mark - Initialization and cleanup

- (id)initWithUrl:(NSURL *)url andDelegate:(id <UserStatusServiceDelegate>)userStatusServiceDelegate
{
	self = [super initService:@"UserStatusService" withUrl:url];
	if (self != nil)
	{
		self.delegate = userStatusServiceDelegate;
	}
	return self;
}


#pragma mark - Public methods

- (void)getDeviceList
{
	responseHandler = [[ArrayHandler alloc] initWithElementName:@"Device" andParserClass:[DeviceHandler class]];
	[super getFromMethod:@"GetDeviceList" query:nil];
}


- (void)getGroups
{
	responseHandler = [[ArrayHandler alloc] initWithElementName:@"Group" andParserClass:[GroupHandler class]];
	[super getFromMethod:@"GetGroups" query:nil];
}


- (void)getSignedOnDevicesAndIncludeViewingSessions:(BOOL)includeViewingSessions
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"includeViewingSessions" boolValue:includeViewingSessions];
	responseHandler = [[ArrayHandler alloc] initWithElementName:@"Device" andParserClass:[DeviceHandler class]];
	[super getFromMethod:@"GetSignedOnDevices" query:query.query];
}


- (void)getSignedOnUsersAndIncludeViewingSessions:(BOOL)includeViewingSessions
{
	QueryString * query = [[QueryString alloc] init];
	[query append:@"includeViewingSessions" boolValue:includeViewingSessions];
	responseHandler = [[ArrayHandler alloc] initWithElementName:@"User" andParserClass:[UserHandler class]];
	[super getFromMethod:@"GetSignedOnUsers" query:query.query];
}


- (void)getUserList
{
	responseHandler = [[ArrayHandler alloc] initWithElementName:@"User" andParserClass:[UserHandler class]];
	[super getFromMethod:@"GetUserList" query:nil];
}


- (void)getValidRecipientGroups
{
	responseHandler = [[ArrayHandler alloc] initWithElementName:@"Group" andParserClass:[GroupHandler class]];
	[super getFromMethod:@"GetValidRecipientGroups" query:nil];
}


#pragma mark - WebService response callback

- (void)didGetResponse:(NSData *)data orError:(NSError *)error
{
	if (! [responseHandler isKindOfClass:[ArrayHandler class]])
		return;
	
	NSString * responseForElementName = [(ArrayHandler *)responseHandler elementName];
	if ([responseForElementName isEqualToString:@"Device"])
	{
		NSArray * deviceList = nil;
		
		if (error == nil)
		{
			deviceList = [responseHandler parseResponse:data];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onGetDeviceListResult:deviceList error:error];
					   });
	}
	else if ([responseForElementName isEqualToString:@"Group"])
	{
		NSArray * groupList = nil;
		
		if (error == nil)
		{
			groupList = [responseHandler parseResponse:data];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onGetGroupsResult:groupList error:error];
					   });
	}
	else if ([responseForElementName isEqualToString:@"User"])
	{
		NSArray * userList = nil;
		
		if (error == nil)
		{
			userList = [responseHandler parseResponse:data];
		}
		
		// dispatch delegate callback asynchronously on the main thread
		dispatch_async(dispatch_get_main_queue(), 
					   ^{
						   [delegate onGetUserListResult:userList error:error];
					   });
	}
}

@end
