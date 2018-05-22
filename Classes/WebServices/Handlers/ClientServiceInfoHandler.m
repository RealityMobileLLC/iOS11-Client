//
//  ClientServiceInfoHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ClientServiceInfoHandler.h"
#import "ArrayOfNameValueHandler.h"
#import "ClientServiceInfo.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation ClientServiceInfoHandler
{
	NSMutableString     * buffer;
	ClientServiceInfo   * clientServiceInfo;
	RvXmlParserDelegate * handler;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		clientServiceInfo = [[ClientServiceInfo alloc] init];
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
		DDLogError(@"Failed to parse ClientServiceInfo");
		return nil;
	}
	
	return self.result;
}


#pragma mark - RvXmlParserDelegate methods

- (ClientServiceInfo *)result
{
	return clientServiceInfo;
}


- (void) parser:(NSXMLParser *)theParser 
didStartElement:(NSString *)elementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qName 
	 attributes:(NSDictionary *)attributeDict
{
	[super parser:theParser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
	
	[buffer setString:@""];
	
	if (handler != nil) 
	{
		// Forward to responsible handler
		[handler    parser:theParser 
		   didStartElement:elementName 
			  namespaceURI:namespaceURI 
			 qualifiedName:qName 
				attributes:attributeDict];
	}
	else if ([elementName isEqualToString:@"ClientConfiguration"]) 
	{
		handler = [[ArrayOfNameValueHandler alloc] init];
	}
	else if ([elementName isEqualToString:@"ExternalSystemURIs"]) 
	{
		handler = [[ArrayOfNameValueHandler alloc] init];
	}
	else if ([elementName isEqualToString:@"SystemURIs"]) 
	{
		handler = [[ArrayOfNameValueHandler alloc] init];
	}
}


- (void)parser:(NSXMLParser *)theParser foundCharacters:(NSString *)string 
{
	if (handler != nil) 
	{
		// Forward to responsible handler
		[handler parser:theParser foundCharacters:string];
	}
	else 
	{
		[buffer appendString:string];
	}
}


- (void)parser:(NSXMLParser *)theParser 
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName 
{
	[super parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	
	if ((handler != nil) && (handler.isParsingElement))
	{
		// Forward to responsible handler
		[handler parser:theParser didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qName];
	}
	else if ([elementName isEqualToString:@"ClientConfiguration"]) 
	{
		clientServiceInfo.clientConfiguration = (NSDictionary *)handler.result;
		handler = nil;
	} 
	else if ([elementName isEqualToString:@"ExternalSystemURIs"]) 
	{
		clientServiceInfo.externalSystemUris = (NSDictionary *)handler.result;
		handler = nil;
	} 
	else if ([elementName isEqualToString:@"SystemURIs"]) 
	{
		clientServiceInfo.systemUris = (NSDictionary *)handler.result;
		handler = nil;
	} 
	else if ([elementName isEqualToString:@"DeviceId"]) 
	{
		clientServiceInfo.deviceId = [NSString stringWithString:buffer];
	} 
	else if ([elementName isEqualToString:@"NewHistoryCount"]) 
	{
		clientServiceInfo.newHistoryCount = [buffer intValue];
	}
}

@end
