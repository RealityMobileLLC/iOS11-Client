//
//  SipEndPointHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/25/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "SipEndPointHandler.h"
#import "SipEndPoint.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation SipEndPointHandler
{
	NSMutableString * buffer;
	SipEndPoint     * sipEndpoint;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		sipEndpoint = [[SipEndPoint alloc] init];
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
		DDLogError(@"Failed to parse SipEndPoint");
		return nil;
	}
	
	return self.result;
}


#pragma mark - RvXmlParserDelegate methods

- (SipEndPoint *)result
{
	return sipEndpoint;
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
	
	if ([elementName isEqualToString:@"EndPoint"]) 
	{
		sipEndpoint.endpoint = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Codec"]) 
	{
		sipEndpoint.codec = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Pin"])
	{
		sipEndpoint.pin = [NSString stringWithString:buffer];
	}
}

@end
