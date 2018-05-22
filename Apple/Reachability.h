/*
 
 File: Reachability.h
 Abstract: Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 
 Version: 2.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
*/

//
// 06/06/11 Added XMLdoc comments for use in RealityVision. Other than that, we are using code as-is.
// 10/05/11 Added import <netinet/in.h> to remove compiler warnings
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

/**
 *  Network reachability status.
 */
typedef enum {
	ReachabilityUnknown = -1,  /**< Used to indicate reachibility is not being monitored. Never returned by Reachability class. */
	NotReachable = 0,          /**< Host is not reachable. */
	ReachableViaWiFi,          /**< Host is reachable via WiFi. */
	ReachableViaWWAN           /**< Host is reachable via Wireless Wide Area Network (cellular). */
} NetworkStatus;


/**
 *  Name of notification that can be used to determine when a Reachability object's network
 *  status has changed.
 */
#define kReachabilityChangedNotification @"kNetworkReachabilityChangedNotification"


/**
 *  Uses the SCNetworkReachability APIs to monitor the network state of an iOS device and
 *  get asynchronous notifications of state changes.  To use, create a Reachability object
 *  for the host or type of network connection to be monitored and then call startNotifier
 *  to start monitoring it on the current run loop.  To receive asynchronous notifications
 *  when a connection's network status changes, register for kReachabilityChangedNotification
 *  notifications.
 */
@interface Reachability: NSObject
{
	BOOL localWiFiRef;
	SCNetworkReachabilityRef reachabilityRef;
}


/**
 *  Creates a Reachability object to check the reachability of a particular host name.
 */
+ (Reachability*) reachabilityWithHostName: (NSString*) hostName;


/**
 *  Creates a Reachability object to check the reachability of a particular IP address.
 */
+ (Reachability*) reachabilityWithAddress: (const struct sockaddr_in*) hostAddress;


/**
 *  Creates a Reachability object to check whether the default route is available.
 *  Should be used by applications that do not connect to a particular host.
 */
+ (Reachability*) reachabilityForInternetConnection;


/**
 *  Creates a Reachability object to check whether a local WiFi connection is available.
 *  Should be used by applications that do not connect to a particular host.
 */
+ (Reachability*) reachabilityForLocalWiFi;


/**
 *  Start listening for reachability notifications on the current run loop.
 */
- (BOOL) startNotifier;


/**
 *  Stop listening for reachability notifications on the current run loop.
 */
- (void) stopNotifier;


/**
 *  Current network reachability status.
 */
- (NetworkStatus) currentReachabilityStatus;


/**
 *  Indicates whether a connection is required.  
 *  WWAN may be available, but not active until a connection has been established.
 *  WiFi may require a connection for VPN on Demand.
 */
- (BOOL) connectionRequired;

@end


