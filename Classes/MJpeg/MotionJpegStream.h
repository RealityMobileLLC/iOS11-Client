//
//  MotionJpegStream.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/7/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class AuthenticationHandler;
@class Session;


/**
 *  Protocol used to provide images read from a MotionJpegStream.
 */
@protocol MotionJpegStreamDelegate

enum
{
	kRVNoSessionId = 0,
	kRVNoFrameId = -1
};

/**
 *  Used to notify a delegate that session data was received.
 */
- (void)didGetSession:(Session *)session;

/**
 *  Used to notify a delegate that an image was recieved.
 */
- (void)didGetImage:(UIImage *)image 
		   location:(CLLocation *)location 
			   time:(NSDate *)timestamp 
		  sessionId:(int)sessionId 
			frameId:(int)frameId;

/**
 *  Used to notify a delegate that the stream ended.
 */
- (void)streamDidEnd;

/**
 *  Used to notify a delegate that the stream was closed due to error.
 */
- (void)streamClosedWithError:(NSError *)error;

@end


/**
 *  Reads images from an HTTP Motion-JPEG stream. 
 */
@interface MotionJpegStream : NSObject

/**
 *  Delegate to notify when events occur.
 */
@property (nonatomic,weak) id <MotionJpegStreamDelegate> delegate;

/**
 *  Indicates whether stream should allow user to enter credentials if challenged by server.
 *  Defaults to NO.
 */
@property (nonatomic) BOOL allowCredentials;

/**
 *  Indicates whether stream is closed.
 */
@property (nonatomic,readonly) BOOL isClosed;

/**
 *  Initializes a MotionJpegStream.
 *
 *  @param url The url for the Motion-JPEG stream.  Must use HTTP or HTTPS.
 *  @return An initialized MotionJpegStream or nil if the object could not be initialized.
 */
- (id)initWithUrl:(NSURL *)url;

/**
 *  Opens the HTTP connection.
 *
 *  @param error A pointer to a NSError object to use if an error occurs while
 *               trying to open the connection.
 *
 *  @return YES if opened successfully or NO if an error occurred.
 */
- (BOOL)open:(NSError **)error;

/**
 *  Closes the connection.
 */
- (void)close;

@end
