//
//  UserDataSource.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/21/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "UserDataSource.h"
#import "ConfigurationManager.h"
#import "SystemUris.h"
#import "Device.h"
#import "User.h"
#import "UserDevice.h"
#import "UserStatusService.h"
#import "RealityVisionClient.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation UserDataSource
{
	UserStatusService * webService;
	NSArray           * theDevices;
    BOOL                isLoading;
}

@synthesize delegate;
@synthesize hidden;


#pragma mark - Initialization and cleanup

- (id)init
{
    self = [super init];
    if (self != nil) 
    {
        isLoading = NO;
        hidden = NO;
    }
    
    return self;
}


#pragma mark - Public methods

- (NSArray *)users
{
    // @todo implement users property
    return nil;
}

- (NSArray *)userDevices
{
    return theDevices;
}

- (NSArray *)userDevicesTransmitting
{
    NSPredicate * isTransmitting = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) 
                                                                   {
                                                                       return ((UserDevice *)evaluatedObject).device.isCamera;
                                                                   }];
    return [theDevices filteredArrayUsingPredicate:isTransmitting];
}

- (NSArray *)userDevicesNotTransmitting
{
    NSPredicate * isNotTransmitting = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) 
                                                                      {
                                                                        return ! ((UserDevice *)evaluatedObject).device.isCamera;
                                                                      }];
    return [theDevices filteredArrayUsingPredicate:isNotTransmitting];
}

- (void)getUsers
{
	if (self.users != nil)
	{
		[self notifyDelegateUserDevicesAdded:nil userDevicesRemoved:nil userDevicesUpdated:nil];
	}
	else 
	{
		[self refresh];
	}
}

- (void)refresh
{
	if (! isLoading)
	{
		isLoading = YES;
		NSURL * userStatusUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
		webService = [[UserStatusService alloc] initWithUrl:userStatusUrl 
                                                      andDelegate:self];
		[webService getSignedOnDevicesAndIncludeViewingSessions:YES];
	}
}

- (void)cancel
{
	if (isLoading)
	{
		isLoading = NO;
		[webService cancel];
		webService = nil;
	}
}

- (void)reset
{
	[self cancel];
	webService = nil;
	theDevices = nil;
}


#pragma mark - UserStatusServiceDelegate methods

- (void)onGetDeviceListResult:(NSArray *)devices error:(NSError *)error
{
	if (isLoading)
	{
		DDLogInfo(@"UserDataSource onGetDeviceListResult");
		isLoading = NO;
		
		if ((devices == nil) && (error == nil))
		{
			error = [RvError rvErrorWithLocalizedDescription:@"Did not receive the list of users from the User Status Service."];
		}
		
		if (error != nil)
		{
			[self.delegate userListDidGetError:error];
			return;
		}
		
        NSMutableArray * allDevices     = [NSMutableArray arrayWithCapacity:[devices count]];
		NSMutableArray * devicesAdded   = [NSMutableArray arrayWithCapacity:[devices count]];
		NSMutableArray * devicesRemoved = [NSMutableArray arrayWithCapacity:[devices count]];
		NSMutableArray * devicesUpdated = [NSMutableArray arrayWithCapacity:[devices count]];
        
        for (Device * device in devices)
        {
            if (! [device.deviceId isEqualToString:[RealityVisionClient instance].deviceId])
            {
                [allDevices addObject:[[UserDevice alloc] initWithDevice:device]];
            }
        }
        
        theDevices = [self updateDevices:theDevices 
							   fromArray:allDevices
							devicesAdded:devicesAdded 
						  devicesRemoved:devicesRemoved 
						  devicesUpdated:devicesUpdated];
		
        // update the displayable list of cameras for this data source
		[self notifyDelegateUserDevicesAdded:devicesAdded 
                          userDevicesRemoved:devicesRemoved 
                          userDevicesUpdated:devicesUpdated];
		webService = nil;
	}
}

- (NSArray *)updateDevices:(NSArray *)oldList 
                 fromArray:(NSArray *)newList
              devicesAdded:(NSMutableArray *)devicesAdded 
            devicesRemoved:(NSMutableArray *)devicesRemoved
			devicesUpdated:(NSMutableArray *)devicesUpdated
{
	NSMutableArray * mergedList = [NSMutableArray arrayWithCapacity:[newList count]];
    
    if (oldList == nil)
    {
        // handle special case where there is no old list
        [devicesAdded addObjectsFromArray:newList];
        [mergedList addObjectsFromArray:newList];
        return mergedList;
    }
	
	NSEnumerator * newEnumerator = [newList objectEnumerator];
	NSEnumerator * oldEnumerator = [oldList objectEnumerator];
	
	UserDevice * newItem = [newEnumerator nextObject];
	UserDevice * oldItem = [oldEnumerator nextObject];
	
	// copy items until we reach the end of either list
	while ((newItem != nil) && (oldItem != nil))
	{
		if ([newItem isEqual:oldItem])
		{
			// item is in both lists so update it and add it to the new merged list
            if ([oldItem updateDeviceInfoFrom:newItem])
			{
				[devicesUpdated addObject:oldItem];
			}
			
			[mergedList addObject:oldItem];
			newItem = [newEnumerator nextObject];
			oldItem = [oldEnumerator nextObject];
		}
		else if (! [oldList containsObject:newItem])
		{
			// item is in new list but not old list so add it
			[devicesAdded addObject:newItem];
			[mergedList addObject:newItem];
			newItem = [newEnumerator nextObject];
		}
		else
		{
			// item is in old list but not new list so skip it
			[devicesRemoved addObject:oldItem];
			oldItem = [oldEnumerator nextObject];
		}
	}
    
	// add remaining items from new list that weren't in old list
	while (newItem != nil)
	{
        [devicesAdded addObject:newItem];
		[mergedList addObject:newItem];
		newItem = [newEnumerator nextObject];
	}
    
    // remove remaining items from old list that aren't in new list
    while (oldItem != nil)
    {
        [devicesRemoved addObject:oldItem];
        oldItem = [oldEnumerator nextObject];
    }
	
	return mergedList;
}

- (void)notifyDelegateUserDevicesAdded:(NSArray *)devicesAdded 
                    userDevicesRemoved:(NSArray *)devicesRemoved
                    userDevicesUpdated:(NSArray *)devicesUpdated
{
    if ([self.delegate respondsToSelector:@selector(userListUpdatedForDataSource:)])
    {
        [self.delegate userListUpdatedForDataSource:self];
    }
	
	if ((devicesRemoved != nil) && ([devicesRemoved count] > 0) && 
        ([self.delegate respondsToSelector:@selector(dataSource:removedUsers:)]))
	{
		[self.delegate dataSource:self removedUsers:devicesRemoved];
	}
	
	if ((devicesAdded != nil) && ([devicesAdded count] > 0) &&
        ([self.delegate respondsToSelector:@selector(dataSource:addedUsers:)]))
	{
		[self.delegate dataSource:self addedUsers:devicesAdded];
	}
	
	if ((devicesUpdated != nil) && ([devicesUpdated count] > 0) &&
		([self.delegate respondsToSelector:@selector(dataSource:updatedUsers:)]))
	{
		[self.delegate dataSource:self updatedUsers:devicesUpdated];
	}
}

@end
