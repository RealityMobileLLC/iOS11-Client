//
//  UserDataSource.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/21/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserStatusService.h"

@class UserDataSource;


/**
 *  Protocol used to get the list of users returned by a UserDataSource.
 *  
 *  Classes that implement this protocol will generally choose to implement
 *  either userListUpdatedForDataSource: or both dataSource:addedUsers: and
 *  dataSource:removedUsers:.
 *
 *  When implementing userListUpdatedForDataSource:, the recipient must get
 *  the new list of users from the data source.  This method is called 
 *  whenever the getUsers: method successfully receives new user data from
 *  a web service, even if the list of users received is the same as the
 *  list of users the data source already had.
 *  
 *  When implementing dataSource:addedUsers:, dataSource:removedUsers:, 
 *  and dataSource:updatedUsers:, the recipient is provided the list of changed 
 *  users.  These methods are only called when the list of users returned 
 *  from a web service has added, removed, or updated users from the list the 
 *  data source already had.
 */
@protocol UserDataSourceDelegate <NSObject>

@optional

/**
 *  Called when the UserDataSource has updated data.
 *  
 *  @param dataSource The data source that has an updated list of users.
 */
- (void)userListUpdatedForDataSource:(UserDataSource *)dataSource;

/**
 *  Called when the UserDataSource has added new users.
 *  
 *  @param dataSource The data source that has an updated list of users.
 *  @param users The list of users that have been added.
 */
- (void)dataSource:(UserDataSource *)dataSource addedUsers:(NSArray *)users;

/**
 *  Called when the UserDataSource has removed users.
 *  
 *  @param dataSource The data source that has an updated list of users.
 *  @param users The list of users that have been removed.
 */
- (void)dataSource:(UserDataSource *)dataSource removedUsers:(NSArray *)users;

/**
 *  Called when the UserDataSource has users with map properties that have been updated.
 *  
 *  @param dataSource The data source that has an updated list of users.
 *  @param users The list of users that have been updated.
 */
- (void)dataSource:(UserDataSource *)dataSource updatedUsers:(NSArray *)users;

/**
 *  Called when the UserDataSource has an error to report.
 *
 *  @param error The error that prevented the user list from being downloaded,
 *               or nil if no error occurred.
 */
- (void)userListDidGetError:(NSError *)error;

@end


/**
 *  An abstract class used to define the interface for asynchronously
 *  retrieving a list of users and providing the list to a delegate.
 *
 *  This class should never be instantiated directly.
 */
@interface UserDataSource : NSObject <UserStatusServiceDelegate>

/**
 *  Delegate that will be notified when the list of users has been
 *  retrieved or an error has occurred.
 */
@property (nonatomic,weak) id <UserDataSourceDelegate> delegate;

/**
 *  The list of all signed on users.
 */
@property (strong, nonatomic,readonly) NSArray * users;

/**
 *  The list of all signed on user devices.
 */
@property (strong, nonatomic,readonly) NSArray * userDevices;

/**
 *  The list of all currently transmitting user devices.
 */
@property (strong, nonatomic,readonly) NSArray * userDevicesTransmitting;

/**
 *  The list of all user devices that are not currently transmitting.
 */
@property (strong, nonatomic,readonly) NSArray * userDevicesNotTransmitting;

/**
 *  Whether the cameras for this data source should be hidden on a map view.
 */
@property (nonatomic) BOOL hidden;

/**
 *  Requests a list of users from the data source.  If the data source
 *  doesn't have a list of users yet, it will start an asynchronous web
 *  service call to retrieve it.
 */
- (void)getUsers;

/**
 *  Forces an asynchronous web service call to refresh the list of users.
 */
- (void)refresh;

/**
 *  Cancels any pending asynchronous calls to retrieve the list of users.
 */
- (void)cancel;

/**
 *  Clears the list of users.
 */
- (void)reset;

@end
