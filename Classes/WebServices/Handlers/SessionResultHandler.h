//
//  SessionResultHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/12/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"
#import "WebServiceResponseHandler.h"


/**
 *  Parses an XML SessionResult document and returns a SessionResult 
 *  object.
 */
@interface SessionResultHandler : RvXmlParserDelegate <WebServiceResponseHandler>  

@end
