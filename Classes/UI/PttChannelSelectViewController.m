//
//  PttChannelSelectViewController.m
//  Cannonball
//
//  Created by Thomas Aylesworth on 3/27/12.
//  Copyright (c) 2012 Reality Mobile. All rights reserved.
//

#import "PttChannelSelectViewController.h"
#import "Channel.h"



@implementation PttChannelSelectViewController
{
	NSArray  * channels;
	NSString * selectedChannel;
}

@synthesize delegate;
@synthesize showCancelButton;


#pragma mark - Initialization and cleanup

- (id)initWithAvailableChannels:(NSArray *)theChannels selectedChannel:(NSString *)theSelectedChannel
{
	self = [self initWithNibName:@"PttChannelSelectViewController" bundle:nil];
	if (self != nil)
	{
		channels = [theChannels sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) 
					                                       {
															   Channel * c1 = (Channel *)obj1;
															   Channel * c2 = (Channel *)obj2;
					                                           return [c1.name localizedCompare:c2.name];
					                                       }];
		selectedChannel = theSelectedChannel;
	}
	return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
	NSAssert([channels count]>0,@"There are no channels to select");
    [super viewDidLoad];
	self.navigationItem.title = NSLocalizedString(@"Channels", @"Channels title");
	
	if (showCancelButton)
	{
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
																							   target:self 
																							   action:@selector(cancelPressed)];
	}
	
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES;
	
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (CGSize)contentSizeForViewInPopover
{
	NSUInteger rowsToShow = MIN(MAX([channels count] + 1, 6), 11);
    CGSize size = CGSizeMake(320, self.tableView.rowHeight * rowsToShow);
    return size;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [channels count]+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"Cell";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
	NSString * name;
	NSString * description;
	BOOL channelIsSelected;
	
	if (indexPath.row == 0)
	{
		// "off" channel is always the first row
		name = NSLocalizedString(@"Off", @"Off channel name");
		description = @"";
		channelIsSelected = (selectedChannel == nil);
	}
	else 
	{
		Channel * theChannel = [channels objectAtIndex:indexPath.row-1];
		name = theChannel.name;
		description = theChannel.description;
		channelIsSelected = [selectedChannel isEqualToString:theChannel.name];
	}
	
	cell.textLabel.text = name;
	cell.detailTextLabel.text = description;
	cell.accessoryType = channelIsSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Channel * channel = (indexPath.row == 0) ? nil : [channels objectAtIndex:indexPath.row-1];
	
	// if user selected currently selected channel, cancel selection
	if ((channel == nil && selectedChannel == nil) || ([selectedChannel isEqualToString:[channel name]]))
	{
		[delegate pttChannelSelectionCancelled];
		return;
	}
	
	// update selected channel and notify delegate
	selectedChannel = [channel name];
	[tableView reloadData];
	[delegate pttChannelSelected:selectedChannel];
}


#pragma mark - Button actions

- (void)cancelPressed
{
	[delegate pttChannelSelectionCancelled];
}

@end
