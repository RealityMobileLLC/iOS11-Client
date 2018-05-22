//
//  CommandHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CommandHandler.h"
#import "Command.h"
#import "CommandResponseType.h"
#import "DirectiveType.h"
#import "ArrayHandler.h"
#import "AttachmentHandler.h"
#import "RecipientHandler.h"
#import "IgnoreHandler.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CommandHandler
{
	NSMutableString     * buffer;
	Command             * command;
	RvXmlParserDelegate * handler;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		command = [[Command alloc] init];
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
		DDLogError(@"Failed to parse Command");
		return nil;
	}
	
	return self.result;
}


#pragma mark - RvXmlParserDelegate methods

- (Command *)result
{
	return command;
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
	else if ([elementName isEqualToString:@"Attachments"]) 
	{
		handler = [[ArrayHandler alloc] initWithElementName:@"Attachment" andParserClass:[AttachmentHandler class]];
	}
	else if ([elementName isEqualToString:@"Recipients"])
	{
		handler = [[ArrayHandler alloc] initWithElementName:@"Recipient" andParserClass:[RecipientHandler class]];
	}
	else if ([elementName isEqualToString:@"RecipientsGroupsUsers"])
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
	else if ([elementName isEqualToString:@"Attachments"]) 
	{
		command.attachments = handler.result;
		handler = nil;
	} 
	else if ([elementName isEqualToString:@"Recipients"])
	{
        command.recipients = handler.result;
		handler = nil;
	}
	else if ([elementName isEqualToString:@"RecipientsGroupsUsers"])
	{
		handler = nil;
	}
	else if ([elementName isEqualToString:@"Id"]) 
	{
		command.commandId = [NSString stringWithString:buffer];
	} 
	else if ([elementName isEqualToString:@"SenderId"]) 
	{
		command.senderId = [buffer intValue];
	}
	else if ([elementName isEqualToString:@"SenderUsername"]) 
	{
		command.senderUsername = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"SenderFullName"]) 
	{
		command.senderFullName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Directive"]) 
	{
		command.directive = [[DirectiveType alloc] initWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Parameter"]) 
	{
		command.parameter = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Message"]) 
	{
		command.message = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Retrieved"]) 
	{
		command.retrieved = [buffer isEqualToString:@"true"];
	}
	else if ([elementName isEqualToString:@"EventTime"]) 
	{
		command.eventTime = [RvXmlParserDelegate parseDate:buffer];
	}
	else if ([elementName isEqualToString:@"RetrievedDate"]) 
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			command.retrievedDate = [RvXmlParserDelegate parseDate:buffer];
		}
	}
	else if ([elementName isEqualToString:@"Response"]) 
	{
		command.response = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"ResponseDate"]) 
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			command.responseDate = [RvXmlParserDelegate parseDate:buffer];
		}
	}
	else if ([elementName isEqualToString:@"ResponseType"]) 
	{
		command.responseType = [[CommandResponseType alloc] initWithString:buffer];
	}
}

@end
