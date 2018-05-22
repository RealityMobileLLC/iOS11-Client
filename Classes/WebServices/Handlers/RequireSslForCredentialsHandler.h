//
//  RequireSslForCredentialsHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/24/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"
#import "WebServiceResponseHandler.h"


/**
 *  Parses the value returned by the GetRequireSslForCredentials web service and 
 *  returns an NSNumber containing a BOOL result.
 */
@interface RequireSslForCredentialsHandler : RvXmlParserDelegate <WebServiceResponseHandler>  

@end
