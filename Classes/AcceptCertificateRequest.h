//
//  AcceptCertificate.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/1/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Delegate used by AcceptCertificate to indicate whether the user has
 *  accepted a certificate.
 */
@protocol AcceptCertificateDelegate

/**
 *  Called when the user has chosen to accept or decline a certificate.
 *
 *  @param accepted Indicates whether user has accepted the certificate.
 */
- (void)certificateAccepted:(BOOL)accepted;

@end


/**
 *  Used to prompt the user to accept a server trust certificate.  Ensures
 *  that only a single prompt is presented to the user when there are multiple
 *  outstanding requests to the same server.
 *  
 *  Objects of this class should never be allocated directly.  Users should
 *  call +acceptCertificate:forHost:delegate: to prompt the user for a given
 *  server and certificate combination.
 */
@interface AcceptCertificateRequest : NSObject 

/**
 *  Prompts the user to accept a server trust certificate for the given host.
 *  If a prompt is already displayed, it adds the delegate to the list of
 *  objects to notify with the user's response.
 *  
 *  @param subject  Subject of the certificate provided by the host.
 *  @param host     Server being authenticated.
 *  @param delegate Object to notify when user responds.
 */
+ (void)acceptCertificate:(NSString *)subject
				  forHost:(NSString *)host 
				 delegate:(id <AcceptCertificateDelegate>)delegate;

@end
