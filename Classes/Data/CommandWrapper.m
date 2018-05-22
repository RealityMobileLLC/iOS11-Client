//
//  CommandWrapper.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/4/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CommandWrapper.h"
#import "CameraInfoWrapper.h"
#import "Command.h"
#import "CommandResponseType.h"
#import "DirectiveType.h"
#import "Recipient.h"
#import "QueryString.h"
#import "RvXmlParserDelegate.h"
#import "ClientTransaction.h"
#import "NotificationViewController.h"
#import "ConfigurationManager.h"
#import "SystemUris.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"
#import "RvNotification.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CommandWrapper

@synthesize command;
@synthesize icon;
@synthesize name;
@synthesize description;
@synthesize senderName;
@synthesize sortedRecipients;
@synthesize eventTimeString;
@synthesize isForceCommand;
@synthesize isSentCommand;
@synthesize requiresResponse;
@synthesize wasAccepted;


#pragma mark - Initialization and cleanup

- (id)initWithCommand:(Command *)cmd
{
	self = [super init];
	if (self != nil)
	{
		command = cmd;
		[self setNameAndDescription];
        sortedRecipients = nil;
	}
	return self;
}

- (id)initWithSentCommand:(Command *)cmd
{
    self = [self initWithCommand:cmd];
    if (self != nil)
    {
        isSentCommand = YES;
    }
    return self;
}


#pragma mark - Properties

- (UIImage *)icon
{
	if (icon == nil)
	{
		switch (command.directive.value) 
		{
			case DT_TextMessage:
				icon = ([command.attachments count] > 0) ? [UIImage imageNamed:@"sym_action_message_annotated"] 
				                                         : [UIImage imageNamed:@"sym_action_message"];
				break;
				
			case DT_PlacePhoneCall:
				icon = [UIImage imageNamed:@"sym_action_phone"];
				break;
				
			case DT_ViewVideo:
			case DT_ViewCameraUri:
			case DT_ViewCameraInfo:
				icon = [UIImage imageNamed:@"sym_action_view"];
				break;
				
			case DT_DownloadFile:
				icon = [UIImage imageNamed:@"sym_action_file"];
				break;
				
			case DT_DownloadImage:
				icon = [UIImage imageNamed:@"sym_action_image"];
				break;
				
			case DT_ViewUrl:
				icon = [UIImage imageNamed:@"sym_action_link"];
				break;
				
			default:
				icon = nil;
		}
		
	}
	
	return icon;
}

- (NSString *)senderName
{
	NSString * sender;
	
	if (command.senderFullName != nil) 
	{
		sender = command.senderFullName;
	}
	else if (command.senderUsername != nil) 
	{
		sender = command.senderUsername;
	}
	else 
	{
		sender = @"";
	}

	return sender;
}

- (NSArray *)sortedRecipients
{
    if (sortedRecipients == nil)
    {
        NSMutableArray * groupRecipients = [NSMutableArray arrayWithCapacity:[command.recipients count]];
        NSMutableArray * userRecipients = [NSMutableArray arrayWithCapacity:[command.recipients count]];
        
        for (Recipient * recipient in command.recipients)
        {
            if (recipient.recipientType.value == RT_Group)
            {
                [groupRecipients addObject:recipient];
            }
            else
            {
                [userRecipients addObject:recipient];
            }
        }
        
        NSMutableArray * recipients = [[NSMutableArray alloc] initWithCapacity:[command.recipients count]];
        [recipients addObjectsFromArray:[groupRecipients sortedArrayUsingSelector:@selector(compare:)]];
        [recipients addObjectsFromArray:[userRecipients sortedArrayUsingSelector:@selector(compare:)]];
        
        sortedRecipients = recipients;
    }
    
    return sortedRecipients;
}

- (NSString *)eventTimeString
{
	return [NSDateFormatter localizedStringFromDate:command.eventTime 
										  dateStyle:NSDateFormatterMediumStyle 
										  timeStyle:NSDateFormatterLongStyle];
}

- (NSString *)messageWithResponse
{
	if ((command.responseType.value == CR_None) || (command.responseDate == nil))
	{
		return command.message;
	}
	
	NSString * ResponseFormatString = NSLocalizedString(@"%@\n\nAt %@ you responded with: %@",
														@"Command response format string");
	
	NSString * responseDateString = [NSDateFormatter localizedStringFromDate:command.responseDate 
																   dateStyle:NSDateFormatterMediumStyle 
																   timeStyle:NSDateFormatterLongStyle];
	
	return [NSString stringWithFormat:ResponseFormatString, command.message, responseDateString, command.response];
}

- (BOOL)isForceCommand
{
	DirectiveTypeEnum directive = command.directive.value;
	
	return ((directive == DT_TurnOffCamera) || 
			(directive == DT_TurnOnCamera) || 
			(directive == DT_GoOffDuty));
}

- (BOOL)requiresResponse
{
	return ((command.responseType.value != CR_None) && (command.responseDate == nil));
}

- (BOOL)wasAccepted
{
	return command.responseDate != nil;
}


#pragma mark - Command handling

- (void)view
{
	if ((! isSentCommand) && (! command.retrieved)) 
	{
		[self postCommandRetrieved];
	}
	
	if (self.isForceCommand)
	{
		[self executeForceCommand];
	}
	else
	{
		[self showCommandNotification];
	}
}

- (void)accept
{
    [self acceptWithResponse:@""];
}

- (void)acceptWithResponse:(NSString *)response
{
    if (isSentCommand)
        return;
    
	if (command.responseDate == nil)
	{
		command.response = response;
		command.responseDate = [NSDate date];
		[[RealityVisionClient instance] decrementPendingCommandCount];
	}
	
	NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
	ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
	
	[clientTransaction acceptCommand:command.commandId 
						   forDevice:[RealityVisionClient instance].deviceId 
						withResponse:response];
}

- (void)dismiss
{
    if (isSentCommand)
        return;
    
	NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
	ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
	
	[clientTransaction dismissCommand:command.commandId 
							forDevice:[RealityVisionClient instance].deviceId];
}

- (void)postCommandRetrieved
{
    if (isSentCommand)
        return;
    
	command.retrieved = YES;
	command.retrievedDate = [NSDate date];
	
	NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
	ClientTransaction * clientTransaction = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
	
	[clientTransaction receivedCommand:command.commandId forDevice:[RealityVisionClient instance].deviceId];
}

/*
 *  Executes "Force" commands that do not require a command notification.  All
 *  other commands are executed by a NotificationViewController.
 */
- (void)executeForceCommand
{
	[self accept];
	
	switch (command.directive.value)
	{
		case DT_TurnOnCamera:
			// hack to delay displaying the transmit view controller until modals have had a chance to close
			[[RealityVisionClient instance] performSelector:@selector(startTransmitSession) 
                                                 withObject:nil 
                                                 afterDelay:0.5];
			break;
			
		case DT_TurnOffCamera:
			[[RealityVisionClient instance] stopTransmitSessionAndGetComments:NO];
			break;
			
		case DT_GoOffDuty:
			[[RealityVisionClient instance] signOffForced];
            break;
			
		case DT_KillPill:
			// @todo implement kill pill?
			break;
			
		default:
			NSAssert(NO,@"This command should be handled by NotificationViewController");
	}
}

/*
 *  Displays a command notification for "Send" commands.
 */
- (void)showCommandNotification
{
	// create and display new command notification view controller
	NotificationViewController * notificationViewController = 
		[[NotificationViewController alloc] initWithNibName:@"NotificationViewController" 
													  bundle:nil];
	notificationViewController.command = self;
	RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
	[appDelegate.navigationController pushViewController:notificationViewController animated:YES];
}


#pragma mark - Private methods

- (void)setNameAndDescriptionForCameraUri
{
	NSRange cameraNameRange = [command.parameter rangeOfString:@" " options:NSAnchoredSearch|NSBackwardsSearch];
	name = [[NSString alloc] initWithString:[command.parameter substringWithRange:cameraNameRange]];
	description = [[NSString alloc] initWithFormat:NSLocalizedString(@"Command: View Remote Camera %@",@"Camera command label"), name];
}

- (void)setNameAndDescriptionForVideo
{
	NSArray * parts = [command.parameter componentsSeparatedByString:@"!"];
	if ([parts count] > 3)
	{
		name = [parts objectAtIndex:3];
		description = [[NSString alloc] initWithFormat:NSLocalizedString(@"Command: View Remote Camera %@",@"Camera command label"), name];
	}
}

- (void)setNameAndDescriptionForCameraInfo
{
	CameraInfoWrapper * camera = [[CameraInfoWrapper alloc] initWithXml:command.parameter];
	name = [[NSString alloc] initWithString:camera.name];
	description = [CommandWrapper descriptionForCameraInfo:camera];
}

- (void)setNameAndDescription
{
	DirectiveType * directive = command.directive;
	
	switch (directive.value)
	{
		case DT_TextMessage:
			name = command.message;
			description = [[NSString alloc] initWithFormat:NSLocalizedString(@"Message: %@",@"Message command label"), name];
			break;
			
		case DT_PlacePhoneCall:
			name = command.parameter;
			description = [[NSString alloc] initWithFormat:NSLocalizedString(@"Phone: %@",@"Phone command label"), name];
			break;
			
		case DT_DownloadFile:
		case DT_DownloadImage:
			name = [NSString stringWithString:[command.parameter lastPathComponent]];
			description = [[NSString alloc] initWithFormat:NSLocalizedString(@"View: %@",@"File command label"), name];
			break;
			
		case DT_ViewUrl:
			name = command.parameter;
			description = [[NSString alloc] initWithFormat:NSLocalizedString(@"View: %@",@"Url command label"), name];
			break;
			
		case DT_ViewCameraUri:
			[self setNameAndDescriptionForCameraUri];
			break;
			
		case DT_ViewVideo:
			[self setNameAndDescriptionForVideo];
			break;
			
		case DT_ViewCameraInfo:
			[self setNameAndDescriptionForCameraInfo];
			break;
			
		case DT_TurnOffCamera:
		case DT_KillPill:
		case DT_GoOffDuty:
		case DT_TurnOnCamera:
			name = [directive stringValue];
			description = command.parameter;
			break;
			
		default:
			DDLogWarn(@"Unrecognized command: %@", [directive stringValue]);
			name = [directive stringValue];
			description = command.parameter;
	}
}

+ (NSString *)descriptionForCameraInfo:(CameraInfoWrapper *)camera
{
	NSString * result = nil;
	
	if (camera.isVideoServerFeed)
	{
		NSString * startTimeString = [QueryString getParameter:@"starttime" fromQuery:[camera.sourceUrl query]];
		
		if (startTimeString != nil)
		{
			NSDate   * startTime = [RvXmlParserDelegate parseDate:startTimeString];
			NSString * localizedStartTime = [NSDateFormatter localizedStringFromDate:startTime 
																		   dateStyle:NSDateFormatterShortStyle    
																		   timeStyle:NSDateFormatterMediumStyle];
			result = [NSString stringWithFormat:NSLocalizedString(@"View: %@ (%@)",@"Watch video archive command label"), camera.name, localizedStartTime];
		}
	}
	else if (camera.isVideoFile)
	{
		result = [NSString stringWithFormat:NSLocalizedString(@"View: %@",@"Watch video file command label"), camera.name];
	}
	
	if (result == nil)
	{
		result = [NSString stringWithFormat:NSLocalizedString(@"Watch: %@",@"Watch command label"), camera.name];
	}
	
	return result;
}

@end
