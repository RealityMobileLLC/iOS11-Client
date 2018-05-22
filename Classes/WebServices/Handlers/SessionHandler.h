//
//  SessionHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/29/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"
#import "WebServiceResponseHandler.h"

@class Session;


/**
 *  Parses an XML Session element and returns a Session object.
 */
@interface SessionHandler : RvXmlParserDelegate <WebServiceResponseHandler> 

@end
