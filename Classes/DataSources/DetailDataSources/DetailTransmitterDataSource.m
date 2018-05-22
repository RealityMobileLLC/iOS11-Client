//
//  DetailTransmitterDataSource.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/4/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "DetailTransmitterDataSource.h"
#import "TransmitterInfo.h"
#import "FavoritesManager.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


enum 
{
	Section_Details,
	Section_Thumbnail,
	Section_Buttons,
	Num_Sections
};


enum 
{
	Details_Row_User,
	Details_Row_StartTime,
	Details_Row_Device,
	Details_Row_Status
};


enum 
{
	Buttons_Row_Watch
};


@implementation DetailTransmitterDataSource


- (id)initWithCameraDetails:(CameraInfoWrapper *)theCamera
{
	NSAssert(theCamera.isTransmitter,@"Camera must be a Transmitter");
	
	self = [super init];
	if (self != nil)
	{
		self.camera = theCamera;
	}
	return self;
}

- (NSString *)title
{
	return NSLocalizedString(@"User Feed Info",@"User feed info title");
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return Num_Sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	switch (section)
	{
		case Section_Details:
			// assumes Status row is always the final row
			return (self.camera.hasLocation || self.camera.isPanTiltZoom) ? Details_Row_Status + 1 : Details_Row_Status;
			
		case Section_Thumbnail:
		case Section_Buttons:
			return 1;
			
		default:
			DDLogWarn(@"Invalid section for DetailTransmitterDataSource");
	}
	
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const CGFloat DEFAULT_ROW_HEIGHT   =  44.0;
	const CGFloat DETAILS_ROW_HEIGHT   =  60.0;
	const CGFloat THUMBNAIL_ROW_HEIGHT = 128.0;
	
	if (indexPath.section == Section_Details)
	{
		return DETAILS_ROW_HEIGHT;
	}
	else if (indexPath.section == Section_Thumbnail)
	{
		return THUMBNAIL_ROW_HEIGHT;
	}
	
    return DEFAULT_ROW_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForDetailsRow:(NSInteger)row
{
	UITableViewCell * cell        = [self tableViewCellForCameraDetails:tableView];
	TransmitterInfo * transmitter = self.camera.sourceObject;
	
	switch (row)
	{
		case Details_Row_User:
			cell.textLabel.text = NSLocalizedString(@"User",@"User full name label");
			cell.detailTextLabel.text = transmitter.fullName;
			break;
			
		case Details_Row_StartTime:
			cell.textLabel.text = NSLocalizedString(@"Start time",@"Start time label");
			cell.detailTextLabel.text = self.camera.description;
			break;
			
		case Details_Row_Device:
			cell.textLabel.text = NSLocalizedString(@"Device",@"Device name label");
			cell.detailTextLabel.text = transmitter.deviceName;
			break;
			
		default:
			DDLogWarn(@"Invalid row for DetailTransmitterDataSource");
			cell = nil;
	}
			
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForButtonsRow:(NSInteger)row
{
	static NSString * CellIdentifier = @"ButtonCell";
	
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) 
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.textLabel.textColor = [UIColor blueColor];
		cell.textLabel.textAlignment = UITextAlignmentCenter;
	}
	
	if (row == Buttons_Row_Watch)
	{
		cell.textLabel.text = NSLocalizedString(@"Watch Video",@"Watch Video button");
	}
	else 
	{
		DDLogWarn(@"Invalid button row for DetailCameraDataSource");
		cell = nil;
	}
	
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	switch (indexPath.section)
	{
		case Section_Details:
			return (indexPath.row == Details_Row_Status) ? [self tableViewCellForCameraStatus:tableView] 
			                                             : [self tableView:tableView cellForDetailsRow:indexPath.row];
			
		case Section_Thumbnail:
			return [self tableViewCellForCameraThumbnail:tableView];
			
		case Section_Buttons:
			return [self tableView:tableView cellForButtonsRow:indexPath.row];
			
		default:
			DDLogWarn(@"Invalid section for DetailTransmitterDataSource");
	}
	
    return nil;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.section == Section_Buttons)
	{
		if (indexPath.row == Buttons_Row_Watch)
		{
			[self showVideo];
		}
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
