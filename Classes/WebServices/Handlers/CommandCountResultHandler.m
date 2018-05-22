//
//  CommandCountResultHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/23/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CommandCountResultHandler.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CommandCountResultHandler
{
	NSMutableString * buffer;
	NSNumber        * commandCount;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:10];
	}
	return self;
}


#pragma mark - WebServiceResponseHandler methods

- (id)parseResponse:(NSData *)xml
{
	NSXMLParser * parser = [[NSXMLParser alloc] initWithData:xml];
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:YES];
    
	BOOL success = [parser parse];
	if (! success)
	{
		DDLogError(@"Failed to parse Get Pending Command Count response");
		return nil;
	}
	
	return self.result;
}


#pragma mark - RvXmlParserDelegate methods

- (NSNumber *)result
{
	return commandCount;
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
	
	if ([elementName isEqualToString:@"int"]) 
	{
		commandCount = [NSNumber numberWithInt:[buffer intValue]];
	}
}

@end
