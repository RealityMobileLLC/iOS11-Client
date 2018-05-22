//
//  RecipientHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/25/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import "RecipientHandler.h"
#import "Recipient.h"
#import "RecipientType.h"


@implementation RecipientHandler
{
	NSMutableString * buffer;
	Recipient       * recipient;
}


#pragma mark -
#pragma mark Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		recipient = [[Recipient alloc] init];
	}
	return self;
}




#pragma mark -
#pragma mark RvXmlParserDelegate methods

- (Recipient *)result
{
	return recipient;
}


- (void) parser:(NSXMLParser *)theParser 
didStartElement:(NSString *)elementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qName 
	 attributes:(NSDictionary *)attributeDict
{
	[super parser:theParser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
	[buffer setString:@""];
}


- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)string 
{
	[buffer appendString:string];
}


- (void)parser:(NSXMLParser *)theParser 
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
{
	[super parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	
	if ([elementName isEqualToString:@"Id"]) 
	{
		recipient.recipientId = [buffer intValue];
	} 
	else if ([elementName isEqualToString:@"Name"]) 
	{
        recipient.name = [NSString stringWithString:buffer];
	}
    else if ([elementName isEqualToString:@"DeviceId"])
    {
        recipient.deviceId = [NSString stringWithString:buffer];
    }
    else if ([elementName isEqualToString:@"DeviceName"])
    {
        recipient.deviceName = [NSString stringWithString:buffer];
    }
    else if ([elementName isEqualToString:@"Type"])
    {
        recipient.recipientType = [[RecipientType alloc] initWithString:buffer];
    }
}

@end
