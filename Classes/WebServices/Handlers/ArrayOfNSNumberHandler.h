//
//  ArrayOfNSNumberHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 7/29/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"


/**
 *  Parses an XML ArrayOfNSNumberHandler element and returns an NSArray object containing
 *  NSNumber objects.
 */
@interface ArrayOfNSNumberHandler : RvXmlParserDelegate 

/**
 *  Initializes an ArrayOfNSNumberHandler object.
 */
- (id)init;

@end
