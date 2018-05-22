//
//  CommandHistoryViewController.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/21/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ClientTransaction.h"

@class CommandWrapper;
@class ActivityTableViewCell;
@class HistoryTableViewCell;


enum
{
    CH_TAG_COMMAND_READ,      // uitableviewcell tag used to indicate command has been read
    CH_TAG_COMMAND_UNREAD     // uitableviewcell tag used to indicate command has not been read 
};


/**
 *  View Controller used to display the user's command history.  This is an abstract class
 *  whose descendent classes determine what commands are requested and displayed.
 */
@interface CommandHistoryViewController : UITableViewController <UIAlertViewDelegate, ClientTransactionDelegate>
{
@protected
    ClientTransaction * webRequest;
}

/**
 *  Title to display in the navigation bar.
 *  
 *  Must be overridden by subclass.
 */
@property (strong, nonatomic,readonly) NSString * commandHistoryTitle;

/**
 *  Text to display while retrieving commands from the server.
 *  
 *  Must be overridden by subclass.
 */
@property (strong, nonatomic,readonly) NSString * loadingCommandsText;

/**
 *  Text to display when there are no commands.
 *  
 *  Must be overridden by subclass.
 */
@property (strong, nonatomic,readonly) NSString * noCommandsText;

/**
 *  Starts an asynchronous web request to retrieve the next set of commands from the server.
 *  
 *  Must be overridden by subclass. Subclass must set webRequest variable and set its delegate to self.
 */
- (void)startCommandHistoryWebRequestWithCommandId:(NSString *)lastCommandId andDisplayCount:(int)displayCount;

/**
 *  Returns a CommandWrapper for the command.  The CommandWrapper should have its isSentCommand
 *  property set appropriately for displaying received versus sent commands.
 *  
 *  Must be overridden by subclass.
 */
- (CommandWrapper *)commandWrapperForCommand:(Command *)cmd;

/**
 *  Returns a HistoryTableViewCell formatted for the command.
 *  
 *  Must be overridden by subclass.
 */
- (HistoryTableViewCell *)historyTableViewCell:(UITableView *)tableView forCommand:(CommandWrapper *)cmd;


// Interface Builder outlets
@property (nonatomic,strong) IBOutlet HistoryTableViewCell * historyTableViewCell;

@end
