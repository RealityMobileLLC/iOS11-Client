//
//  AcceptCertificate.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/1/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "AcceptCertificateRequest.h"
#import "RealityVisionAppDelegate.h"


// Maps a server certificate to an AcceptCertificate object.
static NSMutableDictionary * requestDictionary;

// Synchronization lock.
static NSObject * lock;


@implementation AcceptCertificateRequest
{
	NSString       * key;
	NSMutableArray * delegateList;
}


#pragma mark - Initialization and cleanup

+ (void)initialize
{
	if (self == [AcceptCertificateRequest class]) 
	{
		requestDictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
		lock = [[NSObject alloc] init];
	}
}

- (id)initWithKey:(NSString *)theKey;
{
	NSAssert(theKey!=nil,@"key must not be nil");
	
	self = [super init];
	if (self != nil)
	{
		key = theKey;
		delegateList = [[NSMutableArray alloc] initWithCapacity:10];
	}
	return self;
}

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	self = nil;
	return self;
}

- (void)addDelegate:(id <AcceptCertificateDelegate>)delegate
{
	[delegateList addObject:delegate];
}


#pragma mark - Public methods

+ (void)acceptCertificate:(NSString *)subject
				  forHost:(NSString *)host 
				 delegate:(id <AcceptCertificateDelegate>)delegate
{
	@synchronized(lock)
	{
		NSString * key = [NSString stringWithFormat:@"%@-%@",host,subject];
		AcceptCertificateRequest * request = [requestDictionary objectForKey:key];
		
		if (request == nil)
		{
			// create list of delegates to notify when user responds
			request = [[AcceptCertificateRequest alloc] initWithKey:key];
			[requestDictionary setValue:request forKey:key];
			
			// prompt user
			NSString * alertMessage = [NSString stringWithFormat:NSLocalizedString(@"%@ can't verify the identity of %@.\n\nSubject: %@\n\nWould you like to continue anyway?",
																				   @"Can't verify server certificate message format"),
									                                               [RealityVisionAppDelegate appName], host, subject];
			
			UIAlertView * alert = 
				[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Accept Certificate",@"Accept certificate alert title")
										   message:alertMessage
										  delegate:request
								 cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel")
								 otherButtonTitles:NSLocalizedString(@"Accept",@"Accept certificate button"),
				                                   nil];
			[alert show];
		}
		
		[request addDelegate:delegate];
	}
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	@synchronized(lock)
	{
		for (id <AcceptCertificateDelegate> delegate in delegateList)
		{
			[delegate certificateAccepted:(buttonIndex == 1)];
		}
		
		[requestDictionary removeObjectForKey:key];
	}
}

@end
