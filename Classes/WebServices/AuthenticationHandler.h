//
//  AuthenticationHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AcceptCertificateRequest.h"
#import "CredentialsViewController.h"


/**
 *  Handles RealityVision authentication callbacks from NSURLConnections.
 *  
 *  The user will be prompted once (and only once) for credentials and, optionally, server
 *  certificate acceptance.  Depending on the configuration of the server, the user will
 *  either be prompted for these when GetRequiresSslForCredentials is called or when Connect
 *  is called.
 *  
 *  The ConfigurationManager class maintains the state data for whether the user has been
 *  prompted for credentials and/or server certificate.  When the user signs off, both flags
 *  are set to NO so that the user will be prompted again during the next sign on.
 *  
 *  When prompted for credentials, the AuthenticationHandler gets them as follows:
 *  
 *  1. If the user has already entered credentials during the current sign-on session,
 *     the AuthenticationHandler first attempts to get them from the ConfigurationManager.
 *     If they aren't stored in the ConfigurationManager, it then attempts to get them
 *     from the keychain.
 *
 *  2. If the user has not entered credentials, or if the credentials are not stored,
 *     the user is prompted to enter credentials.
 */
@interface AuthenticationHandler : NSObject <CredentialsDelegate, AcceptCertificateDelegate>

/**
 *  An error indicating why authentication was not allowed to proceed, or nil if no error occurred.
 */
@property (nonatomic,readonly,strong) NSError * authenticationError;

/**
 *  Indicates whether connection should use the keychain or ask for credentials.
 */
- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection;

/**
 *  Indicates whether we can authenticate against the given protection space.
 */
- (BOOL)connection:(NSURLConnection *)conn canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;

/**
 *  Provides authentication credentials for the given challenge.
 */
- (void)connection:(NSURLConnection *)conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

/**
 *  Indicates the connection is complete and all state can be cleared.
 */
- (void)connectionIsComplete:(NSURLConnection *)conn;

@end
