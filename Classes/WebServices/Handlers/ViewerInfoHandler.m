//
//  ViewerInfoHandler.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 5/30/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "ViewerInfoHandler.h"
#import "ViewerInfo.h"
#import "Base64.h"


@implementation ViewerInfoHandler
{
	NSMutableString * buffer;
	ViewerInfo      * viewerInfo;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		buffer = [[NSMutableString alloc] initWithCapacity:1024];
		viewerInfo = [[ViewerInfo alloc] init];
	}
	return self;
}


#pragma mark - RvXmlParserDelegate methods

- (ViewerInfo *)result
{
	return viewerInfo;
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
	
	if ([elementName isEqualToString:@"CameraType"]) 
	{
		viewerInfo.cameraType = [buffer intValue];
	}
	else if ([elementName isEqualToString:@"URI"]) 
	{
		viewerInfo.uri = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Server"]) 
	{
		viewerInfo.server = [NSString stringWithString:buffer];
	} 
	else if ([elementName isEqualToString:@"Port"]) 
	{
		viewerInfo.port = [buffer longLongValue];
	}
	else if ([elementName isEqualToString:@"Caption"]) 
	{
		viewerInfo.caption = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Description"]) 
	{
		viewerInfo.description = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"Thumbnail"])
	{
		NSData * imageData = [Base64 decode:buffer];
		viewerInfo.thumbnail = [UIImage imageWithData:imageData];
	}
	else if ([elementName isEqualToString:@"DeviceId"]) 
	{
		viewerInfo.deviceId = [NSString stringWithString:buffer];
	} 
	else if ([elementName isEqualToString:@"DeviceName"]) 
	{
		viewerInfo.deviceName = [NSString stringWithString:buffer];
	} 
	else if ([elementName isEqualToString:@"Username"]) 
	{
		viewerInfo.userName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"FullName"]) 
	{
		viewerInfo.fullName = [NSString stringWithString:buffer];
	}
	else if ([elementName isEqualToString:@"ArchiveStartTime"])
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			viewerInfo.archiveStartTime = [RvXmlParserDelegate parseDate:buffer];
		}
	}
	else if ([elementName isEqualToString:@"ArchiveEndTime"])
	{
		if (! NSStringIsNilOrEmpty(buffer))
		{
			viewerInfo.archiveEndTime = [RvXmlParserDelegate parseDate:buffer];
		}
	}
}

@end
