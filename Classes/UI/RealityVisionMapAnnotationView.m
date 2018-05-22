//
//  RealityVisionMapAnnotationView.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 1/6/12.
//  Copyright (c) 2012 Reality Mobile LLC. All rights reserved.
//

#import "RealityVisionMapAnnotationView.h"
#import "UIView+Layout.h"
#import "RealityVisionClient.h"



@implementation RealityVisionMapAnnotationView

static BOOL showSourceNames;

+ (void)initialize
{
    if (self == [RealityVisionMapAnnotationView class])
    {
        showSourceNames = YES;
    }
}

- (void)setAnnotation:(id<MKAnnotation>)annotation
{
	[super setAnnotation:annotation];
	[self update];
}

- (UIImage *)sourceImage
{
    NSAssert(NO, @"RealityVisionMapAnnotationView image property must be implemented by descendent class");
    return nil;
}

- (NSString *)sourceName
{
    NSAssert(NO, @"RealityVisionMapAnnotationView name property must be implemented by descendent class");
    return nil;
}

- (UIImage *)sourceImageWithName
{
    UIImage  * sourceImage = [self sourceImage];
    NSString * sourceName  = [self sourceName];
    
    // calculate size of image and name
    UIFont * font = [UIFont systemFontOfSize:16];
    CGSize imageSize = sourceImage.size;
    CGSize nameSize = [sourceName sizeWithFont:font];
    CGPoint nameOrigin = CGPointMake(imageSize.width + 5, CENTER(imageSize.height,nameSize.height));
    CGSize sourceImageWithNameSize = CGSizeMake(nameOrigin.x + nameSize.width, imageSize.height);
    
    // create a graphics context
    UIGraphicsBeginImageContextWithOptions(sourceImageWithNameSize, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // draw the image
    CGRect imageRect = CGRectMake(0.0, 0.0, sourceImage.size.height, sourceImage.size.width);
    [sourceImage drawInRect:imageRect];
    
    // draw the name
    MKMapType mapType = [RealityVisionClient instance].mapType;
    CGColorRef textColor = (mapType == MKMapTypeStandard) ? [UIColor blackColor].CGColor : [UIColor whiteColor].CGColor;
    CGColorRef shadowColor = (mapType == MKMapTypeStandard) ? [UIColor whiteColor].CGColor : [UIColor blackColor].CGColor;
    CGContextSetFillColorWithColor(context, textColor);
    CGContextSetShadowWithColor(context, CGSizeMake(2,2), 2, shadowColor);
    [sourceName drawAtPoint:nameOrigin withFont:font];
    
    // get the combined image and name
    UIImage * sourceImageWithName = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return sourceImageWithName;
}

- (void)update
{
    // if the image already exists we need to keep track of the origin because setting centerOffset does not adjust it as expected
    BOOL keepOrigin = (self.image != nil);
    CGPoint origin;
    if (keepOrigin)
    {
        origin = self.frame.origin;
    }
    
    self.image = (showSourceNames) ? [self sourceImageWithName] : [self sourceImage];
    self.centerOffset = CGPointMake((self.image.size.width - self.sourceImage.size.width) / 2.0, 0.0);
    self.calloutOffset = CGPointMake(-self.centerOffset.x, self.calloutOffset.y);
    
    if (keepOrigin)
    {
        self.frame = CGRectMake(origin.x, origin.y, self.frame.size.width, self.frame.size.height);
    }
    
    [self setNeedsDisplay];
}

+ (BOOL)showSourceNames
{
    return showSourceNames;
}

+ (void)setShowSourceNames:(BOOL)newShowSourceNames
{
    showSourceNames = newShowSourceNames;
}

@end
