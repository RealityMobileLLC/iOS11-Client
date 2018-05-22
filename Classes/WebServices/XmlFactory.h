//
//  XmlFactory.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/23/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CameraInfo;
@class Command;
@class Recipient;
@class GDataXMLElement;

/**
 *  XmlFactory provides static methods used to create XML representations of
 *  various RealityVision data structures.
 */
@interface XmlFactory : NSObject 

/**
 *  Returns an NSData object containing an ArrayOfNameValue XML element inside the named element.
 *  
 *  @param elementName Name of root element
 *  @param dictionary Dictionary containing name/value pairs
 *  @return NSData object containing the resulting XML
 */
+ (NSData *)dataWithArrayOfNameValueElementNamed:(NSString *)elementName dictionary:(NSDictionary *)dictionary;

/**
 *  Returns an NSData object containing an ArrayOfRecipient XML element inside the named element.
 *
 *  @param elementName Name of root element
 *  @param recipients Array of recipients
 *  @return NSData object containing the resulting XML
 */
+ (NSData *)dataWithArrayOfRecipientElementNamed:(NSString *)elementName recipients:(NSArray *)recipients;

/**
 *  Returns an NSData object containing a CameraInfo XML element.
 *  
 *  @param cameraInfo Camera
 *  @return NSData object containing the resulting XML
 */
+ (NSData *)dataWithCameraInfoElement:(CameraInfo *)cameraInfo;

/**
 *  Returns an NSData object containing a CameraInfo XML element inside the named element.
 *  
 *  @param elementName Name of root element
 *  @param cameraInfo Camera
 *  @return NSData object containing the resulting XML
 */
+ (NSData *)dataWithCameraInfoElementNamed:(NSString *)elementName camera:(CameraInfo *)cameraInfo;

/**
 *  Returns an NSData object containing a Command XML element inside the named element.
 *  
 *  @param elementName Name of root element
 *  @param command Command
 *  @return NSData object containing the resulting XML
 */
+ (NSData *)dataWithCommandElementNamed:(NSString *)elementName command:(Command *)command;

/**
 *  Returns an NSData object containing a Recipient XML element inside the named element.
 *
 *  @param elementName Name of root element
 *  @param recipient Recipient
 *  @return NSData object containing the resulting XML
 */
+ (NSData *)dataWithRecipientElementNamed:(NSString *)elementName recipient:(Recipient *)recipient;

/**
 *  Returns an NSData object containing the given elements inside the named root element.
 *  
 *  @param elementName Name of root element
 *  @param elements An array of GDataXmlElement
 *  @return NSData object containing the resulting XML
 */
+ (NSData *)dataWithRootElementNamed:(NSString *)elementName elements:(NSArray *)elements;

/**
 *  Returns an NSData object containing a well-formed XML document with the root element.
 *  
 *  @param root Root element for XML document.
 *  @return NSData object containing the resulting XML document
 */
+ (NSData *)dataWithXmlDocumentWithRootElement:(GDataXMLElement *)root;

/**
 *  Returns an ArrayOfRecipient XML element inside the named element.
 *  
 *  @param elementName Name of root element
 *  @param recipients Array of recipients
 *  @return XML element
 */
+ (GDataXMLElement *)arrayOfRecipientElementNamed:(NSString *)elementName recipients:(NSArray *)recipients;

/**
 *  Returns a CameraInfo XML element inside the named element.
 *  
 *  @param elementName Name of root element
 *  @param cameraInfo Camera
 *  @param XML element
 */
+ (GDataXMLElement *)cameraInfoElementNamed:(NSString *)elementName camera:(CameraInfo *)cameraInfo;

/**
 *  Returns an XML-formatted string representation of the given date.
 *  
 *  @param date The date to format
 *  @return string representation of date
 */
+ (NSString *)formatDate:(NSDate *)date;

@end
