//
//  AuthenticationHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "AuthenticationHandler.h"
#import "ClientConfiguration.h"
#import "ConfigurationManager.h"
#import "RealityVisionAppDelegate.h"
#import "RootViewController.h"
#import "RealityVisionClient.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


// used to track debug logging by assigning an id to each AuthenticationHandler object
static NSUInteger nextHandlerId()
{
	const NSUInteger MaxId = 99;
	static NSUInteger nextId = MaxId;
	nextId = (nextId == MaxId) ? 0 : nextId+1;
	return nextId;
}



@interface AuthenticationHandler ()
{
	NSURLAuthenticationChallenge * authenticationChallenge;
	CFDataRef                      certificateExceptions;
	CredentialsViewController    * credentialsController;
	NSUInteger                     handlerId;
}

- (void)handleDefaultAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)handleServerTrustAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)trustServerForChallenge:(NSURLAuthenticationChallenge *)challenge
			andStoreCertificate:(BOOL)storeCertificate;
- (void)saveCertificateExceptions:(SecTrustRef)trust;

@end


@implementation AuthenticationHandler

@synthesize authenticationError;


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		authenticationError = nil;
		authenticationChallenge = nil;
		certificateExceptions = NULL;
		credentialsController = nil;
		handlerId = nextHandlerId();
	}
	return self;
}


- (void)dealloc
{
	[credentialsController setDelegate:nil];
	
	
	if (certificateExceptions != NULL)
	{
		CFRelease(certificateExceptions);
	}
	
}


#pragma mark - NSURLConnection callbacks

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
	// we want to save the first valid credential we get and the easiest way 
	// to do it is to intercept all credential challenges
	return NO;
}


- (BOOL)connection:(NSURLConnection *)conn canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	BOOL wantsServerTrust = [protectionSpace authenticationMethod] == NSURLAuthenticationMethodServerTrust;
	
	BOOL wantsUserCredentials = [protectionSpace authenticationMethod] == NSURLAuthenticationMethodDefault ||
	                            [protectionSpace authenticationMethod] == NSURLAuthenticationMethodHTTPBasic;
	
	BOOL canSendCredentials = (! [ConfigurationManager instance].requireSslForCredentials) || 
	                          ([protectionSpace receivesCredentialSecurely]);
	
	return wantsServerTrust || (wantsUserCredentials && canSendCredentials);
}


- (void)connection:(NSURLConnection *)conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if (([[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodDefault) ||
		([[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodHTTPBasic))
	{
		[self handleDefaultAuthenticationChallenge:challenge];
	}
	else if ([[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodServerTrust)
	{
		[self handleServerTrustAuthenticationChallenge:challenge];
	}
	else 
	{
		DDLogWarn(@"Unsupported authentication method");
		authenticationError = [RvError rvErrorWithLocalizedDescription:@"Unsupported authentication method"];
		[[challenge sender] cancelAuthenticationChallenge:challenge];
	}
}


- (void)connectionIsComplete:(NSURLConnection *)conn
{
    if (credentialsController != nil)
    {
        RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
        [rootViewController dismissCredentialsViewController];
        credentialsController = nil;
    }
    
    if (certificateExceptions != NULL)
    {
        CFRelease(certificateExceptions);
        certificateExceptions = NULL;
    }
}


#pragma mark - User authentication methods

- (void)handleDefaultAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	DDLogInfo(@"AuthenticationHandler(%d) handleDefaultAuthenticationChallenge: previousFailureCount = %d",
			  handlerId, [challenge previousFailureCount]);
	
	NSURLCredential * credential = nil;
	
	// if this is the first challenge, use a saved credential if one exists (and try again a second time if it failed)
	if ([challenge previousFailureCount] < 3)
	{
        DDLogInfo(@"Looking for saved credential");
        credential = [ConfigurationManager instance].credential;
	}
	
    if (credential == nil)
	{
		if ([RealityVisionClient instance].isSignedOn)
		{
			// @todo this should never happen (but does) ... using this to diagnose problem
			//       note that when this fails, it is because the NSURLCredentialStorage was providing a credential with a null password
			DDLogError(@"User is signed on but saved credential for user %@ did not work (or unable to get credential)",
					   [[[ConfigurationManager instance] credential] user]);
			authenticationError = [RvError rvErrorWithLocalizedDescription:@"Unable to authenticate with stored credential"];
			[[challenge sender] cancelAuthenticationChallenge:challenge];
			return;
		}
		
		DDLogInfo(@"Getting credential from user");
		
		// get credentials from user
		authenticationChallenge = challenge;
		
		if (credentialsController == nil)
		{
			// @todo serialize access to credentials controller so it doesn't try to display multiple times for separate web services
			credentialsController = [[CredentialsViewController alloc] initWithChallenge:authenticationChallenge
																				 andUser:[RealityVisionClient instance].lastSignedOnUser];
			credentialsController.delegate = self;
			
            RootViewController * rootViewController = (RootViewController *)[RealityVisionAppDelegate rootViewController];
			[rootViewController showCredentialsViewController:credentialsController];
		}
		else 
		{
			[credentialsController gotNewChallenge:challenge 
									 statusMessage:NSLocalizedString(@"Invalid credentials - please retry",
																	 @"Invalid credentials message")];
		}
	}
    else
    {
		DDLogInfo(@"Trying credential for user %@", [credential user]);
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    }
}


#pragma mark - Server trust authentication methods

- (void)handleServerTrustAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	DDLogInfo(@"AuthenticationHandler(%d) handleServerTrustAuthenticationChallenge: previousFailureCount = %d",
			  handlerId, [challenge previousFailureCount]);
	
    NSURLProtectionSpace * protectionSpace = [challenge protectionSpace];
	NSString             * host            = [protectionSpace host];
	SecCertificateRef      certificate     = NULL;
	CFStringRef            subject         = NULL;
    SecTrustRef            trust           = [protectionSpace serverTrust];
    SecTrustResultType     trustResult;
    
    // see if the certicate can be trusted
    OSStatus err = SecTrustEvaluate(trust, &trustResult);
    BOOL trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified));
    
	if (! trusted)
	{
#ifdef RV_ADDS_CERTS_TO_KEYCHAIN
#ifdef RV_DEBUG_PRINT_CERTS
		NSArray * certificates = [self certificates];
		if ([certificates count] > 0)
		{
			[self _printCertificate:[certificates objectAtIndex:0] attributes:nil];
		}
#endif
		// get certificates stored on app keychain and try again
		OSStatus anchorErr = SecTrustSetAnchorCertificates(trust, (CFArrayRef)[self certificates]);
		if (anchorErr != noErr)
		{
			// @todo error handling
		}
#endif
		
		// get certificate info
		certificate = SecTrustGetCertificateAtIndex(trust, 0);
		subject     = SecCertificateCopySubjectSummary(certificate);
		
        DDLogInfo(@"Initial certificate trust failed for %@", (__bridge NSString *)subject);
        
        CFDataRef exceptions = (__bridge CFDataRef)[[ConfigurationManager instance] getExceptionsForHost:host 
                                                                                     andSubject:(__bridge NSString *)subject];
        
        if (exceptions != NULL)
        {
            DDLogInfo(@"Trying again with policy exceptions");
            
            if (SecTrustSetExceptions(trust, exceptions))
            {
                err = SecTrustEvaluate(trust, &trustResult);
                trusted = (err == noErr) && ((trustResult == kSecTrustResultProceed) || (trustResult == kSecTrustResultUnspecified));
                
                if (! trusted)
                {
                    DDLogInfo(@"Second certificate trust failed for %@", (__bridge NSString *)subject);
                }
            }
            else 
            {
                DDLogWarn(@"Unable to use certificate policy exceptions for %@", (__bridge NSString *)subject);
            }
        }
        else 
        {
            DDLogInfo(@"No policy exceptions for host %@ and subject %@", host, (__bridge NSString *)subject);
        }
	}
	
    if (! trusted) 
	{
		NSAssert(certificate!=NULL,@"Certificate has not been set");
		NSAssert(subject!=NULL,@"Certificate subject has not been set");
		
		// ask the user if they want to accept this certificate
        DDLogInfo(@"AuthenticationHandler: Requesting certificate acceptance from user.");
		authenticationChallenge = challenge;
		[self saveCertificateExceptions:trust];
		[AcceptCertificateRequest acceptCertificate:(__bridge NSString *)subject forHost:host delegate:self];
	}
	else 
	{
		[self trustServerForChallenge:challenge andStoreCertificate:NO];
    }
	
	if (subject != NULL)
	{
		CFRelease(subject);
	}
}


- (void)trustServerForChallenge:(NSURLAuthenticationChallenge *)challenge
			andStoreCertificate:(BOOL)storeCertificate 
{
	NSAssert(challenge!=nil,@"challenge must not be nil");
	
	// get server certificate and create a credential to trust it
	NSURLProtectionSpace * protectionSpace = [challenge protectionSpace];
	SecTrustRef            trust           = [protectionSpace serverTrust];
	
	if (storeCertificate)
	{
		// add server certificate to keychain
		SecCertificateRef certificate = SecTrustGetCertificateAtIndex(trust, 0);
		CFStringRef       subject     = SecCertificateCopySubjectSummary(certificate);
		
#ifdef RV_ADDS_CERTS_TO_KEYCHAIN
#ifdef RV_DEBUG_PRINT_CERTS
		fprintf(stderr, "Storing certificate to keychain\n");
		int numCerts = SecTrustGetCertificateCount(trust);
		fprintf(stderr, "Number of certificates = %d\n", numCerts);
		[self _printCertificate:certificate attributes:nil];
#endif
		
		NSDictionary * secDictionary = 
			[NSDictionary dictionaryWithObjectsAndKeys:(id)kSecClassCertificate, kSecClass, 
			                                           certificate,              kSecValueRef, 
			                                           nil];
		
		OSStatus err = SecItemAdd((CFDictionaryRef)secDictionary, NULL);
		if ((err != errSecSuccess) && (err != errSecDuplicateItem)) 
		{
			DDLogWarn(@"Unable to add certificate to keychain");
		}
#endif
		
		// save certificate exceptions, if any, for later use
        DDLogInfo(@"AuthenticationHandler: Saving certificate exceptions");
		[[ConfigurationManager instance] addCertificateExceptions:(__bridge NSData *)certificateExceptions 
														  forHost:[protectionSpace host] 
													   andSubject:(__bridge NSString *)subject];
		CFRelease(subject);
	}
	
	// accept the certificate for this challenge
	[[challenge sender] useCredential:[NSURLCredential credentialForTrust:trust] 
		   forAuthenticationChallenge:challenge];
}


- (void)saveCertificateExceptions:(SecTrustRef)trust
{
	if (certificateExceptions != NULL)
	{
		CFRelease(certificateExceptions);
	}
	
	certificateExceptions = SecTrustCopyExceptions(trust);
}


#ifdef RV_ADDS_CERTS_TO_KEYCHAIN
// Returns an array containing all certificates in the app's keychain.
- (NSArray *)certificates
{
    NSArray * certificates = nil;
	NSDictionary * searchDictionary = [NSDictionary dictionaryWithObjectsAndKeys:(id)kSecClassCertificate, kSecClass, 
									   kSecMatchLimitAll,        kSecMatchLimit, 
									   kCFBooleanTrue,           kSecReturnRef, 
									   nil];
	
	OSStatus err = SecItemCopyMatching((CFDictionaryRef)searchDictionary, (CFTypeRef *)&certificates);
	
	if (err == errSecItemNotFound) 
	{
		certificates = [NSArray array];
	}
	
	DDLogVerbose(@"Retrieved %d certificates from the keychain", [certificates count]);
	
	return [certificates autorelease];
}
#endif


#pragma mark - AcceptCertificateDelegate methods

- (void)certificateAccepted:(BOOL)accepted
{
    if (accepted)
    {
        DDLogInfo(@"AuthenticationHandler(%d): User accepted certificate.", handlerId);
        [self trustServerForChallenge:authenticationChallenge andStoreCertificate:YES];
    }
    else
    {
        DDLogInfo(@"AuthenticationHandler(%d): Did not accept certificate because user cancelled.", handlerId);
        authenticationError = [RvError rvUserCancelled];
        [[authenticationChallenge sender] cancelAuthenticationChallenge:authenticationChallenge];
    }
}


#pragma mark - CredentialsDelegate methods

- (void)didGetCredential:(NSURLCredential *)credential
{
    if (credential != nil)
    {
        DDLogInfo(@"AuthenticationHandler(%d): Saving credential for user %@", handlerId, credential.user);
		[[ConfigurationManager instance] saveCredential:credential
									 forProtectionSpace:[authenticationChallenge protectionSpace]];
        [[authenticationChallenge sender] useCredential:credential
                             forAuthenticationChallenge:authenticationChallenge];
    }
    else 
    {
        DDLogInfo(@"AuthenticationHandler(%d): Did not get user credential because user cancelled", handlerId);
        authenticationError = [RvError rvUserCancelled];
        [[authenticationChallenge sender] cancelAuthenticationChallenge:authenticationChallenge];
    }
    
    authenticationChallenge = nil;
}

@end
