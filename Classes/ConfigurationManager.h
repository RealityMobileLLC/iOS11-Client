//
//  ServiceManager.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ClientConfiguration;
@class SystemUris;


/**
 *  Maintains configuration retrieved from a RealityVision server after a successful Connect.
 */
@interface ConfigurationManager : NSObject <NSCoding>

/**
 *  Client configuration retrieved from RealityVision server.
 *  Nil if not signed on.
 */
@property (strong,readonly) ClientConfiguration * clientConfiguration;

/**
 *  System URIs retrieved from RealityVision server.
 *  Nil if not signed on.
 */
@property (strong,readonly) SystemUris * systemUris;

/**
 *  Device ID returned by last successful Connect.
 */
@property (strong,readonly) NSString * deviceId;

/**
 *  Indicates whether the client should only send credentials over a secure
 *  connection.
 */
@property BOOL requireSslForCredentials;

/**
 *  Credential used on last successful Connect.
 */
@property (strong,readonly) NSURLCredential * credential;

/**
 *  Returns the singleton instance of the ConfigurationManager.
 */
+ (ConfigurationManager *)instance;

/**
 *  Creates the singleton instance of the ConfigurationManager from a coder.
 *
 *  @param coder Coder containing the ConfigurationManager.
 *  @param key   Key used to serialize the ConfigurationManager.
 */
+ (void)createFromCoder:(NSCoder *)coder forKey:(NSString *)key;

/**
 *  Updates the current configuration.
 *
 *  @param configuration Client configuration data from RealityVision server.
 *  @param uris          System URIs from RealityVision server.
 *  @param deviceId      Unique identifier for this client device.
 */
+ (void)updateClientConfiguration:(ClientConfiguration *)configuration 
							 uris:(SystemUris *)uris
						 deviceId:(NSString *)deviceId;

/**
 *  Invalidates the current configuration when the device signs off.  Also removes
 *  the current credential from the keychain.
 *  
 *  Note that deviceId remains valid since a device ID is not server-specific.
 */
+ (void)invalidate;

/**
 *  Saves the credential and protection space used on the last successful Connect.
 *  
 *  NOTE: Currently this does not actually save the credential due to an apparent bug in iOS.
 *        It does save the credential's user as the currently authenticated user.  The credential
 *        is being saved in the keychain via NSURLCredentialPersistencePermanent.
 *
 *  @param credential      Credential provided by user. Must not be nil.
 *  @param protectionSpace Protection space from authentication challenge. Must not be nil.
 */
- (void)saveCredential:(NSURLCredential *)credential forProtectionSpace:(NSURLProtectionSpace *)protectionSpace;

/**
 *  Adds a certificate exception that the user has agreed to accept.
 *
 *  @param exceptions Certificate policy exceptions from SecTrustCopyExceptions, 
 *                    or nil to remove exceptions for this host.
 *  @param host       Host that provided the certificate.
 *  @param subject    Certificate subject.
 */
- (void)addCertificateExceptions:(NSData *)exceptions forHost:(NSString *)host andSubject:(NSString *)subject;

/**
 *  Gets a certificate exception matching the given host and certificate subject.
 *  
 *  @param host    Host that provided the certificate.
 *  @param subject Certificate subject.
 *  
 *  @return Certificate policy exceptions previously accepted by the user.
 */
- (NSData *)getExceptionsForHost:(NSString *)host andSubject:(NSString *)subject;

@end
