//
//  AddConnectionViewController.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 6/21/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "AddConnectionViewController.h"
#import "EditingTableViewCell.h"
#import "SwitchTableViewCell.h"
#import "ConnectionProfile.h"
#import "ConnectionDatabase.h"


// table sections
enum  
{
	SERVER_SECTION,
	ADVANCED_SECTION,
	NUM_SECTIONS
};

// advanced section rows
enum
{
	USE_SSL_ROW,
	IS_EXTERNAL_ROW,
	PORT_ROW,
	PATH_ROW,
	NUM_ADVANCED_ROWS
};


@implementation AddConnectionViewController
{
	// @todo probably should keep the hostTextCell, not just the uitextfield
	//UITextField           * hostTextField;
	EditingTableViewCell  * hostTextCell;
	SwitchTableViewCell   * sslSwitchCell;
	SwitchTableViewCell   * externalSwitchCell;
	EditingTableViewCell  * portTextCell;
	EditingTableViewCell  * pathTextCell;
}

@synthesize addConnectionDelegate;
@synthesize connection;


#pragma mark - View lifecycle

- (void)viewDidLoad 
{
	[super viewDidLoad];
    self.navigationItem.title = NSLocalizedString(@"Add Connection",@"Add Connection title");
	
	self.navigationItem.leftBarButtonItem = 
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
													  target:self 
													  action:@selector(cancel)];
	
	self.navigationItem.rightBarButtonItem = 
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
													  target:self
													  action:@selector(save)];
	
	[self.tableView registerNib:[UINib nibWithNibName:@"EditingTableViewCell" bundle:nil]
		 forCellReuseIdentifier:[EditingTableViewCell reuseIdentifier]];
	
	[self.tableView registerNib:[UINib nibWithNibName:@"SwitchTableViewCell"  bundle:nil]
		 forCellReuseIdentifier:[SwitchTableViewCell reuseIdentifier]];
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
	hostTextCell = nil;
	sslSwitchCell = nil;
	externalSwitchCell = nil;
	portTextCell = nil;
	pathTextCell = nil;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return NUM_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (section == SERVER_SECTION)
		return 1;
	
	if (section == ADVANCED_SECTION)
		return NUM_ADVANCED_ROWS;
	
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SERVER_SECTION) 
	{
		NSString * cellIdentifier = [EditingTableViewCell reuseIdentifier];
		EditingTableViewCell * textEditCell = (EditingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		
		textEditCell.label.text = NSLocalizedString(@"Host",@"Host name label");
		textEditCell.textField.text = self.connection ? self.connection.host : nil;
		textEditCell.textField.placeholder = NSLocalizedString(@"host.example.com",@"Host name example");
		textEditCell.textField.keyboardType = UIKeyboardTypeURL;
		textEditCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		textEditCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
		hostTextCell = textEditCell;
		
		return textEditCell;
	}
	else if (indexPath.section == ADVANCED_SECTION)
	{
        if ((indexPath.row == USE_SSL_ROW) || (indexPath.row == IS_EXTERNAL_ROW))
        {
			NSString * cellIdentifier = [SwitchTableViewCell reuseIdentifier];
            SwitchTableViewCell * switchEditCell = (SwitchTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (indexPath.row == USE_SSL_ROW) 
            {
                switchEditCell.label.text = NSLocalizedString(@"Secure",@"Connection secure label");
                switchEditCell.switchField.on = self.connection ? self.connection.useSsl : YES;
                sslSwitchCell = switchEditCell;
            }
            else if (indexPath.row == IS_EXTERNAL_ROW) 
            {
                switchEditCell.label.text = NSLocalizedString(@"External",@"Connection external label");
                switchEditCell.switchField.on = self.connection ? self.connection.isExternal : YES;
                externalSwitchCell = switchEditCell;
            }
            
            return switchEditCell;
        }
        else 
        {
			NSString * cellIdentifier = [EditingTableViewCell reuseIdentifier];
            EditingTableViewCell * textEditCell = (EditingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if (indexPath.row == PORT_ROW) 
            {
                textEditCell.label.text = NSLocalizedString(@"Port",@"Connection port label");
                textEditCell.textField.text = self.connection ? [NSString stringWithFormat:@"%d",connection.port] : @"443";
                textEditCell.textField.keyboardType = UIKeyboardTypeNumberPad;
                portTextCell = textEditCell;
            }
            else if (indexPath.row == PATH_ROW) 
            {
                textEditCell.label.text = NSLocalizedString(@"Path",@"Connection path label");
                textEditCell.textField.text = connection ? connection.path : @"MessagingAndRouting";
				textEditCell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
				textEditCell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
                pathTextCell = textEditCell;
            }
            
            return textEditCell;
        }
	}
    
    return nil;
}


#pragma mark - User interface callbacks

- (IBAction)save
{
	if (([hostTextCell.textField.text length] > 0) &&
		([pathTextCell.textField.text length] > 0))
	{
		connection = [[ConnectionProfile alloc] initWithHost:hostTextCell.textField.text
													  useSsl:sslSwitchCell.switchField.on
												  isExternal:externalSwitchCell.switchField.on
														port:[portTextCell.textField.text intValue]
														path:pathTextCell.textField.text];
		
		[ConnectionDatabase setActiveProfile:connection];
		[addConnectionDelegate connectionAdded:connection];
	}
}

- (IBAction)cancel
{
	[addConnectionDelegate connectionAdded:nil];
}

@end

