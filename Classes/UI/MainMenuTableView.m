//
//  MainMenuTableView.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 4/13/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "MainMenuTableView.h"
#import "DeviceCapabilities.h"
#import "MenuItem.h"
#import "MenuTableViewCell.h"
#import "CommandHistoryMenuViewController.h"
#import "RootViewController.h"
#import "WatchMenuViewController.h"
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
    TRANSMIT_MENU_ITEM,
    WATCH_MENU_ITEM,
    HISTORY_MENU_ITEM,
    ALERT_MENU_ITEM
};


@implementation MainMenuTableView
{
	NSArray * menuItems;
}


#pragma mark - Initialization and cleanup

- (id)init
{
	self = [super init];
	if (self != nil)
	{
		NSMutableArray * items = [NSMutableArray arrayWithCapacity:4];
		
		if ([DeviceCapabilities supportsVideo])
		{
			MenuItem * transmit = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Transmit",@"Transmit menu label") 
															image:@"transmit"];
			transmit.tag = TRANSMIT_MENU_ITEM;
			[items addObject:transmit];
		}
		
		MenuItem * watch = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Watch",@"Watch menu label")
													 image:@"watch"];
		watch.tag = WATCH_MENU_ITEM;
		[items addObject:watch];
		
		MenuItem * history = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Command History",@"Command History menu label")
													   image:@"history"];
		history.tag = HISTORY_MENU_ITEM;
		[items addObject:history];
		
		MenuItem * alert = [[MenuItem alloc] initWithLabel:NSLocalizedString(@"Alert",@"Alert menu label")
													 image:@"alert"];
		alert.tag = ALERT_MENU_ITEM;
		[items addObject:alert];
		
		menuItems = items;
		self.mainMenuEnabled = NO;
	}
	return self;
}



#pragma mark - Public properties

- (NSInteger)menuItemCount
{
	return [menuItems count];
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
	cell.selectionStyle = self.mainMenuEnabled ? UITableViewCellSelectionStyleBlue : UITableViewCellSelectionStyleNone;
    
	if (item.tag == WATCH_MENU_ITEM)
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else if (item.tag == HISTORY_MENU_ITEM)
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		[cell setBadgeCount:[RealityVisionClient instance].inboxCommandCount];
	}
	
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	MenuItem * item = [menuItems objectAtIndex:indexPath.row];
	
	if ((item.tag == ALERT_MENU_ITEM) && ([RealityVisionClient instance].isAlerting))
	{
		cell.backgroundColor = [UIColor redColor];
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if (self.mainMenuEnabled)
    {
        MenuItem * item = [menuItems objectAtIndex:indexPath.row];
        DDLogVerbose(@"MainMenuTableView: User selected %@", item.label);
        
        if (item.tag == TRANSMIT_MENU_ITEM)
        {
            [[RealityVisionClient instance] startTransmitSession];
        }
        else if (item.tag == WATCH_MENU_ITEM)
        {
            WatchMenuViewController * viewController = 
				[[WatchMenuViewController alloc] initWithNibName:@"WatchMenuViewController" 
														   bundle:nil];
            
            [[RealityVisionAppDelegate rootViewController].navigationController pushViewController:viewController 
                                                                                          animated:YES];
        }
        else if (item.tag == HISTORY_MENU_ITEM)
        {
            CommandHistoryMenuViewController * viewController = 
                [[CommandHistoryMenuViewController alloc] initWithNibName:@"CommandHistoryMenuViewController" 
                                                                    bundle:nil];
            
            [[RealityVisionAppDelegate rootViewController].navigationController pushViewController:viewController 
                                                                                          animated:YES];
        }
        else if (item.tag == ALERT_MENU_ITEM)
        {
            [[RealityVisionClient instance] toggleAlertMode];
			[tableView reloadData];
        }
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
