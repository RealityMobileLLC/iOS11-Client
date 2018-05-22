//
//  XmlFactory.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/23/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "XmlFactory.h"
#import "GDataXMLNode.h"
#import "Base64.h"
#import "CameraInfo.h"
#import "Command.h"
#import "CommandResponseType.h"
#import "DirectiveType.h"
#import "Recipient.h"
#import "RecipientType.h"


@interface XmlFactory()

+ (GDataXMLElement *)arrayOfNameValueElement:(NSDictionary *)values;
+ (GDataXMLElement *)arrayOfRecipientElement:(NSArray *)recipients;
+ (GDataXMLElement *)cameraInfoElement:(CameraInfo *)cameraInfo;
+ (GDataXMLElement *)commandElement:(Command *)command;
+ (GDataXMLElement *)elementNamed:(NSString *)name withText:(NSString *)text;
+ (GDataXMLElement *)recipientElement:(Recipient *)recipient;
+ (NSData *)dataWithElement:(GDataXMLElement *)element;
+ (NSString *)formatBool:(BOOL)value;

@end


@implementation XmlFactory


#pragma mark - Initialization and cleanup

- (id)init
{
	// this class should never be instantiated
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}


#pragma mark - Public methods

+ (NSData *)dataWithArrayOfNameValueElementNamed:(NSString *)elementName dictionary:(NSDictionary *)dictionary
{
	GDataXMLElement * node = [XmlFactory arrayOfNameValueElement:dictionary];
	GDataXMLElement * root = [GDataXMLNode elementWithName:elementName];
	[root addChild:node];
	return [XmlFactory dataWithElement:root];
}

+ (NSData *)dataWithArrayOfRecipientElementNamed:(NSString *)elementName recipients:(NSArray *)recipients
{
    GDataXMLElement * root = [XmlFactory arrayOfRecipientElementNamed:elementName recipients:recipients];
    return [XmlFactory dataWithElement:root];
}

+ (NSData *)dataWithCameraInfoElement:(CameraInfo *)cameraInfo
{
	GDataXMLElement * node = [XmlFactory cameraInfoElement:cameraInfo];
	return [XmlFactory dataWithElement:node];
}

+ (NSData *)dataWithCameraInfoElementNamed:(NSString *)elementName camera:(CameraInfo *)cameraInfo
{
	GDataXMLElement * root = [XmlFactory cameraInfoElementNamed:elementName camera:cameraInfo];
	return [XmlFactory dataWithElement:root];
}

+ (NSData *)dataWithCommandElementNamed:(NSString *)elementName command:(Command *)command
{
	GDataXMLElement * node = [XmlFactory commandElement:command];
	GDataXMLElement * root = [GDataXMLNode elementWithName:elementName];
	[root addChild:node];
	return [XmlFactory dataWithElement:root];
}

+ (NSData *)dataWithRecipientElementNamed:(NSString *)elementName recipient:(Recipient *)recipient;
{
	GDataXMLElement * node = [XmlFactory recipientElement:recipient];
	GDataXMLElement * root = [GDataXMLNode elementWithName:elementName];
	[root addChild:node];
	return [XmlFactory dataWithElement:root];
}

+ (NSData *)dataWithRootElementNamed:(NSString *)elementName elements:(NSArray *)elements
{
	GDataXMLElement * root = [GDataXMLNode elementWithName:elementName];
    
    for (GDataXMLElement * node in elements)
    {
        [root addChild:node];
    }
    
	return [XmlFactory dataWithElement:root];
}

+ (NSData *)dataWithXmlDocumentWithRootElement:(GDataXMLElement *)root
{
	//[root addAttribute:[GDataXMLNode attributeWithName:@"xmlns:xsi" 
	//									   stringValue:@"http://www.w3.org/2001/XMLSchema-INSTANCE"]];
	//[root addAttribute:[GDataXMLNode attributeWithName:@"xmlns:xsd" 
	//									   stringValue:@"http://www.w3.org/2001/XMLSchema"]];
	
	GDataXMLDocument * document = [[GDataXMLDocument alloc] initWithRootElement:root];
	[document setCharacterEncoding:@"UTF-16"];
	NSData * documentData = [document XMLData];
	
	return documentData;
}

+ (GDataXMLElement *)arrayOfRecipientElementNamed:(NSString *)elementName recipients:(NSArray *)recipients
{
    GDataXMLElement * node = [XmlFactory arrayOfRecipientElement:recipients];
    GDataXMLElement * root = [GDataXMLNode elementWithName:elementName];
    [root addChild:node];
    return root;
}

+ (GDataXMLElement *)cameraInfoElementNamed:(NSString *)elementName camera:(CameraInfo *)cameraInfo
{
	GDataXMLElement * node = [XmlFactory cameraInfoElement:cameraInfo];
	GDataXMLElement * root = [GDataXMLNode elementWithName:elementName];
	[root addChild:node];
    return root;
}

+ (NSString *)formatDate:(NSDate *)date
{
	static NSDateFormatter * dateFormatter = nil;
	
	if (dateFormatter == nil)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
		[dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	}
	
	return [dateFormatter stringFromDate:date];
}


#pragma mark - Private methods

+ (NSData *)dataWithElement:(GDataXMLElement *)element
{
    NSString * xmlString = [element XMLString];
    NSData * data = [xmlString dataUsingEncoding:NSUnicodeStringEncoding];
	return data;
}

+ (GDataXMLElement *)arrayOfNameValueElement:(NSDictionary *)values
{
	GDataXMLElement * element = [GDataXMLNode elementWithName:@"ArrayOfNameValue"];
	
	if ((element != nil) && (values != nil))
	{
		NSString * key;
		for (key in values) 
		{
			NSString * value = [values valueForKey:key];
			if (value != nil)
			{
				GDataXMLElement * nameNode = [GDataXMLNode elementWithName:@"name" stringValue:key];
				GDataXMLElement * valueNode = [GDataXMLNode elementWithName:@"value" stringValue:value];
				
				GDataXMLElement * nameValueNode = [GDataXMLNode elementWithName:@"NameValue"];
				[nameValueNode addChild:nameNode];
				[nameValueNode addChild:valueNode];
				
				[element addChild:nameValueNode];
			}
		}
	}
	
	return element;
}

+ (GDataXMLElement *)arrayOfRecipientElement:(NSArray *)recipients
{
	GDataXMLElement * node = [GDataXMLNode elementWithName:@"ArrayOfRecipient"];
	
    for (Recipient * recipient in recipients) 
    {
        GDataXMLElement * recipientElement = [XmlFactory recipientElement:recipient];
        [node addChild:recipientElement];
    }
    
    return node;
}

+ (GDataXMLElement *)cameraInfoElement:(CameraInfo *)cameraInfo
{
	GDataXMLElement * server         = [XmlFactory elementNamed:@"Server" withText:cameraInfo.server];
	GDataXMLElement * port           = [XmlFactory elementNamed:@"Port" withText:[NSString stringWithFormat:@"%lld", cameraInfo.port]];
	GDataXMLElement * uri            = [XmlFactory elementNamed:@"URI" withText:cameraInfo.uri];
	GDataXMLElement * caption        = [XmlFactory elementNamed:@"Caption" withText:cameraInfo.caption];
	GDataXMLElement * cameraType     = [XmlFactory elementNamed:@"CameraType" withText:[NSString stringWithFormat:@"%d", cameraInfo.cameraType]];
	GDataXMLElement * country        = [XmlFactory elementNamed:@"Country" withText:cameraInfo.country];
	GDataXMLElement * province       = [XmlFactory elementNamed:@"Province" withText:cameraInfo.province];
	GDataXMLElement * city           = [XmlFactory elementNamed:@"City" withText:cameraInfo.city];
	GDataXMLElement * latitude       = [XmlFactory elementNamed:@"Latitude" withText:[NSString stringWithFormat:@"%f", cameraInfo.latitude]];
	GDataXMLElement * longitude      = [XmlFactory elementNamed:@"Longitude" withText:[NSString stringWithFormat:@"%f", cameraInfo.longitude]];
	GDataXMLElement * description    = [XmlFactory elementNamed:@"Description" withText:cameraInfo.description];
	GDataXMLElement * range          = [XmlFactory elementNamed:@"Range" withText:[NSString stringWithFormat:@"%f", cameraInfo.range]];
	GDataXMLElement * tilt           = [XmlFactory elementNamed:@"Tilt" withText:[NSString stringWithFormat:@"%f", cameraInfo.tilt]];
	GDataXMLElement * heading        = [XmlFactory elementNamed:@"Heading" withText:[NSString stringWithFormat:@"%f", cameraInfo.heading]];
	GDataXMLElement * controlStub    = [XmlFactory elementNamed:@"ControlStub" withText:cameraInfo.controlStub];
	GDataXMLElement * controlRight   = [XmlFactory elementNamed:@"ControlRight" withText:cameraInfo.controlRight];
	GDataXMLElement * controlLeft    = [XmlFactory elementNamed:@"ControlLeft" withText:cameraInfo.controlLeft];
	GDataXMLElement * controlUp      = [XmlFactory elementNamed:@"ControlUp" withText:cameraInfo.controlUp];
	GDataXMLElement * controlDown    = [XmlFactory elementNamed:@"ControlDown" withText:cameraInfo.controlDown];
	GDataXMLElement * controlHome    = [XmlFactory elementNamed:@"ControlHome" withText:cameraInfo.controlHome];
	GDataXMLElement * controlZoomIn  = [XmlFactory elementNamed:@"ControlZoomIn" withText:cameraInfo.controlZoomIn];
	GDataXMLElement * controlZoomOut = [XmlFactory elementNamed:@"ControlZoomOut" withText:cameraInfo.controlZoomOut];
	GDataXMLElement * controlPan     = [XmlFactory elementNamed:@"ControlPan" withText:cameraInfo.controlPan];
	GDataXMLElement * controlTilt    = [XmlFactory elementNamed:@"ControlTilt" withText:cameraInfo.controlTilt];
	GDataXMLElement * inactive       = [XmlFactory elementNamed:@"Inactive" withText:[XmlFactory formatBool:cameraInfo.inactive]];
	
	GDataXMLElement * root = [GDataXMLNode elementWithName:@"CameraInfo"];
	[root addChild:server];
	[root addChild:port];
	[root addChild:uri];
	[root addChild:caption];
	[root addChild:cameraType];
	[root addChild:country];
	[root addChild:province];
	[root addChild:city];
	[root addChild:latitude];
	[root addChild:longitude];
	[root addChild:description];
	[root addChild:range];
	[root addChild:tilt];
	[root addChild:heading];
	[root addChild:controlStub];
	[root addChild:controlRight];
	[root addChild:controlLeft];
	[root addChild:controlUp];
	[root addChild:controlDown];
	[root addChild:controlHome];
	[root addChild:controlZoomIn];
	[root addChild:controlZoomOut];
	[root addChild:controlPan];
	[root addChild:controlTilt];
	[root addChild:inactive];
	
	if (cameraInfo.lastHeartbeat != nil)
	{
		GDataXMLElement * lastHeartbeat = [XmlFactory elementNamed:@"LastHeartbeat" withText:[self formatBool:cameraInfo.hasHeartbeat]];
		[root addChild:lastHeartbeat];
	}
	
	if (cameraInfo.lastHeartbeatTime != nil)
	{
		GDataXMLElement * lastHeartbeatTime = [XmlFactory elementNamed:@"LastHeartbeatTime" withText:[XmlFactory formatDate:cameraInfo.lastHeartbeatTime]];
		[root addChild:lastHeartbeatTime];
	}
	
    // @todo add parameter to specify whether to include thumbnail
	//if (cameraInfo.thumbnail != nil)
	//{
	//	GDataXMLElement * thumbnail = [XmlFactory elementNamed:@"Thumbnail" 
	//												withText:[Base64 encode:UIImageJPEGRepresentation(cameraInfo.thumbnail, 1.0) 
	//																urlSafe:NO]];
	//	[root addChild:thumbnail];
	//}
	
	if (cameraInfo.startTime != nil)
	{
		GDataXMLElement * startTime = [XmlFactory elementNamed:@"StartTime" withText:[XmlFactory formatDate:cameraInfo.startTime]];
		[root addChild:startTime];
	}
	
	return root;
}

+ (GDataXMLElement *)commandElement:(Command *)command
{
	GDataXMLElement * commandId      = [XmlFactory elementNamed:@"Id" withText:command.commandId];
	// @todo GDataXMLElement * attachments    = [XmlFactory elementNamed:@"Attachments" fromAttachments:command.attachments];
	GDataXMLElement * senderId       = [XmlFactory elementNamed:@"SenderId" withText:[NSString stringWithFormat:@"%d", command.senderId]];
	GDataXMLElement * senderFullName = [XmlFactory elementNamed:@"SenderFullName" withText:command.senderFullName];
	GDataXMLElement * senderUsername = [XmlFactory elementNamed:@"SenderUsername" withText:command.senderUsername];
	GDataXMLElement * directive      = [XmlFactory elementNamed:@"Directive" withText:[command.directive stringValue]];
	GDataXMLElement * parameter      = [XmlFactory elementNamed:@"Parameter" withText:command.parameter];
	GDataXMLElement * message        = [XmlFactory elementNamed:@"Message" withText:command.message];
	GDataXMLElement * eventTime      = [XmlFactory elementNamed:@"EventTime" withText:[XmlFactory formatDate:command.eventTime]];
	GDataXMLElement * retrieved      = [XmlFactory elementNamed:@"Retrieved" withText:[XmlFactory formatBool:command.retrieved]];
	GDataXMLElement * response       = [XmlFactory elementNamed:@"Response" withText:command.response];
	
    GDataXMLElement * element = [GDataXMLNode elementWithName:@"Command"];
	[element addChild:commandId];
	//[element addChild:attachments];
	[element addChild:senderId];
	[element addChild:senderFullName];
	[element addChild:senderUsername];
	[element addChild:directive];
	[element addChild:parameter];
	[element addChild:message];
	[element addChild:eventTime];
	[element addChild:retrieved];
	[element addChild:response];
	
	if (command.responseDate != nil)
	{
		GDataXMLElement * responseDate = [XmlFactory elementNamed:@"ResponseDate" withText:[XmlFactory formatDate:command.responseDate]];
		[element addChild:responseDate];
	}
	
	if (command.retrievedDate != nil)
	{
		GDataXMLElement * retrievedDate = [XmlFactory elementNamed:@"RetrievedDate" withText:[XmlFactory formatDate:command.retrievedDate]];
		[element addChild:retrievedDate];
	}
	
	if (command.responseType != nil)
	{
		GDataXMLElement * responseType = [XmlFactory elementNamed:@"ResponseType" withText:[command.responseType stringValue]];
		[element addChild:responseType];
	}
	
	return element;
}

+ (GDataXMLElement *)elementNamed:(NSString *)name withText:(NSString *)text
{
	GDataXMLElement * element = [GDataXMLNode elementWithName:name];
	
	if (text != nil)
	{
		GDataXMLNode * textNode = [GDataXMLNode textWithStringValue:text];
		[element addChild:textNode];
	}
	
	return element;
}

+ (GDataXMLElement *)recipientElement:(Recipient *)recipient
{
    GDataXMLElement * recipientType = [XmlFactory elementNamed:@"Type" withText:recipient.recipientType.stringValue];
    GDataXMLElement * recipientId   = [XmlFactory elementNamed:@"Id"   withText:[NSString stringWithFormat:@"%d", recipient.recipientId]];
    GDataXMLElement * recipientName = [XmlFactory elementNamed:@"Name" withText:recipient.name];
    
    GDataXMLElement * root = [GDataXMLNode elementWithName:@"Recipient"];
    [root addChild:recipientType];
    [root addChild:recipientId];
    [root addChild:recipientName];
    
    if (recipient.recipientType.value == RT_UserDevice)
    {
        GDataXMLElement * deviceId = [XmlFactory elementNamed:@"DeviceId" withText:recipient.deviceId];
        [root addChild:deviceId];
        
        GDataXMLElement * deviceName = [XmlFactory elementNamed:@"DeviceName" withText:recipient.deviceName];
        [root addChild:deviceName];
    }
    
	return root;
}

+ (NSString *)formatBool:(BOOL)value
{
	return (value) ? @"true" : @"false";
}

@end
