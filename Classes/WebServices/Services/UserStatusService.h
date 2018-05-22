//
//  UserStatusService.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/28/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebService.h"
#import "WebServiceResponseHandler.h"


/**
 *  Delegate used by the UserStatusServiceDelegate class to indicate when web services
 *  respond.
 */
@protocol UserStatusServiceDelegate

@optional

/**
 *  Called when a GetDeviceList call completes.
 *
 *  @param cameras An array of Device objects.
 *  @param error   An error, if one occurred, or nil if the operation 
 *                 completed successfully.
 */
- (void)onGetDeviceListResult:(NSArray *)devices error:(NSError *)error;

/**
 *  Called when a GetGroups or GetValidRecipientGroups call completes.
 *
 *  @param cameras An array of Group objects.
 *  @param error   An error, if one occurred, or nil if the operation 
 *                 completed successfully.
 */
- (void)onGetGroupsResult:(NSArray *)groups error:(NSError *)error;

/**
 *  Called when a GetUserList or GetSignedOnUsers call completes.
 *
 *  @param cameras An array of User objects.
 *  @param error   An error, if one occurred, or nil if the operation 
 *                 completed successfully.
 */
- (void)onGetUserListResult:(NSArray *)users error:(NSError *)error;

@end


/**
 *  Responsible for managing RealityVision User Status Service web service 
 *  requests.
 */
@interface UserStatusService : WebService 

/**
 *  The delegate that gets notified when a web service responds.
 */
@property (weak) id <UserStatusServiceDelegate> delegate;

/**
 *  Initializes a UserStatusService object.
 *
 *  @param url      The base URL for RealityVision web services.
 *  @param delegate The delegate to notify when a web service responds.
 *
 *  @return An initialized UserStatusService object or nil if the object
 *          could not be initialized.
 */
- (id)initWithUrl:(NSURL *)url andDelegate:(id <UserStatusServiceDelegate>)delegate;

/**
 *  Initiates a Get Device List request.
 */
- (void)getDeviceList;

/**
 *  Initiates a Get Groups request.
 */
- (void)getGroups;

/**
 *  Initiates a Get Signed On Devices request.
 *  
 *  @param includeViewingSessions Whether to return the list of RealityVision Video Server sessions
 *                                each user is viewing.
 */
- (void)getSignedOnDevicesAndIncludeViewingSessions:(BOOL)includeViewingSessions;

/**
 *  Initiates a Get Signed On Users request.
 *  
 *  @param includeViewingSessions Whether to return the list of RealityVision Video Server sessions
 *                                each user is viewing.
 */
- (void)getSignedOnUsersAndIncludeViewingSessions:(BOOL)includeViewingSessions;

/**
 *  Initiates a Get User List request.
 */
- (void)getUserList;

/**
 *  Initiates a Get Valid Recipient Groups request.
 */
- (void)getValidRecipientGroups;

@end
