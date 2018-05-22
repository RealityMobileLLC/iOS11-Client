//
//  HeadRequest.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebService.h"


/**
 *  Delegate used by the HeadRequest class. 
 */
@protocol HeadRequestDelegate <NSObject>

/**
 *  Called when the server sends a response to the HEAD request.
 *
 *  @param error An error if one occurred or nil if the operation completed
 *               successfully.
 */
- (void)headRequestDidGetResponseOrError:(NSError *)error;

@end


/**
 *  Used to send an HTTP HEAD request to a server.  A HEAD request is used
 *  to verify server accessibility and client authentication.
 *
 *  @todo Currently not using HeadRequest but may need to later to provide 
 *        authentication for some services (i.e. transmit).
 */
@interface HeadRequest : WebService 

/**
 *  The delegate that is notified when the request is complete.
 */
@property (weak) id <HeadRequestDelegate> delegate;

/**
 *  Initializes a HeadRequest object.
 *
 *  @param url      The URL to send the request to.
 *  @param delegate The delegate to notify when the request is complete.
 * 
 *  @return An initialized HeadRequest object or nil if the object could not
 *           be initialized.
 */
- (id)initWithUrl:(NSURL *)url 
		 delegate:(id <HeadRequestDelegate>)delegate;

/**
 *  Sends the HEAD request asynchronously.
 *
 *  When the operation has completed, the -headRequestDidGetResponseOrError
 *  message will be sent to the delegate.
 */
- (void)send;

@end
