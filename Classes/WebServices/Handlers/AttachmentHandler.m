//
//  AttachmentHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "AttachmentHandler.h"
#import "Attachment.h"
#import "AttachmentPurposeType.h"
#import "Base64.h"


@implementation AttachmentHandler
{
@private
	NSMutableString * buffer;
	Attachment      * attachment;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		attachment = [[Attachment alloc] init];
	}
	return self;
}


#pragma mark - RvXmlParserDelegate methods

- (Attachment *)result
{
	return attachment;
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
		attachment.attachmentId = [buffer intValue];
	} 
	else if ([elementName isEqualToString:@"Format"]) 
	{
		attachment.format = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Purpose"]) 
	{
		attachment.purpose = [[AttachmentPurposeType alloc] initWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Data"]) 
	{
		attachment.data = [Base64 decode:buffer];
	}
}

@end
