//
//  RVCredentialStorage.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/23/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "RVCredentialStorage.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation RVCredentialStorage

static CFStringRef kSecRealityVisionService = CFSTR("RealityVision");


#pragma mark - Initialization and cleanup

static RVCredentialStorage * sharedCredentialStorage = nil;

+ (RVCredentialStorage *)sharedCredentialStorage
{
	if (sharedCredentialStorage == nil)
	{
		sharedCredentialStorage = [[RVCredentialStorage alloc] init];
	}
	return sharedCredentialStorage;
}

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		// do some cleanup, if necessary
		// previously, realityvision used NSURLCredentialStorage which stores credentials on the
		// keychain as internet passwords. we are now going to store them as generic passwords.
		// if there are any internet passwords on the keychain, we'll use the first one as the
		// new realityvision generic password (there should only be one anyway).
		// then we'll remove all of the internet passwords from the keychain.
		CFArrayRef internetPasswords = [self createArrayOfInternetPasswords];
		
		if (internetPasswords)
		{
			NSUInteger numCredentials = CFArrayGetCount(internetPasswords);
			DDLogInfo(@"%@ %@: There are %d internet passwords on the keychain", THIS_FILE, THIS_METHOD, numCredentials);
			
			// if we don't have a realityvision credential, use the first internet password
			if (numCredentials > 0 && self.credential == nil)
			{
				CFDictionaryRef secItemDictionary = CFArrayGetValueAtIndex(internetPasswords, 0);
				DDLogInfo(@"%@ %@: Using first internet password for RealityVision credential", THIS_FILE, THIS_METHOD);
				[self logSecItem:secItemDictionary];
				
				NSURLCredential * credential = [self credentialWithSecItem:secItemDictionary];
				if (credential)
				{
					[self setCredential:credential];
				}
			}
			
			CFRelease(internetPasswords);
			[self removeAllInternetPasswords];
		}
	}
	return self;
}


#pragma mark - Public methods

- (NSURLCredential *)credential
{
	CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
	CFDictionarySetValue(query, kSecClass, kSecClassGenericPassword);
	CFDictionarySetValue(query, kSecAttrService, kSecRealityVisionService);
	CFDictionarySetValue(query, kSecReturnAttributes, kCFBooleanTrue);
	CFDictionarySetValue(query, kSecReturnData, kCFBooleanTrue);
	
	CFDictionaryRef secItemDictionary = NULL;
	OSStatus status = SecItemCopyMatching(query, (CFTypeRef *)&secItemDictionary);
	NSURLCredential * credential = (status == noErr) ? [self credentialWithSecItem:secItemDictionary] : nil;
	
	if (query) CFRelease(query);
	if (secItemDictionary) CFRelease(secItemDictionary);
	
	return credential;
}

- (void)setCredential:(NSURLCredential *)credential
{
	// removing the existing credential is easier than searching for it and then updating if it does exist
	[self removeCredential];
	
	CFStringRef account = (__bridge CFStringRef)(credential.user);
	CFDataRef pwdata = (__bridge CFDataRef)([credential.password dataUsingEncoding:NSUTF8StringEncoding]);
	
	CFMutableDictionaryRef secItemDictionary = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
	CFDictionarySetValue(secItemDictionary, kSecClass, kSecClassGenericPassword);
	CFDictionarySetValue(secItemDictionary, kSecAttrAccessible, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly);
	CFDictionarySetValue(secItemDictionary, kSecAttrService, kSecRealityVisionService);
	CFDictionarySetValue(secItemDictionary, kSecAttrAccount, account);
	CFDictionarySetValue(secItemDictionary, kSecValueData, pwdata);
	OSStatus status = SecItemAdd(secItemDictionary, NULL);
	CFRelease(secItemDictionary);
	
	if (status != noErr)
	{
		DDLogError(@"%@ %@: Unable to store credential (%ld)", THIS_FILE, THIS_METHOD, status);
	}
}

- (void)removeCredential
{
	// go ahead and remove all generic passwords in keychain
	CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
	CFDictionarySetValue(query, kSecClass, kSecClassGenericPassword);
	OSStatus status = SecItemDelete(query);
	CFRelease(query);
	
	if (status != noErr)
	{
		DDLogError(@"%@ %@: Unable to delete credentials (%ld)", THIS_FILE, THIS_METHOD, status);
	}
}


#pragma mark - Private methods

- (CFArrayRef)createArrayOfInternetPasswords
{
	CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
	CFDictionarySetValue(query, kSecClass, kSecClassInternetPassword);
	CFDictionarySetValue(query, kSecMatchLimit, kSecMatchLimitAll);
	CFDictionarySetValue(query, kSecReturnAttributes, kCFBooleanTrue);
	CFDictionarySetValue(query, kSecReturnData, kCFBooleanTrue);
	
	CFArrayRef allCredentials = NULL;
	OSStatus status = SecItemCopyMatching(query, (CFTypeRef *)&allCredentials);
	CFRelease(query);
	
	return status == noErr ? allCredentials : NULL;
}

- (void)removeAllInternetPasswords
{
	CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 0, NULL, NULL);
	CFDictionarySetValue(query, kSecClass, kSecClassInternetPassword);
	OSStatus status = SecItemDelete(query);
	CFRelease(query);
	
	if (status != noErr)
	{
		DDLogError(@"%@ %@: Unable to delete credentials (%ld)", THIS_FILE, THIS_METHOD, status);
	}
}

- (NSURLCredential *)credentialWithSecItem:(CFDictionaryRef)secItemDictionary
{
	NSString * user = [self accountFromSecItem:secItemDictionary];
	if (user == nil)
		return nil;
	
	NSString * password = [self valueFromSecItem:secItemDictionary];
	if (password == nil)
		return nil;
	
	return [[NSURLCredential alloc] initWithUser:user
										password:password
									 persistence:NSURLCredentialPersistenceNone];
}

- (NSString *)securityClassFromSecItem:(CFDictionaryRef)secItemDictionary
{
	CFTypeRef securityClass = CFDictionaryGetValue(secItemDictionary, kSecClass);
	
	if (securityClass == kSecClassGenericPassword)
		return @"GenericPassword";
	
	if (securityClass == kSecClassInternetPassword)
		return @"InternetPassword";
	
	if (securityClass == kSecClassCertificate)
		return @"Certificate";
	
	if (securityClass == kSecClassKey)
		return @"Key";
	
	if (securityClass == kSecClassIdentity)
		return @"Identity";
	
	return securityClass ? @"UNKNOWN" : @"NULL";
}

- (NSString *)accountFromSecItem:(CFDictionaryRef)secItemDictionary
{
	CFStringRef account = CFDictionaryGetValue(secItemDictionary, kSecAttrAccount);
	return account ? (__bridge NSString *)account : @"NULL";
}

- (NSString *)securityDomainFromSecItem:(CFDictionaryRef)secItemDictionary
{
	CFStringRef securityDomain = CFDictionaryGetValue(secItemDictionary, kSecAttrSecurityDomain);
	return securityDomain ? (__bridge NSString *)securityDomain : @"NULL";
}

- (NSString *)serverFromSecItem:(CFDictionaryRef)secItemDictionary
{
	CFStringRef server = CFDictionaryGetValue(secItemDictionary, kSecAttrServer);
	return server ? (__bridge NSString *)server : @"NULL";
}

- (NSString *)protocolFromSecItem:(CFDictionaryRef)secItemDictionary
{
	CFNumberRef protocol = CFDictionaryGetValue(secItemDictionary, kSecAttrProtocol);
/*
	if (CFNumberCompare(protocol, kSecAttrProtocolHTTP, NULL) == kCFCompareEqualTo)
		return @"HTTP";
	
	if (CFNumberCompare(protocol, kSecAttrProtocolHTTPProxy, NULL) == kCFCompareEqualTo)
		return @"HTTPProxy";
	
	if (CFNumberCompare(protocol, kSecAttrProtocolHTTPS, NULL) == kCFCompareEqualTo)
		return @"HTTPS";
	
	if (CFNumberCompare(protocol, kSecAttrProtocolHTTPSProxy, NULL) == kCFCompareEqualTo)
		return @"HTTPSProxy";
*/
	return protocol ? @"Other" : @"NULL";
}

- (NSString *)valueFromSecItem:(CFDictionaryRef)secItemDictionary
{
	CFDataRef value = CFDictionaryGetValue(secItemDictionary, kSecValueData);
	return [[NSString alloc] initWithData:(__bridge NSData *)value encoding:NSUTF8StringEncoding];
}

- (void)logSecItem:(CFDictionaryRef)secItemDictionary
{
	DDLogVerbose(@"  Class      : %@", [self securityClassFromSecItem:secItemDictionary]);
	DDLogVerbose(@"  Account    : %@", [self accountFromSecItem:secItemDictionary]);
	DDLogVerbose(@"  Sec Domain : %@", [self securityDomainFromSecItem:secItemDictionary]);
	DDLogVerbose(@"  Server     : %@", [self serverFromSecItem:secItemDictionary]);
	DDLogVerbose(@"  Protocol   : %@", [self protocolFromSecItem:secItemDictionary]);
}

@end
