//
//  MotionJpegStream.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/7/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "MotionJpegStream.h"
#import <Foundation/NSThread.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "Comment.h"
#import "Session.h"
#import "SessionHandler.h"
#import "ConfigurationManager.h"
#import "MainMenuViewController.h"
#import "AuthenticationHandler.h"
#import "RealityVisionClient.h"
#import "RealityVisionAppDelegate.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


static const int SESSION_BUFFER_INITIAL_SIZE = 1024;
static const int IMAGE_BUFFER_INITIAL_SIZE   = 1024 * 128;
static const int IMAGE_BUFFER_MAX_SIZE       = 1024 * 512;

static NSString * const MIME_MULTIPART = @"multipart/x-mixed-replace";
static NSString * const MIME_XML       = @"text/xml";

#ifdef RV_MJPEG_MULTIPART_HEADERS
static const NSString * const REALITYVISION_LATITUDE_HEADER  = @"X-RealityMobile-Latitude";
static const NSString * const REALITYVISION_LONGITUDE_HEADER = @"X-RealityMobile-Longitude";
#endif

#define JPEG_MARKER ((char)0xFF)
#define JPEG_SOI    ((char)0xD8)
#define JPEG_EOI    ((char)0xD9)


@implementation MotionJpegStream
{
	NSURL                 * url;
	NSURLConnection       * connection;
	NSError               * responseError;
	
	BOOL                    isMultipart;
	BOOL                    readSessionData;
	BOOL                    soiFound;
	char                    lastByte;
	
	NSMutableData         * sessionData;
	NSMutableData         * imageData;
	CLLocation            * imageLocation;
	NSDate                * imageTime;
	int                     imageSessionId;
	int                     imageFrameId;
	
	AuthenticationHandler * authenticationHandler;
}

@synthesize delegate;
@synthesize isClosed;


#pragma mark - Initialization and cleanup

- (id)initWithUrl:(NSURL *)theUrl
{
	DDLogVerbose(@"MotionJpegStream initWithUrl: %@", theUrl);
	self = [super init];
	if (self != nil)
	{
		url = theUrl;
		connection = nil;
		responseError = nil;
		authenticationHandler = nil;
		isClosed = YES;
		imageSessionId = kRVNoSessionId;
		imageFrameId = kRVNoFrameId;
		
		// create buffer to hold image data and initialize it with first byte of every JPEG
		static const char JpegMarker = JPEG_MARKER;
		imageData = [NSMutableData dataWithCapacity:IMAGE_BUFFER_INITIAL_SIZE];
		[imageData appendBytes:&JpegMarker length:1];
	}
	return self;
}


#pragma mark - Public methods

- (BOOL)open:(NSError **)error
{
	DDLogVerbose(@"MotionJpegStream open");
	NSURLRequest * request = [NSURLRequest requestWithURL:url
											  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
										  timeoutInterval:60] ;
	if (request != nil)
	{
		isMultipart = NO;
		readSessionData = NO;

		// create connection to send request and manage response
		connection = [NSURLConnection connectionWithRequest:request delegate:self];
		if (connection == nil)
		{
			NSString * msg = [NSString stringWithFormat:@"Unable to create HTTP connection to %@", url];
			DDLogError(@"MotionJpegStream open: %@", msg);
			
			if (error != nil) 
			{
				*error = [RvError rvErrorWithLocalizedDescription:msg];
			}
		}
		else 
		{
			[RealityVisionAppDelegate didStartNetworking];
		}
	}
	
	isClosed = connection == nil;
	return ! isClosed;
}

- (void)close
{
	DDLogVerbose(@"MotionJpegStream close");
	[connection cancel];
	[self connectionIsComplete];
}

- (BOOL)allowCredentials
{
    return authenticationHandler != nil;
}

- (void)setAllowCredentials:(BOOL)allowCredentials
{
    authenticationHandler = (allowCredentials) ? [[AuthenticationHandler alloc] init] : nil;
}


#pragma mark - JPEG methods

+ (NSDate *)parseDate:(NSString *)dateString
{
	static NSDateFormatter * dateFormatter = nil;
	
	if (dateFormatter == nil)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss"];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	}
	
	return [dateFormatter dateFromString:dateString];
}

- (void)getLocationFromCGImageSource:(CGImageSourceRef)imageSource
{
	NSDictionary * properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
	
#if 0 // DEBUG log property values
	for (id key in properties) 
	{
		NSObject * value = [properties objectForKey:key];
		DDLogVerbose(@"JPEG property %@ = %@", key, value];
	}
#endif
	
	NSDictionary * gps = [properties objectForKey:@"{GPS}"];
	
	if (gps != nil)
	{
		NSString * latitudeString  = [gps objectForKey:@"Latitude"];
		NSString * latitudeRef     = [gps objectForKey:@"LatitudeRef"];
		NSString * longitudeString = [gps objectForKey:@"Longitude"];
		NSString * longitudeRef    = [gps objectForKey:@"LongitudeRef"];
		
		double latitude  = [latitudeString doubleValue];
		double longitude = [longitudeString doubleValue];
		
		if ([latitudeRef  isEqualToString:@"S"]) latitude  = -latitude;
		if ([longitudeRef isEqualToString:@"W"]) longitude = -longitude;
		
		imageLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
	}
	
	NSDictionary * tiff = [properties objectForKey:@"{TIFF}"];
	
	if (tiff != nil)
	{
		NSString * timestamp = [tiff objectForKey:@"DateTime"];
		imageTime = NSStringIsNilOrEmpty(timestamp) ? nil : [MotionJpegStream parseDate:timestamp];
		
		NSArray * frameInfo = [[tiff objectForKey:@"ImageDescription"] componentsSeparatedByString:@","];
		
		if ((frameInfo != nil) && ([frameInfo count] == 2))
		{
			imageSessionId = [[frameInfo objectAtIndex:0] intValue];
			imageFrameId   = [[frameInfo objectAtIndex:1] intValue];
		}
	}
	
}

- (void)makeJpegImage
{
	// make copy of image data buffer to prevent overwriting before image is displayed
	NSData * data = [imageData copy];
	
	NSDictionary * imageOptions  = [NSDictionary dictionaryWithObjectsAndKeys:(NSString *)kUTTypeJPEG, kCGImageSourceTypeIdentifierHint, nil];
	CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, 
															   (__bridge CFDictionaryRef)imageOptions);
	
	if (imageSource == NULL)
	{
		DDLogWarn(@"Unable to create image source");
		return;
	}
	
	CGImageSourceStatus imageStatus = CGImageSourceGetStatus(imageSource);
	
	if (imageStatus != kCGImageStatusComplete)
	{
		DDLogWarn(@"Unable to create image. Status=%d", imageStatus);
		CFRelease(imageSource);
		return;
	}
	
	[self getLocationFromCGImageSource:imageSource];
	CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
	
	if (cgImage == NULL)
	{
		DDLogWarn(@"Unable to create CGImage");
		CFRelease(imageSource);
		return;
	}
	
    UIImage * image = [UIImage imageWithCGImage:cgImage];
	
	if (image != nil)
	{
		[self.delegate didGetImage:image location:imageLocation time:imageTime sessionId:imageSessionId frameId:imageFrameId];
	}
	else
	{
		DDLogWarn(@"Unable to create image");
	}
	
	CGImageRelease(cgImage);
	CFRelease(imageSource);
}


#pragma mark - Session data methods

- (void)didReceiveSessionData:(NSData *)data
{
	[sessionData appendData:data];
}

- (void)handleSessionData
{
	SessionHandler * sessionHandler = [[SessionHandler alloc] init];
	[sessionHandler parseResponse:sessionData];
	Session * session = sessionHandler.result;
	
	if (session != nil)
	{
		[self.delegate didGetSession:session];
	}
	
	sessionData = nil;
}


#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode != 200)
	{
		NSString * stringForStatusCode = [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode];
		DDLogWarn(@"Received http error (%d) : %@", httpResponse.statusCode, stringForStatusCode);
        NSString * errorDescription = [NSString stringWithFormat:@"Unable to connect to video feed: %@", stringForStatusCode];
		responseError = [RvError rvErrorWithLocalizedDescription:errorDescription];
		return;
    }
	
#ifdef RV_MJPEG_MULTIPART_HEADERS
	// 
	// NSURLConnection does not provide access to multipart headers other than content-type (iOS 4.1)
	// see https://devforums.apple.com/message/287096
	// Problem ID 8487876 https://bugreport.apple.com 
	// 
	NSDictionary * headers = [httpResponse allHeaderFields];
	NSString * latitudeString  = [headers objectForKey:REALITYVISION_LATITUDE_HEADER];
	NSString * longitudeString = [headers objectForKey:REALITYVISION_LONGITUDE_HEADER];
	
	if (! (NSStringIsNilOrEmpty(latitudeString) || NSStringIsNilOrEmpty(longitudeString)))
	{
		double latitude = [latitudeString doubleValue];
		double longitude = [longitudeString doubleValue];
		imageLocation = [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
	}
	
	// debug code
	for (id key in headers) 
	{
		DDLogVerbose(@"HTTP response header %@ = %@", key, [headers objectForKey:key]];
	}
#endif

	NSString * contentType = [[response MIMEType] lowercaseString];
	if (contentType != nil)
	{
		if ([contentType rangeOfString:MIME_MULTIPART].location != NSNotFound)
		{
			isMultipart = YES;
		}
		else if (isMultipart)
		{
			BOOL isSessionData = [contentType rangeOfString:MIME_XML].location != NSNotFound;
			
			if (isSessionData)
			{
				sessionData = [NSMutableData dataWithCapacity:SESSION_BUFFER_INITIAL_SIZE];
			}
			else if (readSessionData)
			{
				// we've read the session data so parse it
				[self handleSessionData];
			}
			
			readSessionData = isSessionData;
		}
	}
	
	// reset jpeg search
	soiFound = NO;
	lastByte = 0;
	imageLocation = nil;
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	if (readSessionData)
	{
		[self didReceiveSessionData:data];
		return;
	}
	
	// current byte in data buffer
	const char * thisByte = [data bytes];
	NSUInteger bytesRemaining = [data length];
	
	// image data to copy from current buffer
	const char * startOfImageData = soiFound ? thisByte : NULL;
	NSUInteger dataLength = 0;
	
	while (bytesRemaining > 0)
	{
		if ((lastByte == JPEG_MARKER) && (*thisByte == JPEG_SOI))
		{
			if (soiFound)
				DDLogWarn(@"MotionJpegStream didReceiveData: Second SOI before EOI.");
			
			soiFound = YES;
			startOfImageData = thisByte;
			dataLength = 0;
			
			// buffer already has the initial JPEG_MARKER byte
			[imageData setLength:1];
		}
		
		if (soiFound)
		{
			dataLength++;
			
			if ((lastByte == JPEG_MARKER) && (*thisByte == JPEG_EOI))
			{
				[imageData appendBytes:startOfImageData length:dataLength];
				[self makeJpegImage];
				soiFound = NO;
				startOfImageData = NULL;
				dataLength = 0;
			}
		}
	
		lastByte = *thisByte;
		thisByte++;
		bytesRemaining--;
	}
	
	if (dataLength > 0)
	{
		[imageData appendBytes:startOfImageData length:dataLength];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    DDLogVerbose(@"MotionJpegStream didFinishLoading");
	[self connectionIsComplete];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
	DDLogError(@"MotionJpegStream didFailWithError: %@", error);
	responseError = authenticationHandler.authenticationError ? authenticationHandler.authenticationError : error;
	[self connectionIsComplete];
}

- (void)connectionIsComplete
{
	DDLogVerbose(@"MotionJpegStream connectionIsComplete");
	isClosed = YES;
	if (connection != nil)
	{
		connection = nil;
		[RealityVisionAppDelegate didStopNetworking];
		[authenticationHandler connectionIsComplete:connection];
		
		if (responseError != nil)
		{
			[self.delegate streamClosedWithError:responseError];
			responseError = nil;
		}
		else 
		{
			[self.delegate streamDidEnd];
		}
	}
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)conn
{
	return [authenticationHandler connectionShouldUseCredentialStorage:conn];
}

- (BOOL)connection:(NSURLConnection *)conn canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return [authenticationHandler connection:conn canAuthenticateAgainstProtectionSpace:protectionSpace];
}

- (void)connection:(NSURLConnection *)conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	return [authenticationHandler connection:conn didReceiveAuthenticationChallenge:challenge];
}

@end
