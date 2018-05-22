//
//  Command.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "Command.h"
#import "CommandResponseType.h"
#import "DirectiveType.h"


@implementation Command

@synthesize commandId;
@synthesize directive;
@synthesize parameter;
@synthesize message;
@synthesize eventTime;
@synthesize retrieved;
@synthesize retrievedDate;
@synthesize senderId;
@synthesize senderUsername;
@synthesize senderFullName;
@synthesize recipients;
@synthesize attachments;
@synthesize responseType;
@synthesize response;
@synthesize responseDate;

@end
