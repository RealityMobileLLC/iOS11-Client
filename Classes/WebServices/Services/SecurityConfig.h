//
//  SecurityConfig.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/24/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebService.h"
#import "WebServiceResponseHandler.h"

@class ClientServiceInfo;


/**
 *  Delegate used by the SecurityConfig class to indicate when web services
 *  respond.
 */
@protocol SecurityConfigDelegate

/**
 *  Called when a GetRequireSslForCredentials call completes.
 *
 *  @param requireSslForCredentials The value returned by the service.
 *  @param error An error, if one occurred, or nil if the operation 
 *               completed successfully.
 */
- (void)onGotRequireSslForCredentials:(BOOL)requireSslForCredentials error:(NSError *)error;

@end


/**
 *  Responsible for managing RealityVision SecurityConfig web service requests.
 */
@interface SecurityConfig : WebService

/**
 *  The delegate that gets notified when a web service responds.
 */
@property (weak) id <SecurityConfigDelegate> delegate;

/**
 *  Initializes a SecurityConfigDelegate object.
 *
 *  @param url      The base URL for RealityVision web services.
 *  @param delegate The delegate to notify when a web service responds.
 *
 *  @return An initialized SecurityConfig object or nil if the object could
 *           not be initialized.
 */
- (id)initWithSecurityConfigUrl:(NSURL *)url 
					   delegate:(id <SecurityConfigDelegate>)delegate;

/**
 *  Initiates a GetRequireSslForCredentials request.
 */
- (void)getRequireSslForCredentials;

@end
