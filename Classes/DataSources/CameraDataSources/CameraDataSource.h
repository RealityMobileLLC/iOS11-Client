//
//  CameraDataSource.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/20/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CameraDataSource;


/**
 *  Protocol used to get the list of cameras returned by a CameraDataSource.
 *  
 *  Classes that implement this protocol will generally choose to implement
 *  either cameraListUpdatedForDataSource: or both dataSource:addedCameras: and
 *  dataSource:removedCameras:.
 *
 *  When implementing cameraListUpdatedForDataSource:, the recipient must get
 *  the new list of cameras from the data source.  This method is called 
 *  whenever the getCameras: method successfully receives new camera data from
 *  a web service, even if the list of cameras received is the same as the
 *  list of cameras the data source already had.
 *  
 *  When implementing dataSource:addedCameras:, dataSource:removedCameras:, 
 *  and dataSource:updatedCameras:, the recipient is provided the list of changed 
 *  cameras.  These methods are only called when the list of cameras returned 
 *  from a web service has added, removed, or updated cameras from the list the 
 *  data source already had.
 */
@protocol CameraDataSourceDelegate <NSObject>

@optional

/**
 *  Called when the CameraDataSource has updated data.
 *  
 *  @param dataSource The data source that has an updated list of cameras.
 */
- (void)cameraListUpdatedForDataSource:(CameraDataSource *)dataSource;

/**
 *  Called when the CameraDataSource has added new cameras.
 *  
 *  @param dataSource The data source that has an updated list of cameras.
 *  @param cameras The list of cameras that have been added.
 */
- (void)dataSource:(CameraDataSource *)dataSource addedCameras:(NSArray *)cameras;

/**
 *  Called when the CameraDataSource has removed cameras.
 *  
 *  @param dataSource The data source that has an updated list of cameras.
 *  @param cameras The list of cameras that have been removed.
 */
- (void)dataSource:(CameraDataSource *)dataSource removedCameras:(NSArray *)cameras;

/**
 *  Called when the CameraDataSource has cameras with map properties that have been updated.
 *  
 *  @param dataSource The data source that has an updated list of cameras.
 *  @param cameras The list of cameras that have been updated.
 */
- (void)dataSource:(CameraDataSource *)dataSource updatedCameras:(NSArray *)cameras;

/**
 *  Called when the CameraDataSource has an error to report.
 *
 *  @param error The error that prevented the camera list from being downloaded,
 *               or nil if no error occurred.
 */
- (void)cameraListDidGetError:(NSError *)error;

@end


/**
 *  An abstract class used to define the interface for asynchronously
 *  retrieving a list of cameras and providing the list to a delegate.
 *
 *  This class should never be instantiated directly.
 */
@interface CameraDataSource : NSObject 
{
@protected
	NSMutableArray * cameras;
	NSMutableArray * filteredCameras;
	BOOL             hidden;
	BOOL             isLoading;
	NSInteger        numberOfCamerasWithLocation;
}

/**
 *  Delegate that will be notified when the list of cameras have been
 *  retrieved or an error has occurred.
 */
@property (nonatomic,weak) id <CameraDataSourceDelegate> delegate;

/**
 *  Title to use when displaying this camera list.
 */
@property (strong, nonatomic,readonly) NSString * title;

/**
 *  Text to display when the data source is loading.
 */
@property (strong, nonatomic,readonly) NSString * loadingCamerasText;

/**
 *  Text to display when the data source is empty.
 */
@property (strong, nonatomic,readonly) NSString * noCamerasText;

/**
 *  Text to display as a placeholder in a searchbar.
 */
@property (strong, nonatomic,readonly) NSString * searchPlaceholderText;

/**
 *  Whether the cameras for this data source should be hidden on a map view.
 */
@property (nonatomic) BOOL hidden;

/**
 *  Whether the CameraDataSource supports cameras with Pan-Tilt-Zoom controls.
 */
@property (nonatomic,readonly) BOOL supportsPtz;

/**
 *  Whether the CameraDataSource supports editing the camera list.
 */
@property (nonatomic,readonly) BOOL supportsEdit;

/**
 *  Whether the CameraDataSource supports a category view of the cameras.
 */
@property (nonatomic,readonly) BOOL supportsCategories;

/**
 *  Whether the CameraDataSource supports the refresh method.
 */
@property (nonatomic,readonly) BOOL supportsRefresh;

/**
 *  Whether the CameraDataSource is currently showing categories.
 *  YES means the data source is showing categories.
 *  NO means the data source is showing a list of only cameras.
 *  The value is meaningless if supportsCategories returns NO.
 */
@property (nonatomic,readonly) BOOL isShowingCategories;

/**
 *  Whether the CameraDataSource is still waiting for the list of cameras.
 */
@property (nonatomic,readonly) BOOL isLoading;

/**
 *  Whether the CameraDataSource supports paging.  Paged data sources return
 *  only partial results from the server when getCameras is called.
 *
 *  Paged data sources must also support the getMoreCameras method to return
 *  the next set of results, as well as the hasMoreCameras property which
 *  indicates whether there are more results to get.
 */
@property (nonatomic,readonly) BOOL supportsPaging;

/**
 *  For data sources that support paging, indicates whether there are more
 *  cameras on the server.  If this property returns YES, a call to 
 *  getMoreCameras will update the list of cameras.
 */
@property (nonatomic,readonly) BOOL hasMoreCameras;

/**
 *  For data sources that support paging, provides the total number of
 *  cameras on the server.
 */
@property (nonatomic,readonly) NSInteger totalCameras;

/**
 *  The total number of cameras currently loaded by this data source.
 */
@property (nonatomic,readonly) NSUInteger numberOfCameras;

/**
 *  The total number of cameras that match the current filter.
 */
@property (nonatomic,readonly) NSUInteger numberOfFilteredCameras;

/**
 *  The number of cameras currently loaded by this data source that have a location.
 */
@property (nonatomic,readonly) NSUInteger numberOfCamerasWithLocation;

/**
 *  The list of all cameras as CameraInfoWrapper objects.
 */
@property (strong, nonatomic,readonly) NSArray * cameras;

/**
 *  For data sources that support categories, the list of all cameras in the
 *  current category and its subcategories.  For data sources that don't 
 *  support categories, returns the same list as the cameras property.
 */
@property (strong, nonatomic,readonly) NSArray * camerasInCategory;

/**
 *  Requests a list of cameras from the data source.  If the data source
 *  doesn't have a list of cameras yet, it will start an asynchronous web
 *  service call to retrieve it.  If desired, subclasses may cache the list
 *  of cameras and immediately notify the delegate from within this method.
 *  
 *  This is a virtual method whose implementation must be provided by its
 *  subclasses.
 */
- (void)getCameras;

/**
 *  Requests the next set of cameras from a paged data source.  This should
 *  only be called if supportsPaging returns YES.
 *  
 *  This is a virtual method whose implementation should be provided only
 *  for subclasses that support paging.
 */
- (void)getMoreCameras;

/**
 *  Forces an asynchronous web service call to refresh the list of cameras.
 *
 *  This is a virtual method whose implementation must be provided by its
 *  subclasses.
 */
- (void)refresh;

/**
 *  Cancels any pending asynchronous calls to retrieve the list of cameras.
 *
 *  This is a virtual method whose implementation must be provided by its
 *  subclasses.
 */
- (void)cancel;

/**
 *  Calls cancel to stop any pending operations and then clears the list of cameras.
 *  
 *  Subclasses should first call [super reset] and then reset their own
 *  members back to the init state.
 */
- (void)reset;

/**
 *  Switches between a category view of the cameras and the full list.
 *  Calling this when supportsCategories returns NO does nothing.
 */
- (void)toggleCategoryView;

/**
 *  Returns the number of sections for the camera list.
 */
- (NSInteger)numberOfSections;

/**
 *  Returns the number of sections for the filtered camera list.
 */
- (NSInteger)numberOfFilteredSections;

/**
 *  Returns the number of rows in the given section of the camera list.
 */
- (NSInteger)numberOfRowsInSection:(NSInteger)section;

/**
 *  Returns the number of rows in the given section of the filtered camera list.
 */
- (NSInteger)numberOfRowsInFilteredSection:(NSInteger)section;

/**
 *  Returns the title for a section of the camera list.
 */
- (NSString *)titleForHeaderInSection:(NSInteger)section;

/**
 *  Returns the title for a section of the filtered camera list.
 */
- (NSString *)titleForHeaderInFilteredSection:(NSInteger)section;

/**
 *  Gets the object to display at the given index path.  The object will either 
 *  be a BrowseTreeNode representing a subcategory of cameras, or a 
 *  CameraInfoWrapper representing a viewable camera feed.
 *  
 *  @param indexPath An index path representing a row in a table view.
 *  @return the object to be displayed
 */
- (id)browseTreeNodeAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Gets the object to display at the given index path for the filtered camera
 *  list.  The object will either be a BrowseTreeNode representing a subcategory 
 *  of cameras, or a CameraInfoWrapper representing a viewable camera feed.
 *  
 *  @param indexPath An index path representing a row in a table view.
 *  @return the object to be displayed
 */
- (id)browseTreeNodeAtFilteredIndexPath:(NSIndexPath *)indexPath;

/**
 *  Indicates whether the row at the given index path can be deleted.
 *  
 *  @param indexPath An index path representing a row in a table view.
 *  @return YES if row can be deleted
 */
- (BOOL)canDeleteRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Indicates whether the row at the given index path for the filtered camera
 *  list can be deleted.
 *  
 *  @param indexPath An index path representing a row in a table view.
 *  @return YES if row can be deleted
 */
- (BOOL)canDeleteRowAtFilteredIndexPath:(NSIndexPath *)indexPath;

/**
 *  Deletes the row at the given index path.
 *  
 *  @param indexPath An index path representing a row in a table view.
 *  @return YES if deleting the row caused the section to also be deleted.
 */
- (BOOL)deleteRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Deletes the row at the given index path for the filtered camera list.
 *  
 *  @param indexPath An index path representing a row in a table view.
 *  @return YES if deleting the row caused the section to also be deleted.
 */
- (BOOL)deleteRowAtFilteredIndexPath:(NSIndexPath *)indexPath;

/**
 *  Sets the filteredCameras property to include only those cameras whose name
 *  includes the given search text.
 *  
 *  @param searchText Text used to filter the camera list.
 *  @return YES if data source supports filtering
 */
- (BOOL)filterCamerasForSearchText:(NSString *)searchText;

/**
 *  Searches for the given text.  This is intended for data sources that do not
 *  support filtering, such as data sources that require that searches be done
 *  on the server.  The default implementation does nothing.
 *  
 *  @param searchText Text used when searching the camera list.
 */
- (void)searchForText:(NSString *)searchText;

/**
 *  Indicates that the data source should no longer use the results from a
 *  previous call to searchForText.  This is intended for data sources that do
 *  not support filtering, such as data sources that require that searches be
 *  done on the server.  The default implementation does nothing.
 */
- (void)endSearch;

/**
 *  Returns an array of CameraInfoWrapper objects that merges an existing array 
 *  with a new one.  The objects in the existing array that are still in the 
 *  new array will be placed in the merged array and updated with the new 
 *  values.  Objects in the new array that aren't in the old array will be 
 *  placed in the merged array.  Objects in the old array that aren't in the 
 *  new array will not be placed in the merged array.
 *  
 *  The end result will be that merged array will contain all of the cameras
 *  from the new array but using the objects from the old array when possible.
 *  
 *  It also adds cameras that are in the new array but not in the old array to
 *  the camerasAdded array; and cameras that are in the old array but not in
 *  the new array to the camerasRemoved array.
 *  
 *  This is intended as a convenience for subclasses to identify cameras that
 *  have been added or removed since the last call to a web service.
 *  
 *  Note that the implementation of this method assumes that the order of items
 *  in oldList and newList are the same.  That is, if the two lists contain the
 *  same cameras, they will be in the same order.
 *  
 *  The current implementation is O(n) and *may* be inefficient with very large 
 *  numbers of cameras.  An implementation using sets or dictionaries *might*
 *  scale better but would probably be less efficient with a smaller number of
 *  cameras.  No performance testing has been done so this should only be
 *  revisited if a problem arises.
 *  
 *  @param oldList The existing array of CameraInfoWrapper objects, or nil.
 *  @param newList The new array of CameraInfoWrapper objects.  Must not be nil.
 *  @param camerasAdded On exit, contains all of the cameras that are in newList but not in oldList.
 *  @param camerasRemoved On exit, contains all of the cameras that are in oldList but not in newList.
 *  @return merged array of CameraInfoWrapper objects.
 */
- (NSMutableArray *)updateCameras:(NSArray *)oldList 
						fromArray:(NSArray *)newList
					 camerasAdded:(NSMutableArray *)camerasAdded 
				   camerasRemoved:(NSMutableArray *)camerasRemoved
				   camerasUpdated:(NSMutableArray *)camerasUpdated;

/**
 *  Notifies the delegate of an updated camera list by sending it a 
 *  cameraListUpdatedForDataSource: message.  Also calls 
 *  dataSource:addedCameras: and/or dataSource:removedCameras: if either of
 *  the corresponding arrays has any elements.
 *  
 *  @param camerasAdded Array of cameras to be given to dataSource:addedCameras:.
 *                      This can not be nil.
 *  @param camerasRemoved Array of cameras to be given to dataSource:removedCameras:.
 *                        This can not be nil.
 */
- (void)notifyDelegateCamerasAdded:(NSArray *)camerasAdded 
                    camerasRemoved:(NSArray *)camerasRemoved
					camerasUpdated:(NSArray *)camerasUpdated;

@end
