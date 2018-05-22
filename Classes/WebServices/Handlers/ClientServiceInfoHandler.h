//
//  ClientServiceInfoHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"
#import "WebServiceResponseHandler.h"

@class ClientServiceInfo;


/**
 *  Parses an XML ClientServiceInfo document and returns a ClientServiceInfo 
 *  object.
 */
@interface ClientServiceInfoHandler : RvXmlParserDelegate <WebServiceResponseHandler>

@end
