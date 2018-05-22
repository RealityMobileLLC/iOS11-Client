//
//  UIImage+RealityVision.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/26/11.
//  Copyright 2011 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  The RealityVision category extends UIImage to provide custom functionality.
 */
@interface UIImage (RealityVision) 

/**
 *  Returns an image containing the given image scaled to the requested size.
 *  The aspect ratio of the image doesn't change.
 *  
 *  @param image The image to resize.
 *  @param size  The size of the returned image.
 *  @return resized image
 */
+ (UIImage *)image:(UIImage *)image resizedTo:(CGSize)size;

/**
 *  Returns an image containing the given image shrunk to fit in the requested 
 *  size.  If the original image is smaller than maxSize, it is returned.
 *  
 *  @param image   The image to resize.
 *  @param maxSize The maximum size of the returned image.
 *  @return resized image
 */
+ (UIImage *)image:(UIImage *)image resizedToFit:(CGSize)maxSize;

/**
 *  Returns an image containing the given image shrunk to fit in the requested 
 *  height.  If the original image is smaller than maxHeight, it is returned.
 *  
 *  @param image     The image to resize.
 *  @param maxHeight The maximum height of the returned image.
 *  @return resized image
 */
+ (UIImage *)image:(UIImage *)image resizedToFitHeight:(CGFloat)maxHeight;

@end
