//
//  CommandCountResultHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/23/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"
#import "WebServiceResponseHandler.h"


/**
 *  Parses the value returned by the GetPendingCommandCount web service and 
 *  returns an NSNumber with the requested command count.
 */
@interface CommandCountResultHandler : RvXmlParserDelegate <WebServiceResponseHandler> 

@end
