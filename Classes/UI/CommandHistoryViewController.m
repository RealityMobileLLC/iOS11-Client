//
//  CommandHistoryViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/21/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import "CommandHistoryViewController.h"
#import "ClientConfiguration.h"
#import "SystemUris.h"
#import "CommandWrapper.h"
#import "Command.h"
#import "CommandHistoryResult.h"
#import "ConfigurationManager.h"
#import "RealityVisionClient.h"
#import "ActivityTableViewCell.h"
#import "HistoryTableViewCell.h"
#import "RealityVisionAppDelegate.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation CommandHistoryViewController
{
	NSMutableArray        * commands;
	NSString              * lastCommandId;
    BOOL                    hasMoreCommands;
	int                     displayCount;
	ActivityTableViewCell * activityTableViewCell;
}

@synthesize historyTableViewCell;


#pragma mark - Initialization and cleanup

- (void)createToolbarItems
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		UIBarButtonItem * flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
																					target:nil 
																					action:nil];
		
		UIBarButtonItem * homeButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Home",@"Home button") 
																		style:UIBarButtonItemStyleBordered 
																	   target:[RealityVisionAppDelegate rootViewController] 
																	   action:@selector(showRootView)];
		
		self.toolbarItems = [NSArray arrayWithObjects:flexSpace, homeButton, nil];
		
	}
}

- (void)dealloc 
{
	[webRequest cancel];
}


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"CommandHistoryViewController viewDidLoad");
	[super viewDidLoad];
	self.title = self.commandHistoryTitle;
	[self createToolbarItems];
	[self.tableView registerNib:[UINib nibWithNibName:@"HistoryTableViewCell" bundle:nil]
		 forCellReuseIdentifier:[HistoryTableViewCell reuseIdentifier]];
	
    int minimumDisplayCount = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 15 : 7;
	displayCount = MAX([ConfigurationManager instance].clientConfiguration.clientCommandDisplayCount, minimumDisplayCount);
    
	commands = [NSMutableArray arrayWithCapacity:20];
	hasMoreCommands = YES;
	[self getMoreCommands];
}

- (void)viewDidUnload 
{
	DDLogVerbose(@"CommandHistoryViewController viewDidUnload");
	[super viewDidUnload];
	[webRequest cancel];
	webRequest = nil;
	commands = nil;
	lastCommandId = nil;
	historyTableViewCell = nil;
	activityTableViewCell = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	DDLogVerbose(@"CommandHistoryViewController viewWillAppear");
    [super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
	DDLogVerbose(@"CommandHistoryViewController viewDidAppear");
    [super viewDidAppear:animated];
	[self.tableView flashScrollIndicators];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	[self.tableView flashScrollIndicators];
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark - CommandHistoryViewController abstract methods to be implemented by subclasses

- (NSString *)commandHistoryTitle
{
    // subclasses must override to return the title to be displayed in the navigation bar
    return nil;
}

- (NSString *)loadingCommandsText
{
    // subclasses must override to return the text to be displayed while retrieving commands
    return nil;
}

- (NSString *)noCommandsText
{
    // subclasses must override to return the text to be displayed while retrieving commands
    return nil;
}

- (void)startCommandHistoryWebRequestWithCommandId:(NSString *)commandId andDisplayCount:(int)displayCount
{
    // subclasses must override to perform asynchronous web request to retrieve the next displayCount set of commands
    // web request should call onCommandHistoryRequest with the result
    [self doesNotRecognizeSelector:_cmd];
}

- (CommandWrapper *)commandWrapperForCommand:(Command *)cmd
{
    // subclasses must override to return a command wrapper for the command
    return nil;
}

- (HistoryTableViewCell *)historyTableViewCell:(UITableView *)tableView forCommand:(CommandWrapper *)cmd
{
    // subclasses must override to return a formatted HistoryTableViewCell for the command
	return nil;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	int count = [commands count];
	
	// if applicable, account for additional row to display "no commands" or "more commands"
    return ((count == 0) || (hasMoreCommands)) ? count + 1 : count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// if history has not yet loaded, indicate to user that it is loading
	if (webRequest != nil)
	{
		activityTableViewCell = 
            [ActivityTableViewCell activityTableViewCellWithText:self.loadingCommandsText
                                                        andStart:YES];
		activityTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
		return activityTableViewCell;
	}
	
	// if there is no history, let the user know
	if ([commands count] == 0)
	{
		activityTableViewCell = 
        [ActivityTableViewCell activityTableViewCellWithText:self.noCommandsText 
                                                        andStart:NO];
		activityTableViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
		return activityTableViewCell;
	}
	
	// if there is more history available, show option to load more
	if (indexPath.row == [commands count])
	{
		activityTableViewCell = 
            [ActivityTableViewCell activityTableViewCellWithText:NSLocalizedString(@"Older Commands ...",@"Older commands prompt") 
                                                        andStart:NO];
		activityTableViewCell.textLabel.textColor = [UIColor blueColor];
		activityTableViewCell.selectionStyle = UITableViewCellSelectionStyleBlue;
		return activityTableViewCell;
	}
	
	return [self historyTableViewCell:tableView forCommand:[commands objectAtIndex:indexPath.row]];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// silly apple only lets us set a cell's background color here
	if ([cell isKindOfClass:[HistoryTableViewCell class]])
	{
		float greyscale = (cell.tag == CH_TAG_COMMAND_UNREAD) ? 0.9 : 1.0;
		cell.backgroundColor = [UIColor colorWithWhite:greyscale alpha:1.0];
	}
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.row < [commands count])
	{
		CommandWrapper * cmd = [commands objectAtIndex:indexPath.row];
		DDLogVerbose(@"CommandHistoryViewController: User selected command %@", cmd.name);
		[cmd view];
		
		// needed because some force commands launch other apps but
        // viewWillAppear: will not be called when leaving and returning to app
		if (cmd.isForceCommand)
		{
			[tableView deselectRowAtIndexPath:indexPath animated:NO];
			[self.tableView reloadData];
		}
	}
	else if (([commands count] > 0) && (indexPath.row == [commands count]))
	{
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[self getMoreCommands];
	}
}


#pragma mark - ClientTransactionDelegate methods

- (void)onCommandHistoryResult:(CommandHistoryResult *)commandHistory error:(NSError *)error
{
	DDLogInfo(@"CommandHistoryViewController onCommandHistoryResult");
	
	hasMoreCommands = NO;
	
	if (error != nil)
	{
		DDLogError(@"CommandHistoryViewController onCommandHistoryResult received error: %@", error);
		[self performSelectorOnMainThread:@selector(alertUserWithErrorMessage:)
							   withObject:[error localizedDescription]
							waitUntilDone:NO];
	}
	else if (commandHistory == nil)
	{
		DDLogError(@"CommandHistoryViewController onCommandHistoryResult did not receive CommandHistoryResult");
        NSString * message = NSLocalizedString(@"Did not receive command history",@"Did not receive command history error");
        [self performSelectorOnMainThread:@selector(alertUserWithErrorMessage:)
							   withObject:message
							waitUntilDone:NO];
	}
	else
	{
		for (Command * cmd in commandHistory.commands)
		{
            CommandWrapper * snoopDog = [self commandWrapperForCommand:cmd];
            [commands addObject:snoopDog];
            lastCommandId = cmd.commandId;
		}
		
		hasMoreCommands = commandHistory.moreResults;
		
		[self.tableView reloadData];
	}
	
	webRequest = nil;
}


#pragma mark - UIAlertViewDelegate methods

- (void)dismiss
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:NO];
}


#pragma mark - Private methods

- (void)getMoreCommands 
{
	DDLogInfo(@"CommandHistoryViewController getMoreCommands");
	
	if (hasMoreCommands && (webRequest == nil))
	{
		NSString * commandId = lastCommandId ? lastCommandId : @"null";
        [self startCommandHistoryWebRequestWithCommandId:commandId andDisplayCount:displayCount];
		[activityTableViewCell startActivityIndicator];
	}
}

- (void)alertUserWithErrorMessage:(NSString *)message
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Could Not Get Command History",
																			   @"Could not get command history alert")
                                                      message:message 
                                                     delegate:self 
                                            cancelButtonTitle:NSLocalizedString(@"OK",@"OK")
                                            otherButtonTitles:nil];
    [alert show];
}

@end
