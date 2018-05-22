//
//  CameraInfoHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/18/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"

@class CameraInfo;


/**
 *  Parses an XML CameraInfo element and returns a CameraInfo object.
 */
@interface CameraInfoHandler : RvXmlParserDelegate 

@end
