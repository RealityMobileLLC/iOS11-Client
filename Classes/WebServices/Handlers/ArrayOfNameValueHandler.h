//
//  ArrayOfNameValueHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"


/**
 *  Parses an XML ArrayOfNameValue element and returns an NSDictionary object.
 */
@interface ArrayOfNameValueHandler : RvXmlParserDelegate 

/**
 *  Initializes an ArrayOfNameValueHandler object.
 */
- (id)init;

@end
