//
//  WebServiceResponseHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/8/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 *  Protocol used to convert the response from a web service into an 
 *  arbitrary object.
 */
@protocol WebServiceResponseHandler <NSObject>

/**
 *  Parses the response from a web service.
 *
 *  @param xml A response returned by a web service.
 *
 *  @return An object corresponding to the response.
 */
- (id)parseResponse:(NSData *)xml;

@end
