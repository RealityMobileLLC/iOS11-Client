//
//  CommandService.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/26/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "CommandService.h"
#import "CameraInfo.h"
#import "GuidHandler.h"
#import "QueryString.h"
#import "XmlFactory.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CommandService
{
	id <WebServiceResponseHandler> responseHandler;
    
    // state data needed to retry operation
    NSString    * method;
    QueryString * query;
    NSData      * data;
    NSError     * error;
}

@synthesize delegate;


#pragma mark - Initialization and cleanup

- (id)initWithUrl:(NSURL *)url andDelegate:(id <CommandServiceDelegate>)commandServiceDelegate
{
	self = [super initService:@"CommandService" withUrl:url];
	if (self != nil)
	{
		delegate = commandServiceDelegate;
        responseHandler = nil;
        method = nil;
        query = nil;
        data = nil;
	}
	return self;
}


#pragma mark - Public methods

- (void)postViewCameraUrl:(NSString *)viewingUrl 
                  caption:(NSString *)caption 
                isProxied:(BOOL)proxied 
              withMessage:(NSString *)message 
                       to:(NSArray *)recipients
{
    method = @"PostViewCamera";
    
    query = [[QueryString alloc] init];
	[query append:@"recipients" stringValue:@""];
    [query append:@"viewingUrl" stringValue:viewingUrl];
    [query append:@"proxied"    boolValue:proxied];
    [query append:@"caption"    stringValue:caption];
    [query append:@"message"    stringValue:message];
    
    data = [XmlFactory dataWithArrayOfRecipientElementNamed:@"recipients" recipients:recipients];
    
    responseHandler = [[GuidHandler alloc] init];
    [super postToMethod:method query:query.query data:data];
}


- (void)postViewCameraInfo:(CameraInfo *)camera 
               withMessage:(NSString *)message 
                        to:(NSArray *)recipients
{
    method = @"PostViewCameraInfo";
    
    query = [[QueryString alloc] init];
    [query append:@"recipients" stringValue:@""];
    [query append:@"camera"     stringValue:@""];
    [query append:@"message"    stringValue:message];
    
    GDataXMLElement * recipientsElement = [XmlFactory arrayOfRecipientElementNamed:@"recipients" recipients:recipients];
    GDataXMLElement * cameraElement = [XmlFactory cameraInfoElementNamed:@"camera" camera:camera];
    data = [XmlFactory dataWithRootElementNamed:@"params" 
                                        elements:[NSArray arrayWithObjects:recipientsElement, cameraElement, nil]];
    
    responseHandler = [[GuidHandler alloc] init];
    [super postToMethod:method query:query.query data:data];
}


- (void)postViewScreencast:(NSString *)screencastName 
                   caption:(NSString *)caption 
               withMessage:(NSString *)message 
                        to:(NSArray *)recipients
{
    method = @"PostViewScreencast";
    
    query = [[QueryString alloc] init];
	[query append:@"recipients"     stringValue:@""];
    [query append:@"screencastName" stringValue:screencastName];
    [query append:@"caption"        stringValue:caption];
    [query append:@"message"        stringValue:message];
    
    data = [XmlFactory dataWithArrayOfRecipientElementNamed:@"recipients" recipients:recipients];
    
    responseHandler = [[GuidHandler alloc] init];
    [super postToMethod:method query:query.query data:data];
}


- (void)postViewUserFeed:(NSString *)deviceId 
             withMessage:(NSString *)message
                      to:(NSArray *)recipients
{
    method = @"PostViewUserFeed";
    
    query = [[QueryString alloc] init];
	[query append:@"recipients" stringValue:@""];
    [query append:@"deviceId"   stringValue:deviceId];
    [query append:@"message"    stringValue:message];
    
    data = [XmlFactory dataWithArrayOfRecipientElementNamed:@"recipients" recipients:recipients];
    
    responseHandler = [[GuidHandler alloc] init];
    [super postToMethod:method query:query.query data:data];
}


- (void)postViewUserFeedFromBeginning:(NSString *)deviceId 
                          withMessage:(NSString *)message 
                                   to:(NSArray *)recipients 
{
    method = @"PostViewUserFeedFromBeginning";
    
    query = [[QueryString alloc] init];
	[query append:@"recipients" stringValue:@""];
    [query append:@"deviceId"   stringValue:deviceId];
    [query append:@"message"    stringValue:message];
    
    data = [XmlFactory dataWithArrayOfRecipientElementNamed:@"recipients" recipients:recipients];
    
    responseHandler = [[GuidHandler alloc] init];
    [super postToMethod:method query:query.query data:data];
}


- (void)postViewArchiveForDevice:(NSString *)deviceId 
                           since:(NSDate *)startTime 
                         caption:(NSString *)caption 
                     withMessage:(NSString *)message 
                              to:(NSArray *)recipients
{
    method = @"PostViewDeviceArchiveSince";
    
    query = [[QueryString alloc] init];
	[query append:@"recipients" stringValue:@""];
    [query append:@"deviceId"   stringValue:deviceId];
    [query append:@"startTime"  stringValue:[XmlFactory formatDate:startTime]];
    [query append:@"caption"    stringValue:caption];
    [query append:@"message"    stringValue:message];
    
    data = [XmlFactory dataWithArrayOfRecipientElementNamed:@"recipients" recipients:recipients];
    
    responseHandler = [[GuidHandler alloc] init];
    [super postToMethod:method query:query.query data:data];
}


- (void)postViewArchiveForDevice:(NSString *)deviceId 
                betweenStartTime:(NSDate *)startTime 
                     andStopTime:(NSDate *)stopTime 
                         caption:(NSString *)caption 
                     withMessage:(NSString *)message 
                              to:(NSArray *)recipients
{
    method = @"PostViewDeviceArchiveSince";
    
    query = [[QueryString alloc] init];
	[query append:@"recipients" stringValue:@""];
    [query append:@"deviceId"   stringValue:deviceId];
    [query append:@"startTime"  stringValue:[XmlFactory formatDate:startTime]];
    [query append:@"stopTime"   stringValue:[XmlFactory formatDate:stopTime]];
    [query append:@"caption"    stringValue:caption];
    [query append:@"message"    stringValue:message];
    
    data = [XmlFactory dataWithArrayOfRecipientElementNamed:@"recipients" recipients:recipients];
    
    responseHandler = [[GuidHandler alloc] init];
    [super postToMethod:method query:query.query data:data];
}


#pragma mark - WebService response callback
 
- (void)notifyDelegateOfGuid:(NSString *)guid orError:(NSError *)responseError
{
	NSString * __block theGuid = guid;  // retain guid until delegate is done with it
	
    // dispatch delegate callback asynchronously on the main thread
    dispatch_async(dispatch_get_main_queue(), 
                   ^{
                       [delegate onPostCommandResult:theGuid error:responseError];
					   theGuid = nil;
                   });
}

- (void)didGetResponse:(NSData *)responseData orError:(NSError *)responseError
{
	if (responseError != nil)
	{
        DDLogError(@"CommandService received error response: %@", [responseError localizedDescription]);
        
        if ([responseError.domain isEqualToString:RV_DOMAIN])
        {
            RvError * rvError = (RvError *)responseError;
            
            if ((rvError.code == RV_HTTP_ERROR) && (rvError.httpStatus.intValue == 450))
            {
                // the recipient list was empty, which probably means groups or users were removed before command was sent
                UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to Share Video",
																							   @"Unable to share video")
																	 message:NSLocalizedString(@"The command could not be delivered because it had no valid recipients.",@"The command could not be delivered because it had no valid recipients.")
																	delegate:nil 
														   cancelButtonTitle:NSLocalizedString(@"OK",@"OK") 
														   otherButtonTitles:nil];
                [alertView show];
            }
        }
        else
        {
            // not a realityvision or http error, so we were probably not able to reach the server
            // ask the user if they want to retry
            
            // retain self and error until user has responded to alert
            error = responseError;
            
            // notify user of error and see if they want to retry
			NSString * title = NSLocalizedString(@"Unable to Share Video",@"Unable to share video");
			NSString * message = NSLocalizedString(@"The command did not reach the server. Would you like to retry?",
												   @"The command did not reach the server. Would you like to retry?");
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:title
																 message:message
																delegate:self 
													   cancelButtonTitle:NSLocalizedString(@"No",@"No") 
													   otherButtonTitles:NSLocalizedString(@"Yes",@"Yes"),nil];
            [alertView show];
            return;
        }
	}
    
    // only parse response if there was no error
    NSString * commandId = (responseError == nil) ? [responseHandler parseResponse:responseData] : nil;
    [self notifyDelegateOfGuid:commandId orError:responseError];
    responseHandler = nil;
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
 	if (buttonIndex == 0)
    {
        DDLogInfo(@"CommandService: user cancelled operation");
        [self notifyDelegateOfGuid:nil orError:error];
        responseHandler = nil;
    }
    else
	{
        // user wants to retry
        DDLogInfo(@"CommandService: user retrying operation");
        [super postToMethod:method query:query.query data:data];
	}
    
    error = nil;
}

@end
