//
//  ActivityTableViewCell.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 9/11/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "ActivityTableViewCell.h"


@implementation ActivityTableViewCellLoader
@synthesize activityTableViewCell;
@end


@implementation ActivityTableViewCell

@synthesize activityIndicatorView;
@synthesize textLabel;


+ (ActivityTableViewCell *)activityTableViewCellWithText:(NSString *)text andStart:(BOOL)start
{
	ActivityTableViewCellLoader * loader = [[ActivityTableViewCellLoader alloc] init];
	[[NSBundle mainBundle] loadNibNamed:@"ActivityTableViewCell" owner:loader options:nil];
	ActivityTableViewCell * activityTableViewCell = loader.activityTableViewCell;
	
	activityTableViewCell.textLabel.text = text;
	
	if (start)
	{
		[activityTableViewCell.activityIndicatorView startAnimating];
	}
	else 
	{
		[activityTableViewCell.activityIndicatorView stopAnimating];
	}
	
	return activityTableViewCell;
}

- (void)startActivityIndicator
{
	[activityIndicatorView startAnimating];
}

- (void)stopActivityIndicator
{
	[activityIndicatorView stopAnimating];
}

@end
