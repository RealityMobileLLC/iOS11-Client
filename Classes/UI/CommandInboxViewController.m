//
//  CommandInboxViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CommandInboxViewController.h"
#import "CommandWrapper.h"
#import "HistoryTableViewCell.h"
#import "ConfigurationManager.h"
#import "SystemUris.h"
#import "ClientTransaction.h"


@implementation CommandInboxViewController

- (NSString *)commandHistoryTitle
{
    return NSLocalizedString(@"Inbox",@"Command Inbox title");
}

- (NSString *)loadingCommandsText
{
    return NSLocalizedString(@"Loading",@"Loading command inbox prompt") ;
}

- (NSString *)noCommandsText
{
    return NSLocalizedString(@"No Commands",@"No commands in inbox");
}

- (CommandWrapper *)commandWrapperForCommand:(Command *)cmd
{
    return [[CommandWrapper alloc] initWithCommand:cmd];
}

- (void)startCommandHistoryWebRequestWithCommandId:(NSString *)commandId andDisplayCount:(int)displayCount
{
    NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
    webRequest = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
    webRequest.delegate = self;
    [webRequest getReceivedCommandsAfterCommand:commandId count:displayCount];
}

- (HistoryTableViewCell *)historyTableViewCell:(UITableView *)tableView forCommand:(CommandWrapper *)cmd
{
	NSString * cellIdentifier = [HistoryTableViewCell reuseIdentifier];
    HistoryTableViewCell * cell = (HistoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	cell.iconImageView.image = cmd.icon;
	cell.titleTextLabel.text = cmd.name;
	cell.fromTextLabel.text  = [NSString stringWithFormat:NSLocalizedString(@"From: %@",@"Command from format string"), cmd.senderName];
	cell.dateTextLabel.text  = cmd.eventTimeString;
	
	BOOL isUnread = ! cmd.wasAccepted;
	CGFloat fontSize = cell.titleTextLabel.font.pointSize;
	cell.titleTextLabel.font = (isUnread) ? [UIFont boldSystemFontOfSize:fontSize] 
                                          : [UIFont systemFontOfSize:fontSize];
	
	// use tag to indicate whether background color should be changed in tableView:willDisplayCell:forRowAtIndexPath:
	cell.tag = (isUnread) ? CH_TAG_COMMAND_UNREAD : CH_TAG_COMMAND_READ;
	cell.accessoryType = (cmd.isForceCommand) ? UITableViewCellAccessoryNone 
                                              : UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

@end

