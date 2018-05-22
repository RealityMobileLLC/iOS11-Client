//
//  CommandHistoryMenuViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 10/20/11.
//  Copyright (c) 2011 Reality Mobile LLC. All rights reserved.
//

#import "CommandHistoryMenuViewController.h"
#import "CommandInboxViewController.h"
#import "CommandOutboxViewController.h"
#import "MenuItem.h"
#import "MenuTableViewCell.h"
#import "RealityVisionAppDelegate.h"
#import "RealityVisionClient.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


enum 
{
    INBOX_MENU_ITEM,
    OUTBOX_MENU_ITEM,
};


@implementation CommandHistoryMenuViewController
{
	NSArray * menuItems;
}

@synthesize menuTableViewCell;


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	DDLogVerbose(@"CommandHistoryMenuViewController viewDidLoad");
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Command History",@"Command History title");
	
	[self.tableView registerNib:[UINib nibWithNibName:@"MenuTableViewCell" bundle:nil]
		 forCellReuseIdentifier:[MenuTableViewCell reuseIdentifier]];
    
    // create menu
    MenuItem * inbox = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Inbox",@"Command inbox menu label")
                                                  image:nil];
    inbox.tag = INBOX_MENU_ITEM;
    
    MenuItem * outbox = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Outbox",@"Command outbox menu label")
                                                   image:nil];
    outbox.tag = OUTBOX_MENU_ITEM;
    
    menuItems = [NSArray arrayWithObjects:inbox, outbox, nil];
}

- (void)viewDidUnload 
{
	DDLogVerbose(@"CommandHistoryMenuViewController viewDidUnload");
    [super viewDidUnload];
	menuTableViewCell = nil;
	menuItems = nil;
}

- (void)viewWillAppear:(BOOL)animated 
{
	DDLogVerbose(@"CommandHistoryMenuViewController viewWillAppear");
    [super viewWillAppear:animated];
    
	// register for changes to command count
    [[RealityVisionClient instance] addObserver:self
									 forKeyPath:@"inboxCommandCount"
										options:NSKeyValueObservingOptionNew
										context:NULL];
	[self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
	DDLogVerbose(@"CommandHistoryMenuViewController viewWillDisappear");
    [super viewWillDisappear:animated];
    [[RealityVisionClient instance] removeObserver:self forKeyPath:@"inboxCommandCount"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [menuItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	NSString * cellIdentifier = [MenuTableViewCell reuseIdentifier];
    MenuTableViewCell * cell = (MenuTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	MenuItem * item = [menuItems objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:item.image];
	cell.textLabel.text = item.label;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	if (item.tag == INBOX_MENU_ITEM)
	{
		[cell setBadgeCount:[RealityVisionClient instance].inboxCommandCount];
	}
	
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    MenuItem * item = [menuItems objectAtIndex:indexPath.row];
    DDLogInfo(@"CommandHistoryMenuViewController: User selected %@", item.label);
    
    if (item.tag == INBOX_MENU_ITEM)
    {
        CommandInboxViewController * viewController = 
            [[CommandInboxViewController alloc] initWithNibName:@"CommandHistoryViewController" 
                                                          bundle:nil];
        [self.navigationController pushViewController:viewController animated:YES];
    }
    else if (item.tag == OUTBOX_MENU_ITEM)
    {
        CommandOutboxViewController * viewController = 
            [[CommandOutboxViewController alloc] initWithNibName:@"CommandHistoryViewController" 
                                                           bundle:nil];
        [self.navigationController pushViewController:viewController animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - Key-Value-Observing

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"inboxCommandCount"]) 
	{
        // update the command count shown in the menu
        [self.tableView reloadData];
    }
}

@end
