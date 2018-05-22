//
//  ConfigurationManager.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ConfigurationManager.h"
#import "ClientConfiguration.h"
#import "SystemUris.h"
#import "CertificateException.h"
#import "RVCredentialStorage.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


static NSString * const KEY_CONFIGURATION               = @"ClientConfiguration";
static NSString * const KEY_DEVICE_ID                   = @"DeviceId";
static NSString * const KEY_URIS                        = @"SystemUris";
static NSString * const KEY_EXCEPTIONS                  = @"CertificateExceptions";
static NSString * const KEY_REQUIRE_SSL_FOR_CREDENTIALS = @"RequireSslForCredentials";
static NSString * const KEY_AUTHENTICATED_USER          = @"AuthenticatedUser";


@implementation ConfigurationManager
{
	NSMutableDictionary * certificateExceptions;
    NSString            * authenticatedUser;
}

@synthesize clientConfiguration;
@synthesize systemUris;
@synthesize requireSslForCredentials;
@synthesize deviceId;


#pragma mark - Initialization and cleanup

static ConfigurationManager * instance;

+ (ConfigurationManager *)instance
{
	if (instance == nil) 
	{
		@try 
		{
			DDLogInfo(@"Creating new ConfigurationManager with no configuration");
			instance = [[ConfigurationManager alloc] init];
		}
		@catch (NSException * exception) 
		{
			DDLogError(@"Exception creating ConfigurationManager: %@", exception);
			instance = nil;
		}
	}
	return instance;
}

- (id)init
{
	NSAssert(instance==nil,@"ConnectionManager singleton should only be instantiated once");
	self = [super init];
	if (self != nil)
	{
		DDLogVerbose(@"%@ %@", THIS_FILE, THIS_METHOD);
		clientConfiguration = nil;
		systemUris = nil;
		deviceId = nil;
        authenticatedUser = nil;
		certificateExceptions = [[NSMutableDictionary alloc] initWithCapacity:5];
		requireSslForCredentials = YES;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
	NSAssert(instance==nil,@"ConnectionManager singleton should only be instantiated once");
	
	DDLogVerbose(@"%@ %@", THIS_FILE, THIS_METHOD);
	clientConfiguration = [coder decodeObjectForKey:KEY_CONFIGURATION];
	systemUris = [coder decodeObjectForKey:KEY_URIS];
	deviceId = [coder decodeObjectForKey:KEY_DEVICE_ID];
	
	certificateExceptions = [coder decodeObjectForKey:KEY_EXCEPTIONS];
	if (certificateExceptions == nil)
	{
		certificateExceptions = [[NSMutableDictionary alloc] initWithCapacity:5];
	}
	
    requireSslForCredentials = YES;
	if ([coder containsValueForKey:KEY_REQUIRE_SSL_FOR_CREDENTIALS])
	{
		requireSslForCredentials = [coder decodeBoolForKey:KEY_REQUIRE_SSL_FOR_CREDENTIALS];
	}
	
    authenticatedUser = nil;
	if ([coder containsValueForKey:KEY_AUTHENTICATED_USER])
	{
		authenticatedUser = [coder decodeObjectForKey:KEY_AUTHENTICATED_USER];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder 
{
	// note that we purposefully do NOT serialize the credential -- it is stored safely in the keychain
	[coder encodeObject:clientConfiguration    forKey:KEY_CONFIGURATION];
	[coder encodeObject:systemUris             forKey:KEY_URIS];
	[coder encodeObject:deviceId               forKey:KEY_DEVICE_ID];
	[coder encodeObject:certificateExceptions  forKey:KEY_EXCEPTIONS];
	[coder encodeBool:requireSslForCredentials forKey:KEY_REQUIRE_SSL_FOR_CREDENTIALS];
    [coder encodeObject:authenticatedUser      forKey:KEY_AUTHENTICATED_USER];
}


#pragma mark - Public methods

+ (void)createFromCoder:(NSCoder *)coder forKey:(NSString *)key
{
	instance = [coder decodeObjectForKey:key];
}

+ (void)updateClientConfiguration:(ClientConfiguration *)configuration 
							 uris:(SystemUris *)uris 
						 deviceId:(NSString *)devId
{
	NSAssert(configuration!=nil,@"configuration parameter must not be nil");
	NSAssert(uris!=nil,@"uris parameter must not be nil");
	
	ConfigurationManager * configMgr = [ConfigurationManager instance];
	@synchronized(configMgr)
	{
		configMgr->clientConfiguration = configuration;
		configMgr->systemUris = uris;
		configMgr->deviceId = devId;
	}
}

+ (void)invalidate
{
	DDLogInfo(@"ConfigurationManager invalidate");
	
	ConfigurationManager * configMgr = [ConfigurationManager instance];
	@synchronized(configMgr)
	{
		configMgr->clientConfiguration = nil;
		configMgr->systemUris = nil;
		configMgr->requireSslForCredentials = YES;
		configMgr->authenticatedUser = nil;
		[configMgr->certificateExceptions removeAllObjects];
		[[RVCredentialStorage sharedCredentialStorage] removeCredential];
	}
}

- (NSURLCredential *)credential
{
    if (authenticatedUser == nil)
	{
		DDLogInfo(@"No authenticatedUser, so returning nil for credential");
        return nil;
	}
    
	NSURLCredential * credential = [RVCredentialStorage sharedCredentialStorage].credential;
	if (! [[credential user] isEqualToString:authenticatedUser])
	{
		DDLogError(@"ConfigurationManager credential: Keychain credential is for user %@; expecting user %@",
				   [credential user], authenticatedUser);
		return nil;
	}
	
    return credential;
}

- (void)saveCredential:(NSURLCredential *)credential forProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    NSAssert(credential!=nil,@"Credential must be provided");
    NSAssert(protectionSpace!=nil,@"Protection Space must be provided");
	
	@synchronized(self)
	{
		NSURLCredential * theCredential = [[NSURLCredential alloc] initWithUser:credential.user
																	   password:credential.password
																	persistence:NSURLCredentialPersistenceNone];
		[[RVCredentialStorage sharedCredentialStorage] setCredential:theCredential];
		
		if (! [credential.user isEqualToString:authenticatedUser])
		{
			if (authenticatedUser != nil)
			{
				DDLogWarn(@"ConfigurationManager overwriting existing authenticated user");
			}
			
			authenticatedUser = [[NSString alloc] initWithString:credential.user];
		}
	}
}

- (void)addCertificateExceptions:(NSData *)exceptions
						 forHost:(NSString *)host
					  andSubject:(NSString *)subject
{
	NSAssert(host!=nil,@"Host cannot be nil");
	NSAssert(subject!=nil,@"Subject cannot be nil");
	
	@synchronized(self)
	{
		CertificateException * thisException =
			(exceptions == nil) ? nil : [[CertificateException alloc] initWithSubject:subject andExceptions:exceptions];
		
		[certificateExceptions setValue:thisException forKey:host];
	}
}

- (NSData *)getExceptionsForHost:(NSString *)host andSubject:(NSString *)subject
{
	@synchronized(self)
	{
		CertificateException * thisException = [certificateExceptions objectForKey:host];
		BOOL certificateMatch = (thisException != nil) && ([thisException.subject isEqualToString:subject]);
		return certificateMatch ? thisException.exceptions : nil;
	}
}

@end
