//
//  SessionHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/29/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "SessionHandler.h"
#import "Session.h"
#import "ArrayHandler.h"
#import "CommentHandler.h"
#import "IgnoreHandler.h"
#import "Base64.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@interface SessionHandler()
{
	NSMutableString * buffer;
	Session         * session;
}
@end


@implementation SessionHandler


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		session = [[Session alloc] init];
		handler = nil;
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
		DDLogError(@"Failed to parse Session");
		return nil;
	}
	
	return self.result;
}


#pragma mark - RvXmlParserDelegate methods

- (Session *)result
{
	return session;
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
		[handler parser:theParser 
			 didStartElement:elementName 
				namespaceURI:namespaceURI 
			   qualifiedName:qName 
				  attributes:attributeDict];
	}
	else if ([elementName isEqualToString:@"Comments"]) 
	{
		handler = [[ArrayHandler alloc] initWithElementName:@"Comment" andParserClass:[CommentHandler class]];
	}
	else if ([elementName isEqualToString:@"Region"])
	{
		handler = [[IgnoreHandler alloc] init];
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
	else if ([elementName isEqualToString:@"Comments"]) 
	{
		session.comments = handler.result;
		handler = nil;
	} 
	else if ([elementName isEqualToString:@"Region"])
	{
		handler = nil;
	}
	else if ([elementName isEqualToString:@"SessionId"]) 
	{
		session.sessionId = [buffer intValue];
	} 
	else if ([elementName isEqualToString:@"DeviceId"]) 
	{
		session.deviceId = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"DeviceDescription"]) 
	{
		session.deviceDescription = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"StartTime"]) 
	{
		session.startTime = [RvXmlParserDelegate parseDate:buffer];
	}
	else if ([elementName isEqualToString:@"StopTime"]) 
	{
		session.stopTime = [RvXmlParserDelegate parseDate:buffer];
	}
	else if ([elementName isEqualToString:@"GpsStartTime"]) 
	{
		session.gpsStartTime = [RvXmlParserDelegate parseDate:buffer];
	}
	else if ([elementName isEqualToString:@"GpsStopTime"]) 
	{
		session.gpsStopTime = [RvXmlParserDelegate parseDate:buffer];
	}
	else if ([elementName isEqualToString:@"HasGps"]) 
	{
		session.hasGps = [buffer isEqualToString:@"true"];
	}
	else if ([elementName isEqualToString:@"UserFullName"]) 
	{
		session.userFullName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Username"]) 
	{
		session.username = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"FrameCount"]) 
	{
		session.frameCount = [buffer intValue];
	} 
	else if ([elementName isEqualToString:@"Thumbnail"])
	{
		NSData * imageData = [Base64 decode:buffer];
		session.thumbnail  = [UIImage imageWithData:imageData];
	}
}

@end
