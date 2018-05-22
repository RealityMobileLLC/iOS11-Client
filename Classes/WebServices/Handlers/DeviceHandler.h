//
//  DeviceHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/28/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"

@class Device;


/**
 *  Parses an XML Device element and returns a Device object.
 */
@interface DeviceHandler : RvXmlParserDelegate 

@end
