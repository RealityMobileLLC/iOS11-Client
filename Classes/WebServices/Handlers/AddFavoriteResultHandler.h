//
//  AddFavoriteResultHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/23/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "RvXmlParserDelegate.h"
#import "WebServiceResponseHandler.h"


/**
 *  Parses an XML ArrayOfAttachment element and returns an NSArray object.
 */
@interface AddFavoriteResultHandler : RvXmlParserDelegate <WebServiceResponseHandler> 

@end
