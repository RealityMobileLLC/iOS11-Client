//
//  RecipientSelectionViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/15/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "RecipientSelectionViewController.h"
#import "Device.h"
#import "Group.h"
#import "User.h"
#import "RecipientType.h"
#import "Recipient.h"
#import "SystemUris.h"
#import "ConfigurationManager.h"
#import "CommandMessageViewController.h"
#import "RealityVisionClient.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


enum 
{
    GroupsSection,
    UsersSection,
    kNumberOfSections
};


@implementation RecipientSelectionViewController
{
	Recipient                    * allUsersRecipient;
	NSMutableArray               * groups;
	NSMutableArray               * users;
	UserStatusService            * groupsService;
	UserStatusService            * usersService;
	CommandMessageViewController * messageViewController;
    NSInteger                      selectionCount;
}


@synthesize delegate;
@synthesize showCancelButton;
@synthesize restrictToLandscapeOrientation;
@synthesize camera;
@synthesize shareVideoStartTime;
@synthesize shareCurrentTransmitSession;
@synthesize shareCurrentTransmitSessionFromBeginning;


#pragma mark - Initialization and cleanup

- (void)cancelOutstandingRequests
{
    // cancel any outstanding server requests
    usersService.delegate = nil;
    [usersService cancel];
    
    groupsService.delegate = nil;
    [groupsService cancel];
}


- (void)dealloc
{
    [self cancelOutstandingRequests];
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    DDLogVerbose(@"RecipientSelectionViewController viewDidLoad");
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Recipients",@"Select recipients title");
    self.tableView.rowHeight = 34;
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 320.0);
    allUsersRecipient = [[Recipient alloc] initWithGroup:[Group allUsersGroup]];
    selectionCount = 0;
}


- (void)viewDidUnload
{
    DDLogVerbose(@"RecipientSelectionViewController viewDidUnload");
    [super viewDidUnload];
    [self cancelOutstandingRequests];
    allUsersRecipient = nil;
    groups = nil;
    users = nil;
    groupsService = nil;
    usersService = nil;
	messageViewController = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    DDLogVerbose(@"RecipientSelectionViewController viewWillAppear");
    NSAssert(self.camera||self.shareCurrentTransmitSession,@"Either camera or shareCurrentTransmitSession must be specified");
    [super viewWillAppear:animated];
    
    if ((showCancelButton) && (self.navigationItem.leftBarButtonItem == nil))
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
                                                                                               target:self 
                                                                                               action:@selector(done)];
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next",@"Next button") 
                                                                               style:UIBarButtonItemStyleDone 
                                                                              target:self 
                                                                              action:@selector(next)];
    self.navigationItem.rightBarButtonItem.enabled = (selectionCount > 0);
    
    if (users == nil)
    {
        NSURL * userStatusUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
        usersService = [[UserStatusService alloc] initWithUrl:userStatusUrl 
                                                  andDelegate:self];
        [usersService getSignedOnUsersAndIncludeViewingSessions:NO];
    }
    
    if (groups == nil)
    {
        NSURL * userStatusUrl = [ConfigurationManager instance].systemUris.messagingAndRoutingRest;
        groupsService = [[UserStatusService alloc] initWithUrl:userStatusUrl 
                                                   andDelegate:self];
        [groupsService getValidRecipientGroups];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    DDLogVerbose(@"RecipientSelectionViewController viewDidAppear");
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    DDLogVerbose(@"RecipientSelectionViewController viewWillDisappear");
    [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
    DDLogVerbose(@"RecipientSelectionViewController viewDidDisappear");
    [super viewDidDisappear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (restrictToLandscapeOrientation)
		return interfaceOrientation == UIInterfaceOrientationLandscapeRight;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


#pragma mark - Public methods

- (NSArray *)recipients
{
    if (allUsersRecipient.selected)
    {
        return [NSArray arrayWithObject:allUsersRecipient];
    }
    
    NSPredicate * isSelected = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) 
                                                               {
                                                                   return ((Recipient *)evaluatedObject).selected;
                                                               }];
                                
    NSMutableArray * recipients = [NSMutableArray arrayWithCapacity:10];
    [recipients addObjectsFromArray:[groups filteredArrayUsingPredicate:isSelected]];
    [recipients addObjectsFromArray:[users filteredArrayUsingPredicate:isSelected]];
    
    return recipients;
}


#pragma mark - Button actions

- (void)removeSelections
{
    [usersService cancel];
    usersService = nil;
    
    [groupsService cancel];
    groupsService = nil;
    
    users = nil;
    groups = nil;
    selectionCount = 0;
}


- (void)done
{
    DDLogVerbose(@"RecipientSelectionViewController done");
    [self removeSelections];
    
    // dismiss message view controller
    [self.navigationController popViewControllerAnimated:NO];
    
    // let delegate know we are done
    [delegate didCompleteVideoSharing];
    
    messageViewController = nil;
}


- (void)next
{
    DDLogVerbose(@"RecipientSelectionViewController next");
    if (messageViewController == nil)
    {
        messageViewController = 
            [[CommandMessageViewController alloc] initWithNibName:@"CommandMessageViewController" 
                                                            bundle:nil];
        messageViewController.recipientViewController = self;
    }
    
    [self.navigationController pushViewController:messageViewController animated:YES];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView 
{
    return kNumberOfSections;
}


- (NSString *)tableView:(UITableView *)theTableView titleForHeaderInSection:(NSInteger)section
{
    if (section == GroupsSection)
    {
        return NSLocalizedString(@"Groups",@"Groups recipient selection header");
    }
    else if (section == UsersSection)
    {
        return NSLocalizedString(@"Users",@"Users recipient selection header");
    }
    
    NSAssert(NO,@"Unknown section");
    return nil;
}


- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section 
{
    if (section == GroupsSection)
    {
        return groups ? [groups count] : 1;
    }
    else if (section == UsersSection)
    {
        return users ? [users count] : 1;
    }
    
    NSAssert(NO,@"Unknown section");
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (((indexPath.section == GroupsSection) && (groups == nil)) || 
        ((indexPath.section == UsersSection) && (users == nil)))
    {
        cell.textLabel.text = NSLocalizedString(@"Loading",@"Loading recipients");
        cell.textLabel.font = [UIFont systemFontOfSize:17];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    Recipient * recipient = (indexPath.section == GroupsSection) ? [groups objectAtIndex:indexPath.row] 
                                                                 : [users objectAtIndex:indexPath.row];
    
    cell.textLabel.font = (indexPath.section == GroupsSection) ? [UIFont boldSystemFontOfSize:17] 
                                                               : [UIFont systemFontOfSize:17];
    cell.textLabel.text = recipient.name;
    cell.accessoryType = recipient.selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (((indexPath.section == GroupsSection) && (groups == nil)) || 
        ((indexPath.section == UsersSection) && (users == nil)))
    {
        // user selected the "loading" cell, so don't do anything
        return;
    }
	
	//Se selecciona el recipient, o sea con que usuario quiero compartir el video
    Recipient * recipient = (indexPath.section == GroupsSection) ? [groups objectAtIndex:indexPath.row] 
                                                                 : [users objectAtIndex:indexPath.row];
    recipient.selected = ! recipient.selected;
    
    if (recipient.selected) selectionCount++;
    else selectionCount--;
    
    self.navigationItem.rightBarButtonItem.enabled = (selectionCount > 0);
    [tableView reloadData];
}


#pragma mark - UserStatusServiceDelegate methods

- (void)onGetUserListResult:(NSArray *)userList error:(NSError *)error
{
	DDLogInfo(@"RecipientSelectionViewController onGetUserListResult");
    usersService = nil;
    
	if (error != nil)
	{
        DDLogError(@"%@", [error localizedDescription]);
	}
    else if (userList == nil)
    {
        DDLogError(@"Did not receive the list of users from the User Status Service");
    }
    
    users = [NSMutableArray arrayWithCapacity:[users count]];
    
    for (User * user in userList)
    {
        if ([user.userName caseInsensitiveCompare:[RealityVisionClient instance].userId] != NSOrderedSame)
        {
            Recipient * recipient = [[Recipient alloc] initWithUser:user];
            [users addObject:recipient];
        }
    }
    
    [self.tableView reloadData];
}


- (void)onGetGroupsResult:(NSArray *)groupList error:(NSError *)error
{
    DDLogInfo(@"RecipientSelectionViewController onGetGroupsResult");
    groupsService = nil;
    
    if (error != nil)
    {
        DDLogError(@"%@", [error localizedDescription]);
    }
    else if (groupList == nil)
    {
        DDLogError(@"Did not receive the list of groups from the User Status Service");
    }
    
    groups = [NSMutableArray arrayWithCapacity:[groupList count]+1];
    [groups addObject:allUsersRecipient];
    
    for (Group * group in groupList)
    {
        Recipient * recipient = [[Recipient alloc] initWithGroup:group];
        [groups addObject:recipient];
    }
    
    [self.tableView reloadData];
}

@end
