//
//  WebService.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AuthenticationHandler;


/**
 *  Base class for managing RESTful web service requests.
 *
 *  This class provides a mechanism for sending an HTTP GET or POST
 *  request to a RESTful web service and getting the response.
 */
@interface WebService : NSObject

/**
 *  Indicates whether the RealityVision Device ID should be sent in a custom HTTP header.
 *  Defaults to YES.
 */
@property (nonatomic) BOOL sendDeviceId;

/**
 *  Initializes a WebService object.
 *
 *  @param service The name of the service.
 *  @param baseUrl The base URL for the web services.
 *
 *  @return An initialized WebService object or nil if the object could
 *           not be initialized.
 */
- (id)initService:(NSString *)service withUrl:(NSURL *)baseUrl;

/**
 *  Sends an HTTP GET request to a web service method.
 *
 *  The full URL for the request is in the format:
 *    baseUrl\\service\\method(?query)
 *
 *  The request is sent asynchronously.  When complete, the
 *  -didGetResponse:orError: method is called.
 *  
 *  @param method The name of the web service method.
 *  @param query  A query string containing web service parameters or nil if
 *                the web service does not take any parameters.
 */
- (void)getFromMethod:(NSString *)method 
				query:(NSString *)query;

/**
 *  Sends an HTTP PUT request to a web service method.
 *
 *  The full URL for the request is in the format:
 *    baseUrl\\service\\method(?query)
 *
 *  The request is sent asynchronously.  When complete, the
 *  -didGetResponse:orError: method is called.
 *  
 *  @param method The name of the web service method.
 *  @param query  A query string containing web service parameters or nil if
 *                the web service does not take any parameters.
 *  @param data   Data to be sent in the body of the POST request.
 */
- (void)postToMethod:(NSString *)method 
			   query:(NSString *)query  
				data:(NSData *)data;

/**
 *  Sends an HTTP HEAD request to the web service's baseUrl.
 */
- (void)headRequest;

/**
 *  Used to make a generic HTTP request not necessarily tied to a web service.
 *  The response is ignored.
 *  
 *  @param request The URL request to make.
 */
- (void)doHttpRequest:(NSURLRequest *)request;

/**
 *  Called when the request is complete.
 *
 *  Descendent classes must implement this method to get the HTTP response
 *  or error.
 *
 *  @param data  The body of the HTTP response from the server.
 *  @param error An error object, if one occurred, or nil if the request
 *               completed successfully.
 */
- (void)didGetResponse:(NSData *)data orError:(NSError *)error;

/**
 *  Cancels a web service request.
 */
- (void)cancel;

@end
