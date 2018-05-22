//
//  CommandHistoryHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"
#import "WebServiceResponseHandler.h"

@class CommandHistoryResult;


/**
 *  Parses an XML CommandHistoryResult document and returns a CommandHistoryResult 
 *  object.
 */
@interface CommandHistoryResultHandler : RvXmlParserDelegate <WebServiceResponseHandler> 

@end
