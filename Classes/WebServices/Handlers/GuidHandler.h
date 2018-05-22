//
//  GuidHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/3/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"
#import "WebServiceResponseHandler.h"


/**
 *  Parses a GUID by web services and returns an NSString containing its result.
 */
@interface GuidHandler : RvXmlParserDelegate <WebServiceResponseHandler>  

@end
