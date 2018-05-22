//
//  RVCredentialStorage.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/23/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  RVCredentialStorage implements a singleton for managing RealityVision credentials. It is
 *  intended for storing a single credential associated with the RealityVision service. The 
 *  credential is stored in the app's keychain with data protection set to
 *  kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly. That allows the credential to be accessed
 *  any time after the device has been unlocked for the first time after a power on. The credential
 *  is not backed up or migrated to new devices.
 */
@interface RVCredentialStorage : NSObject

/**
 *  Returns the shared credential storage object.
 */
+ (RVCredentialStorage *)sharedCredentialStorage;

/**
 *  Returns the RealityVision credential.
 */
- (NSURLCredential *)credential;

/**
 *  Stores the RealityVision credential in the keychain.
 */
- (void)setCredential:(NSURLCredential *)credential;

/**
 *  Removes the RealityVision credential from the keychain.
 *  
 *  NOTE: This actually removes all generic passwords from the app's keychain.
 */
- (void)removeCredential;

@end
