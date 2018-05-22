//
//  RvXmlParserDelegate.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Abstract class that implements the NSXMLParserDelegate protocol
 *  and is capable of returning an arbitrary result.
 */
@interface RvXmlParserDelegate : NSObject <NSXMLParserDelegate>
{
@protected
	// handler for the current sub-element that needs to be parsed before the current element completes
	RvXmlParserDelegate * handler;
}

/**
 *  Indicates whether the delegate has received a didStartElement and is
 *  waiting on its corresponding didEndElement.
 */
@property (nonatomic,readonly) BOOL isParsingElement;

/**
 *  Descendent classes must implement this method to return the result from
 *  parsing an XML document.
 */
@property (strong, nonatomic,readonly) id result;

/**
 *  Subclasses that implement this NSXMLParserDelegate method must call
 *  the version in this class:
 *  
 *  [super parser:didStarElement:namespaceURI:qualifiedName:attributes:]
 */
- (void) parser:(NSXMLParser *)theParser 
didStartElement:(NSString *)elementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qName 
	 attributes:(NSDictionary *)attributeDict;

/**
 *  Subclasses that implement this NSXMLParserDelegate method must call
 *  the version in this class:
 *  
 *  [super parser:didEndElement:namespaceURI:qualifiedName:]
 */
- (void)parser:(NSXMLParser *)theParser 
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName;

/**
 *  Parses an RFC 3339 format date string received from a web service.
 *
 *  @param dateString String to convert to a date.
 */
+ (NSDate *)parseDate:(NSString *)dateString;

@end
