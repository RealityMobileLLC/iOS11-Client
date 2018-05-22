//
//  UIImage+RealityVision.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/26/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import "UIImage+RealityVision.h"


@implementation UIImage (RealityVision)


+ (UIImage *)image:(UIImage *)image resizedTo:(CGSize)size
{
	// find scaling value needed to fit image inside new boundaries
	CGFloat scale = MIN(size.width  / image.size.width, 
						size.height / image.size.height);
	
	CGFloat newWidth  = image.size.width  * scale;
	CGFloat newHeight = image.size.height * scale;
	
	CGFloat newX = MAX((size.width  - newWidth)  / 2.0, 0.0);
	CGFloat newY = MAX((size.height - newHeight) / 2.0, 0.0);
	
	UIGraphicsBeginImageContext(size);
	[image drawInRect:CGRectMake(newX, newY, newWidth, newHeight)];
	UIImage * resizedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return resizedImage;
}


+ (UIImage *)image:(UIImage *)image resizedToFit:(CGSize)maxSize
{
	BOOL imageAlreadyFits = ((image.size.width <= maxSize.width) && (image.size.height <= maxSize.height));
	return imageAlreadyFits ? image : [UIImage image:image resizedTo:maxSize];
}


+ (UIImage *)image:(UIImage *)image resizedToFitHeight:(CGFloat)maxHeight
{
	if (image.size.height <= maxHeight)
		return image;
	
	CGFloat scale = maxHeight / image.size.height;
	
	CGFloat newWidth  = image.size.width  * scale;
	CGFloat newHeight = image.size.height * scale;
	
	UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
	[image drawInRect:CGRectMake(0.0, 0.0, newWidth, newHeight)];
	UIImage * resizedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return resizedImage;
}


@end
