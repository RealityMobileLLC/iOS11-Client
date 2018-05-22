//
//  MotionJpegTransmitClient.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/1/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "MotionJpegTransmitClient.h"
#include <CFNetwork/CFNetwork.h>
#import "ClientConfiguration.h"
#import "Base64.h"
#import "AuthenticationHandler.h"
#import "ConfigurationManager.h"
#import "RealityVisionAppDelegate.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

// @todo ios4 needed because of apparent ios 4 bug when cleaning up the producer and consumer streams in NSURLConnection
//#define RV_SUPPORT_IOS4

//#define RV_LOGS_ASYNC_TRANSMIT

#define NANOSECONDS_PER_SECOND (1000 * 1000 * 1000)

@interface MotionJpegTransmitClient (DispatchQueue)

- (void)createTransmitFrame:(NSData *)jpegData withGpgga:(NSString *)gpgga;
- (void)scheduleSendNextChunk;
- (void)sendNextChunk;
- (void)sendEndOfTransmit;
- (void)releaseFrameBuffer;

@end


@implementation MotionJpegTransmitClient
{
	id <TransmitClientDelegate> delegate;
	
	NSURL                 * url;
	NSURLCredential       * credential;
	BOOL                    archive;
	int                     targetBitRate;
	int                     intervalFrameCount;
	int                     intervalBytesSent;
	NSDate                * intervalStartTime;
	double                  frameRate;
	double                  bitRate;
	
	BOOL                    isOpen;
    int64_t                 writeDelay;
	int64_t                 writeDelayDelta;
	
	// The producer and consumer streams are bound so that anything written to the producer
	// is automatically consumed by the consumer.  The consumerStream is used as the body
	// stream for the NSURLConnection.  This lets us write image data to the producer as it
	// becomes available, and have that automatically flow through to the server as part of
	// the HTTP body.
    NSOutputStream        * producerStream;
    NSInputStream         * consumerStream;
	NSURLConnection       * connection;
	AuthenticationHandler * authenticationHandler;
	
	// the following variables should only be modified on the dispatch queue
	dispatch_queue_t        dispatchQueue;
	NSMutableData         * frameBuffer;
	NSUInteger              bufferOffset;
	BOOL                    readyToSend;
}

@synthesize archive;
@synthesize targetBitRate;
@synthesize isOpen;
@synthesize frameRate;
@synthesize bitRate;


#pragma mark - Initialization and cleanup

- (id)initWithUrl:(NSURL *)transmitUrl 
	   credential:(NSURLCredential *)transmitCredential 
		 delegate:(id <TransmitClientDelegate>)transmitDelegate
{
	NSAssert(transmitUrl!=nil,@"url can't be null");
	NSAssert(transmitDelegate!=nil,@"delegate can't be null");
	
	self = [super init];
	if (self != nil)
	{
		dispatchQueue = dispatch_queue_create("transmit-client-queue", NULL);

		if (dispatchQueue != NULL)
		{
			url = transmitUrl;
			credential = transmitCredential;
			authenticationHandler = [[AuthenticationHandler alloc] init];
			delegate = transmitDelegate;
			consumerStream = nil;
			producerStream = nil;
			archive = YES;
			targetBitRate = -1;
			writeDelayDelta = 0.0;
			isOpen = NO;
		}
		else
		{
			DDLogError(@"Could not create dispatch queue");
			self = nil;
		}
	}
	
	return self;
}

- (void)dealloc
{
	[self close];
	//dispatch_release(dispatchQueue);
}


#pragma mark - Public methods

- (BOOL)open:(NSError **)error
{
	NSAssert([NSThread isMainThread],@"open must be called on the main thread");
	NSAssert(isOpen==NO,@"client is already open");
	NSAssert(frameBuffer==nil,@"frameBuffer already exists");
	NSAssert(producerStream==nil,@"producerStream already exists");
	NSAssert(consumerStream==nil,@"consumerStream already exists");
	
	DDLogInfo(@"Opening transmit client for %@",[url absoluteString]);
	
	BOOL requireSslForCredentials = [ConfigurationManager instance].requireSslForCredentials;
	BOOL connectionIsSecure = [[url scheme] isEqualToString:@"https"];
	
	if ((credential == nil) || (! requireSslForCredentials) || (connectionIsSecure))
	{
		// initialize statistics
		[self resetStatistics];
		
		// create buffer to hold data for a single frame
		const int BUFFER_SIZE = 32 * 1024;
		frameBuffer = [NSMutableData dataWithCapacity:BUFFER_SIZE];
		bufferOffset = 0;
		readyToSend = NO;
		
		// create bound producer and consumer socket streams
		[MotionJpegTransmitClient createBoundInputStream:&consumerStream 
											outputStream:&producerStream 
											  bufferSize:BUFFER_SIZE];
		
		// the producer stream is used to write out image data as it is received
		// stream buffering is managed by the stream:handleEvent: method
		producerStream.delegate = self;
		[producerStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[producerStream open];
		
		// create a URLRequest for an HTTP PUT to the video server to start the transmit session
		// the consumer stream is used as the body for this request to allow us to stream an
		// arbitrary amount of data without having to provide a content-length
		NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url 
																	cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData 
																timeoutInterval:60];
		[request setHTTPMethod:@"PUT"];
        [request setHTTPBodyStream:consumerStream];
		
		if (credential != nil)
		{
			DDLogVerbose(@"Adding credential to HTTP request");
			NSString   * userAndPasswordString = [NSString stringWithFormat:@"%@:%@", credential.user, credential.password];
			const char * userAndPassword       = [userAndPasswordString cStringUsingEncoding:[NSString defaultCStringEncoding]];
			
			[request setValue:[NSString stringWithFormat:@"Basic %@", [Base64 encodeCString:userAndPassword urlSafe:NO]] forHTTPHeaderField: @"Authorization"];
		}
		
		[request setValue:@"multipart/x-mixed-replace; boundary=myboundary" forHTTPHeaderField:@"Content-Type"];
		//[request setValue:@"100-continue"                forHTTPHeaderField:@"Expect"];
		[request setValue:(archive ? @"true" : @"false") forHTTPHeaderField:@"X-RealityMobile-Archive"];
		[request setValue:@"Camera"                      forHTTPHeaderField:@"X-RealityMobile-Client-Type"];
		[request setValue:@"5.0"                         forHTTPHeaderField:@"X-RealityMobile-RV"];
		
		// create connection to send request and manage response
		[RealityVisionAppDelegate didStartNetworking];
		connection = [NSURLConnection connectionWithRequest:request delegate:self];
		
		isOpen = YES;
	}
	else if (error != NULL)
	{
		*error = [RvError rvErrorWithLocalizedDescription:NSLocalizedString(@"Can not send credentials over non-secure connection.",
                                                                            @"Can not send credentials over non-secure connection.")];
	}
	
	return isOpen;
}

- (void)closeWithError:(NSError *)error
{
	if (isOpen)
	{
		DDLogVerbose(@"Closing transmit client");

		// don't send any more frames
		isOpen = NO;
		
		if (frameBuffer != nil)
		{
			if (error == nil)
			{
				// send end of stream marker
				dispatch_async(dispatchQueue, ^{ [self sendEndOfTransmit]; });
			}
			
			// flush the dispatch queue and release the frame buffer
			dispatch_sync(dispatchQueue, ^{ [self releaseFrameBuffer]; });
			
			// notify delegate in case it's waiting on a pending write
			[delegate writeDidComplete:nil];
		}
		
		if (connection != nil)
		{
			[authenticationHandler connectionIsComplete:connection];
            
            if (error == nil)
            {
                // if called from connection:didFailWithError: we don't want to deallocate the connection
                [connection cancel];
                connection = nil;
            }
		}
		
		if (producerStream != nil)
		{
			[producerStream close];
			[producerStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			producerStream.delegate = nil;
			
#ifdef RV_SUPPORT_IOS4
			CFRelease((__bridge CFWriteStreamRef)producerStream);
#endif
			producerStream = nil;
		}
		
		if (consumerStream != nil)
		{
			
#ifdef RV_SUPPORT_IOS4
			CFRelease((__bridge CFReadStreamRef)consumerStream);
#endif
			consumerStream = nil;
		}
		
		[RealityVisionAppDelegate didStopNetworking];
		
		if (error != nil)
		{
			[delegate clientClosedWithError:error];
		}
	}
}

- (void)close
{
	[self closeWithError:nil];
}

- (void)writeJpegData:(NSData *)jpegData withGpgga:(NSString *)gpgga
{
	dispatch_async(dispatchQueue, ^{ [self createTransmitFrame:jpegData withGpgga:gpgga]; });
}

- (void)writeJpegData:(NSData *)jpegData
{
	dispatch_async(dispatchQueue, ^{ [self createTransmitFrame:jpegData withGpgga:nil]; });
}

- (void)setTargetBitRate:(int)newBitRate
{
    targetBitRate = newBitRate;
	
	if (targetBitRate > 0.0)
	{
		writeDelayDelta = (int64_t)((500.0 / (double)targetBitRate) * 0.05 * NANOSECONDS_PER_SECOND);
	}
}

- (void)resetStatistics
{
	writeDelay = 0;
	intervalFrameCount = 0;
	intervalBytesSent = 0;
	frameRate = 0.0;
	bitRate = 0.0;
	intervalStartTime = [NSDate date];
}

- (void)computeStatistics
{
	NSDate * timeNow = [NSDate date];
	NSTimeInterval elapsedSeconds = [timeNow timeIntervalSinceDate:intervalStartTime];
	
	double newFrameRate = intervalFrameCount / elapsedSeconds;
	frameRate += (newFrameRate - frameRate) / 10.0;
	
	double newBitRate = (8.0 * intervalBytesSent / elapsedSeconds) / 1024.0;
	bitRate += (newBitRate - bitRate) / 10.0;
	
	intervalStartTime = timeNow;
	intervalFrameCount = 0;
	intervalBytesSent = 0;
}


#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
	// because we are using a stream for the NSURLRequest body, this will never get called
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	// because we are using a stream for the NSURLRequest body, this will never get called
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	// because we are using a stream for the NSURLRequest body, this will never get called
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
	DDLogError(@"MotionJpegTransmitClient didFailWithError: %@", error);
	NSError * actualError = authenticationHandler.authenticationError ? authenticationHandler.authenticationError : error;
	[self closeWithError:actualError];
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
{
	// this doesn't appear to ever be called ... though it might if we used EXPECT=100-CONTINUE
	DDLogVerbose(@"MotionJpegTransmitClient needsNewBodyStream");
	return consumerStream;
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
	[authenticationHandler connection:conn didReceiveAuthenticationChallenge:challenge];
}


#pragma mark - NSStreamDelegate methods

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
    NSAssert(theStream==producerStream,@"Received event for unexpected stream");
	
    switch (streamEvent) 
	{
        case NSStreamEventOpenCompleted:
			DDLogVerbose(@"producer stream opened");
			break;
			
        case NSStreamEventHasBytesAvailable:
			// should never happen
			DDLogWarn(@"producer stream received NSStreamEventHasBytesAvailable");
			break;
			
        case NSStreamEventHasSpaceAvailable: 
			{
				//DDLogVerbose(@"  producer stream hasSpaceAvailable");
				dispatch_async(dispatchQueue, ^{ readyToSend = YES; [self scheduleSendNextChunk]; });
			}
			break;
			
        case NSStreamEventErrorOccurred: 
			DDLogError(@"producer stream error %@", [theStream streamError]);
			break;
			
        case NSStreamEventEndEncountered: 
			DDLogWarn(@"producer stream received NSStreamEventEndEncountered");
			break;
			
        default:
			DDLogWarn(@"producer stream received unexpected event");
			break;
    }
}


#pragma mark - Private methods

//
//  Wrapper around CFStreamCreateBoundPair.  As with CFStreamCreateBoundPair, ownership of the
//  streams follows the Create Rule, so the created streams are owned by the caller.
//
+ (void)createBoundInputStream:(NSInputStream * __strong *)inputStreamPtr
                  outputStream:(NSOutputStream * __strong *)outputStreamPtr 
                    bufferSize:(NSUInteger)bufferSize
{
	NSAssert(inputStreamPtr||outputStreamPtr,@"Must provide inputStreamPtr or outputStreamPtr");
	
    CFReadStreamRef  readStream  = NULL;
    CFWriteStreamRef writeStream = NULL;
	
    CFStreamCreateBoundPair(NULL, 
                            ((inputStreamPtr  != NULL) ? &readStream  : NULL),
                            ((outputStreamPtr != NULL) ? &writeStream : NULL), 
                            (CFIndex)bufferSize);
    
    if (inputStreamPtr != NULL) 
	{
#ifdef RV_SUPPORT_IOS4
		CFRetain(readStream);
        *inputStreamPtr  = (__bridge NSInputStream *)readStream;
#else
        *inputStreamPtr  = (__bridge_transfer NSInputStream *)readStream;
#endif
    }
    
	if (outputStreamPtr != NULL) 
	{
#ifdef RV_SUPPORT_IOS4
		CFRetain(writeStream);
        *outputStreamPtr  = (__bridge NSOutputStream *)writeStream;
#else
        *outputStreamPtr = (__bridge_transfer NSOutputStream *)writeStream;
#endif
    }
}


#pragma mark - Dispatch queue methods

- (void)createTransmitFrame:(NSData *)jpegData withGpgga:(NSString *)gpgga
{
	if (isOpen)
	{
		if (bufferOffset != [frameBuffer length])
		{
			DDLogError(@"Previous frame not finished sending. Buffer length = %d, offset = %d",
					   [frameBuffer length], bufferOffset);
			return;
		}

#ifdef RV_LOGS_ASYNC_TRANSMIT		
		DDLogVerbose(@"*** start frame ***");
#endif
		
		// create headers
		NSMutableString *multipartHeaders = [NSMutableString stringWithCapacity:200];
		[multipartHeaders appendString:@"--myboundary\r\n"];
		[multipartHeaders appendString:@"Content-Type: image/jpeg\r\n"];
		[multipartHeaders appendFormat:@"Content-Length: %d\r\n", [jpegData length]];
		if (gpgga != nil)
		{
			[multipartHeaders appendFormat:@"X-RealityMobile-Gpgga: %@\r\n", gpgga];
		}
		[multipartHeaders appendString:@"\r\n"];
		
		// place header and jpeg data in buffer
		bufferOffset = 0;
		[frameBuffer setLength:0];
		[frameBuffer appendData:[multipartHeaders dataUsingEncoding:NSASCIIStringEncoding]];
		if (jpegData != nil)
		{
			[frameBuffer appendData:jpegData];
		}
		
#ifdef RV_LOGS_ASYNC_TRANSMIT		
		DDLogVerbose(@"  total frame size = %d",[frameBuffer length]);
#endif
		
		// write as much as we can to the output stream
		[self scheduleSendNextChunk];
	}
}

- (void)frameComplete
{
	intervalFrameCount++;
	[delegate writeDidComplete:nil];
}

- (void)updateBitRate:(int)bytesSent
{
	intervalBytesSent += bytesSent;
}

- (void)scheduleSendNextChunk
{
	NSUInteger bytesToWrite = [frameBuffer length] - bufferOffset;
	
	if ((readyToSend) && (bytesToWrite > 0))
	{
		if (targetBitRate <= 0)
		{
			[self sendNextChunk];
			return;
		}
		
		// incrementally increase or decrease delay in writing data until target bit rate is reached
		writeDelay += (bitRate <= targetBitRate) ? (-writeDelayDelta) : writeDelayDelta;
		writeDelay = MAX(writeDelay, 0.0);
		
#ifdef RV_LOGS_ASYNC_TRANSMIT		
		DDLogVerbose(@"  scheduleSendNextChunk: bitRate = %.1f target = %d delay=%llu", bitRate, targetBitRate, writeDelay);
#endif

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, writeDelay), dispatchQueue, ^{ [self sendNextChunk]; });
	}
}

- (void)sendNextChunk
{
	NSUInteger bytesToWrite = [frameBuffer length] - bufferOffset;
	
	if ((readyToSend) && (bytesToWrite > 0))
	{
		const uint8_t * buffer = frameBuffer.bytes;
		NSInteger bytesWritten = [producerStream write:&buffer[bufferOffset] 
											 maxLength:bytesToWrite];
		
		if (bytesWritten > 0) 
		{
#ifdef RV_LOGS_ASYNC_TRANSMIT		
			DDLogVerbose(@"  sent %d bytes",bytesWritten);
#endif

            [self updateBitRate:bytesWritten];
			
			if (bytesWritten < bytesToWrite)
			{
#ifdef RV_LOGS_ASYNC_TRANSMIT		
				DDLogVerbose(@"  waiting for hasSpaceAvailable");
#endif
				// wait for stream to be ready for more data
				readyToSend = NO;
			}
			else 
			{
#ifdef RV_LOGS_ASYNC_TRANSMIT		
				DDLogVerbose(@"*** frame complete ***");
#endif
				[self frameComplete];
			}
			
			bufferOffset += bytesWritten;
		}
		else
		{
			DDLogError(@"Network write error: %@", [[producerStream streamError] localizedDescription]);
			[delegate writeDidComplete:[producerStream streamError]];
		}
	}
}

- (void)sendEndOfTransmit
{
	[frameBuffer appendData:[@"--myBoundary--\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
	[self scheduleSendNextChunk];
}

- (void)releaseFrameBuffer
{
	frameBuffer = nil;
	bufferOffset = 0;
}

@end
