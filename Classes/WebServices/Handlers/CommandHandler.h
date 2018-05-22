//
//  CommandHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "RvXmlParserDelegate.h"
#import "WebServiceResponseHandler.h"

@class Command;


/**
 *  Parses an XML Command element and returns a Command object.
 */
@interface CommandHandler : RvXmlParserDelegate <WebServiceResponseHandler> 

@end
