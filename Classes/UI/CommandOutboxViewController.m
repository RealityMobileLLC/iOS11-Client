//
//  CommandOutboxViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/3/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CommandOutboxViewController.h"
#import "Command.h"
#import "CommandWrapper.h"
#import "DirectiveType.h"
#import "Recipient.h"
#import "HistoryTableViewCell.h"
#import "ConfigurationManager.h"
#import "SystemUris.h"
#import "ClientTransaction.h"



@implementation CommandOutboxViewController

- (NSString *)commandHistoryTitle
{
    return NSLocalizedString(@"Outbox",@"Command Outbox title");
}

- (NSString *)loadingCommandsText
{
    return NSLocalizedString(@"Loading",@"Loading command outbox prompt") ;
}

- (NSString *)noCommandsText
{
    return NSLocalizedString(@"No Commands",@"No commands in outbox");
}

- (CommandWrapper *)commandWrapperForCommand:(Command *)cmd
{
    return [[CommandWrapper alloc] initWithSentCommand:cmd];
}

- (void)startCommandHistoryWebRequestWithCommandId:(NSString *)commandId andDisplayCount:(int)displayCount
{
    NSURL * clientTransactionUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
    webRequest = [[ClientTransaction alloc] initWithUrl:clientTransactionUrl];
    webRequest.delegate = self;
    DirectiveType * directive = [[DirectiveType alloc] initWithValue:DT_ViewCameraInfo];
    [webRequest getSentCommandsOfType:directive afterCommand:commandId count:displayCount];
}

- (HistoryTableViewCell *)historyTableViewCell:(UITableView *)tableView forCommand:(CommandWrapper *)cmd
{
	NSString * cellIdentifier = [HistoryTableViewCell reuseIdentifier];
    HistoryTableViewCell * cell = (HistoryTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
    NSString * recipients = [Recipient stringWithRecipients:cmd.sortedRecipients];
	cell.iconImageView.image = cmd.icon;
	cell.titleTextLabel.text = cmd.name;
	cell.fromTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"To: %@",@"Command to format string"), recipients];
	cell.dateTextLabel.text = cmd.eventTimeString;
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	return cell;
}

@end

