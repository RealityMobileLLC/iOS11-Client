//
//  FavoriteEntryHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RvXmlParserDelegate.h"

@class FavoriteEntry;


/**
 *  Parses an XML FavoriteEntry element and returns a FavoriteEntry object.
 */
@interface FavoriteEntryHandler : RvXmlParserDelegate 

@end
