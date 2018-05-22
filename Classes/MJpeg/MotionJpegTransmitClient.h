//
//  MotionJpegTransmitClient.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/1/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AuthenticationHandler;


/**
 *  Delegate used by the MotionJpegTransmitClient.
 */
@protocol TransmitClientDelegate

/**
 *  Called when a writeJpegData operation has completed.
 *
 *  @param error Identifies an error that occurred while writing or nil if the
 *               operation completed successfully.
 */
- (void)writeDidComplete:(NSError *)error;

/**
 *  Called when the connection to the server is closed.
 *
 *  @param error Identifies an error that caused the connection to close or nil 
 *               if no error occurred.
 */
- (void)clientClosedWithError:(NSError *)error;

@end


/**
 *  Manages a video transmit session to a RealityVision Video Server.
 *
 *  The MotionJpegTransmitClient sends an unlimited length multipart 
 *  Motion-JPEG stream inside the request entity of an HTTP PUT request.
 *
 *  Writing each frame is asynchronous.  The delegate is notified when
 *  each write operation completes via the -writeDidComplete: message.
 *
 *  If the connection to the server is closed, the delegate is notified by
 *  the -clientClosedWithError: message.
 *
 *  To prevent buffer overflow and memory leaks, there can be only one
 *  outstanding write operation at a time.  After each call to -writeJpegData:
 *  or -writeJpegData:withGpgga:, the caller must wait for the delegate to
 *  receive a corresponding -writeDidComplete: message before calling one of
 *  the -writeJpegData: methods again.
 *
 *  @todo The credential is provided in init because we need to authenticate 
 *        before sending data.  A better way to do this would be to use an
 *        HTTP HEAD request to pre-authenticate before streaming video.
 */
@interface MotionJpegTransmitClient : NSObject <NSStreamDelegate>

/**
 *  Indicates whether the video data should be archived by the server.
 *  Defaults to YES.
 */
@property (nonatomic) BOOL archive;

/**
 *  The target bit rate used for bandwidth throttling.
 *  Defaults to sending data as fast as possible.
 */
@property (nonatomic) int targetBitRate;

/**
 *  Indicates whether the connection to the server is open.
 */
@property (nonatomic,readonly) BOOL isOpen;

/**
 *  The current average bit rate for the transmission in kbps.  This value
 *  is calculated by computeStatistics which must be called at a regular
 *  fixed interval.
 */
@property (nonatomic,readonly) double bitRate;

/**
 *  The current average frame rate for the transmission.  This value
 *  is calculated by computeStatistics which must be called at a regular
 *  fixed interval.
 */
@property (nonatomic,readonly) double frameRate;

/**
 *  Initializes a MotionJpegTransmitClient.
 *
 *  @param url        The url for the RealityVision Video Transmit service.
 *  @param credential The credential to use when connecting.
 *  @param delegate   The delegate to notify when asynchronous events complete.
 *
 *  @return An initialized MotionJpegTransmitClient or nil if the object
 *           could not be initialized.
 */
- (id)initWithUrl:(NSURL *)url 
	   credential:(NSURLCredential *)credential 
		 delegate:(id <TransmitClientDelegate>)delegate;

/**
 *  Opens the connection to the server.
 *
 *  @param error A pointer to a NSError object to use if an error occurs while
 *               trying to open the connection.
 *
 *  @return YES if opened successfully or NO if an error occurred.
 */
- (BOOL)open:(NSError **)error;

/**
 *  Closes the connection to the server and flushes all pending writes.
 */
- (void)close;

/**
 *  Sends a video frame with a geographic location to the server.
 *
 *  This call is asynchronous and will return before the write has completed.
 *  The delegate gets sent a -writeDidComplete: message when the operation
 *  has completed or an error occurred.
 *
 *  This method must not be called again until the delegate receives the
 *  -writeDidComplete: message.
 *
 *  @param jpegData The video frame in JPEG format.
 *  @param gpgga    A GPGGA string representing the geographic location at 
 *                  which the frame was taken.
 */
- (void)writeJpegData:(NSData *)jpegData withGpgga:(NSString *)gpgga;

/**
 *  Sends a video frame to the server.
 *
 *  This call is asynchronous and will return before the write has completed.
 *  The delegate gets sent a -writeDidComplete: message when the operation
 *  has completed or an error occurred.
 *
 *  This method must not be called again until the delegate receives the
 *  -writeDidComplete: message.
 *
 *  @param jpegData The video frame in JPEG format.
 */
- (void)writeJpegData:(NSData *)jpegData;

/**
 *  Resets the frame rate and bit rate statistics.
 */
- (void)resetStatistics;

/**
 *  Updates the frame rate and bit rate statistics using an exponentially
 *  smoothed moving average.  This method should be called at a fixed, regular
 *  interval, like once per second.
 */
- (void)computeStatistics;

@end
