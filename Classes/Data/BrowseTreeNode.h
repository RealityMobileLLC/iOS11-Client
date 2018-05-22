//
//  BrowseTreeNode.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/24/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

// Define this to create three top-level browse categories for Cameras, Screencasts, and Files.
//#define RV_USES_GET_ALL_CAMERAS


#ifdef RV_USES_GET_ALL_CAMERAS
/**
 *  The root category for RealityVision fixed cameras.
 */
extern NSString * const RootCategoryCameras;

/**
 *  The root category for RealityVision screencasts.
 */
extern NSString * const RootCategoryScreencasts;

/**
 *  The root category for RealityVision video files.
 */
extern NSString * const RootCategoryFiles;
#endif


/**
 *  A tree whose leaf nodes contain CameraInfoObjects.
 */
@interface BrowseTreeNode : NSObject 

/**
 *  The parent of this node or nil if this is the root node.
 */
@property (weak, nonatomic,readonly) BrowseTreeNode * parent;

/**
 *  The title of this node.
 */
@property (strong, nonatomic,readonly) NSString * title;

/**
 *  An array containing all of the cameras in the entire browse tree.  This
 *  array contains only CameraInfoWrapper objects.
 */
@property (strong, nonatomic,readonly) NSArray * allCameras;

/**
 *  An array containing all of the children of this node.  Each element of the
 *  array is either a BrowseTreeNode representing a subcategory of cameras, or
 *  a CameraInfoWrapper representing a viewable camera.
 */
@property (strong, nonatomic,readonly) NSArray * childrenForCategoryView;

/**
 *  An array containing all of the leaf nodes of this node and each of its
 *  child nodes.  Each element of the array is a CameraInfoWrapper representing
 *  a viewable camera.
 */
@property (strong, nonatomic,readonly) NSArray * childrenForListView;

/**
 *  Initializes a new BrowseTreeNode root object with the given cameras.
 *  
 *  @param cameras An array of CameraInfoWrapper objects.
 *  @param title   The title to use for the root node.
 */
- (id)initWithCameras:(NSArray *)cameras andTitle:(NSString *)title;

/**
 *  Returns the BrowseTreeNode for the given category, if that category is
 *  a direct subcategory of the current node.
 *  
 *  @param category Subcategory to get, or nil if category not found.
 */
- (BrowseTreeNode *)getCategory:(NSString *)category;

/**
 *  Returns an NSComparisonResult value that indicates the lexical ordering of 
 *  the receiver and another BrowseTreeNode object.  The comparison is
 *  performed on the title property of the two objects.
 *  
 *  @param node The node with which to compare the receiver.
 *  
 *  @return NSOrderedAscending if the receiver precedes node; 
 *          NSOrderedSame if the receiver and node are equivalent;
 *          and NSOrderedDescending if the receiver follows node.
 */
- (NSComparisonResult)compare:(BrowseTreeNode *)node;

@end
