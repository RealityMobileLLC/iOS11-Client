//
//  DetailCameraDataSource.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/3/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "DetailCameraDataSource.h"
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
	Details_Row_Name,
	Details_Row_Description,
	Details_Row_Categories,
	Details_Row_Status
};


@interface DetailCameraDataSource()
@property (nonatomic,readonly) NSInteger favoriteButtonRow;
@property (nonatomic,readonly) NSInteger watchButtonRow;
@end


@implementation DetailCameraDataSource

- (id)initWithCameraDetails:(CameraInfoWrapper *)theCamera
{
	self = [super init];
	if (self != nil)
	{
		self.camera = theCamera;
	}
	return self;
}

- (NSString *)title
{
	return self.camera.isScreencast ? NSLocalizedString(@"Screencast Info", @"Screencast info title") :
	       self.camera.isVideoFile  ? NSLocalizedString(@"Video File Info", @"Video file info title")
	                                : NSLocalizedString(@"Camera Info",     @"Camera info title");
}

- (NSInteger)favoriteButtonRow
{
    return self.camera.canBeFavorite ? 0 : -1;
}

- (NSInteger)watchButtonRow
{
    return self.favoriteButtonRow + 1;
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
			return 1;
			
		case Section_Buttons:
			return self.camera.canBeFavorite ? 2 : 1;
			
		default:
			DDLogWarn(@"Invalid section for DetailCameraDataSource");
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
	UITableViewCell * cell = [self tableViewCellForCameraDetails:tableView];
	
	switch (row)
	{
		case Details_Row_Name:
			cell.textLabel.text = NSLocalizedString(@"Name",@"Camera caption (name) label");
			cell.detailTextLabel.text = self.camera.name;
			break;
			
		case Details_Row_Description:
            cell.textLabel.text = (self.camera.isScreencast) ? NSLocalizedString(@"Start Time",@"Screencast start time label")
		                                                     : NSLocalizedString(@"Description",@"Camera description label");
			cell.detailTextLabel.text = self.camera.description;
			break;
			
		case Details_Row_Categories:
			cell.textLabel.text = NSLocalizedString(@"Categories",@"Camera categories label");
			cell.detailTextLabel.text = self.camera.categories;
			break;
			
		default:
			DDLogWarn(@"Invalid row for DetailCameraDataSource");
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
	
	if (row == self.favoriteButtonRow)
	{
		[self initFavoriteButtonLabel:cell.textLabel forTableView:tableView];
	}
	else if (row == self.watchButtonRow)
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
			DDLogWarn(@"Invalid section for DetailCameraDataSource");
	}
	
    return nil;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if (indexPath.section == Section_Buttons)
	{
		if (indexPath.row == self.favoriteButtonRow)
		{
			[self toggleFavoriteAndRefreshTableView:tableView];
		}
		else if (indexPath.row == self.watchButtonRow)
		{
			[self showVideo];
		}
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
