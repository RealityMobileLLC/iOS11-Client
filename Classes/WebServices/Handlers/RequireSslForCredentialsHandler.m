//
//  RequireSslForCredentialsHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/24/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "RequireSslForCredentialsHandler.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation RequireSslForCredentialsHandler
{
	NSMutableString * buffer;
	NSNumber        * requireSsl;
}


#pragma mark -
#pragma mark Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		requireSsl = nil;
	}
	return self;
}




#pragma mark -
#pragma mark WebServiceResponseHandler methods

- (id)parseResponse:(NSData *)xml
{
	NSXMLParser * parser = [[NSXMLParser alloc] initWithData:xml];
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:YES];
    
	BOOL success = [parser parse];
	if (! success)
	{
		DDLogError(@"Failed to parse GetRequireSslForCredentials response");
		return nil;
	}
	
	return self.result;
}


#pragma mark -
#pragma mark RvXmlParserDelegate methods

- (NSNumber *)result
{
	return requireSsl;
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
	
	if ([elementName isEqualToString:@"boolean"]) 
	{
		requireSsl = [[NSNumber alloc] initWithBool:[buffer boolValue]];
	}
}

@end
