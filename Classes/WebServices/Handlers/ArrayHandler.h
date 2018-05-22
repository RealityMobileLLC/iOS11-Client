//
//  ArrayHandler.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 5/30/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "RvXmlParserDelegate.h"
#import "WebServiceResponseHandler.h"


/**
 *  Parses an array of XML elements and returns an NSArray object.
 */
@interface ArrayHandler : RvXmlParserDelegate <WebServiceResponseHandler>

@property (nonatomic,readonly,strong) NSString * elementName;
@property (nonatomic,readonly) Class parserClass;

/**
 *  Returns an initialized ArrayHandler object for parsing an array of XML elements with the 
 *  given name using objects of parserClass.
 *  
 *  @param elementName The name of the XML elements that make up the array.
 *  @param parserClass The class to instantiate to parse each element. 
 *                     Must be a subclass of RvXmlParserDelegate.
 */
- (id)initWithElementName:(NSString *)elementName andParserClass:(Class)parserClass;

@end
