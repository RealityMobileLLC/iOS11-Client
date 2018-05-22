//
//  DetailDataSource.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 3/3/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "DetailDataSource.h"
#import "CameraStatusTableViewCell.h"
#import "MotionJpegMapViewController.h"
#import "ThumbnailTableViewCell.h"
#import "RealityVisionAppDelegate.h"


@implementation DetailDataSource
{
	UITableView * __weak theTableView;   // currently only used to update the favorite button label
	BOOL haveFavorites;                  // becomes YES once favorites have been retrieved
	BOOL isFavorite;                     // not valid unless haveFavorites is YES
}

@synthesize camera;


- (void)setCamera:(CameraInfoWrapper *)theCamera
{
	camera = theCamera;
}

- (NSString *)title
{
	return @"";
}

- (void)initFavoriteButtonLabel:(UILabel *)label forTableView:(UITableView *)tableView
{
	theTableView = tableView;
	
	if (! haveFavorites)
	{
		// initialize isFavorite only if this is the first time we have favorites
		haveFavorites = ([FavoritesManager favorites] != nil);
		isFavorite = haveFavorites ? [FavoritesManager isAFavorite:camera] : NO;
	}
	
	label.text = isFavorite ? NSLocalizedString(@"Remove from Favorites",@"Remove Favorite button")
	                        : NSLocalizedString(@"Add to Favorites",@"Add Favorite button");
	label.enabled = haveFavorites;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	[self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (UITableViewCell *)tableViewCellForCameraDetails:(UITableView *)tableView
{
	static NSString * CellIdentifier = @"CameraCell";
	
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) 
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.detailTextLabel.numberOfLines = 3;
		cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
	}
	
	return cell;
}

- (UITableViewCell *)tableViewCellForCameraStatus:(UITableView *)tableView
{
	NSString * cellIdentifier = [CameraStatusTableViewCell reuseIdentifier];
	CameraStatusTableViewCell * cell = (CameraStatusTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	cell.locationImage.highlighted = self.camera.hasLocation;
	cell.locationLabel.hidden = ! self.camera.hasLocation;
	cell.ptzImage.highlighted = self.camera.isPanTiltZoom;
	cell.ptzLabel.hidden = ! self.camera.isPanTiltZoom;
	
	return cell;
}

- (UITableViewCell *)tableViewCellForCameraThumbnail:(UITableView *)tableView
{
	NSString * cellIdentifier = [ThumbnailTableViewCell reuseIdentifier];
	ThumbnailTableViewCell * cell = (ThumbnailTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	cell.imageView.image = self.camera.thumbnail ? self.camera.thumbnail : [UIImage imageNamed:@"ic_list_inactive_thumbnail"];
	
	return cell;
}

- (void)toggleFavoriteAndRefreshTableView:(UITableView *)tableView
{
	if (! haveFavorites)
		return;
	
	if (isFavorite)
	{
		[FavoritesManager remove:self.camera];
	}
	else 
	{
		[FavoritesManager add:self.camera];
	}
	
	isFavorite = ! isFavorite;
	[tableView reloadData];
}

- (void)showVideo
{
	MotionJpegMapViewController * viewController = 
		[[MotionJpegMapViewController alloc] initWithNibName:@"MotionJpegMapViewController" 
													   bundle:nil];
	viewController.camera = camera;
	
	RealityVisionAppDelegate * appDelegate = [UIApplication sharedApplication].delegate;
	[appDelegate.navigationController pushViewController:viewController animated:YES];
}


#pragma mark - FavoritesObserver methods

- (void)favoritesUpdated:(NSArray *)favorites orError:(NSError *)error
{
	haveFavorites = (favorites != nil);
	if (haveFavorites)
	{
		isFavorite = [FavoritesManager isAFavorite:camera];
		[theTableView reloadData];
	}
}

@end
