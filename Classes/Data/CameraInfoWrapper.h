//
//  CameraInfoWrapper.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/19/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "MapObject.h"
#import "UserDevice.h"

@class CameraInfo;
@class CameraMapViewDelegate;
@class Command;
@class FavoriteEntry;
@class GpsLockStatus;
@class Session;
@class TransmitterInfo;
@class ViewerInfo;


/**
 *  Indicates an invalid coordinate. If/when RealityVision moves to a sane method of
 *  identifying invalid coordinates, this should be mapped to kCLLocationCoordinate2DInvalid.
 *  
 *  @see kCLLocationCoordinate2DInvalid.
 */
extern const CLLocationCoordinate2D RVLocationCoordinate2DInvalid;

/**
 *  Returns a Boolean indicating whether the specified coordinate is valid. Currently a
 *  coordinate is considered invalid if it's latitude and longitude are both 0. If/when
 *  RealityVision moves to a sane method of identifying invalid coordinates, this should
 *  be replaced with a call to CLLocationCoordinate2DIsValid().
 *  
 *  @see CLLocationCoordinate2DIsValid
 */
extern BOOL RVLocationCoordinate2DIsValid(CLLocationCoordinate2D coord);

/**
 *  Enumeration of Pan/Tilt/Zoom commands.
 */
typedef enum 
{
	PTZ_LEFT,
	PTZ_RIGHT,
	PTZ_UP,
	PTZ_DOWN,
	PTZ_ZOOM_IN,
	PTZ_ZOOM_OUT,
	PTZ_HOME,
	PTZ_PAN,
	PTZ_TILT
} PanTiltZoom;


/**
 *  Wrapper that provides properties for using a viewable camera.
 *
 *  @see CameraInfo
 */
@interface CameraInfoWrapper : NSObject <MapObject>

/**
 *  The underlying CameraInfo object.
 */
@property (nonatomic,readonly,strong) CameraInfo * cameraInfo;

/**
 *  The original object used to create this object.  This is only set when the 
 *  CameraInfoWrapper was initialized with a FavoriteEntry or any other class
 *  besides CameraInfo.
 */
@property (strong, nonatomic,readonly) id sourceObject;

/**
 *  The descriptive name for the camera.
 */
@property (strong, nonatomic,readonly) NSString * name;

/**
 *  Subtitle to display for camera.
 */
@property (strong, nonatomic,readonly) NSString * description;

/**
 *  String consisting of comma-separated categories.
 */
@property (strong, nonatomic,readonly) NSString * categories;

/**
 *  The fully qualified URL for the camera feed.
 */
@property (strong, nonatomic,readonly) NSURL * sourceUrl;

/**
 *  RealityVision Command that can be used to view this camera feed when added as a favorite.
 */
@property (strong, nonatomic,readonly) Command * viewCameraCommandForFavorite;

/**
 *  Indicates whether the camera is a video file.
 */
@property (nonatomic,readonly) BOOL isVideoFile;

/**
 *  Indicates whether the camera uses HTTPS.
 */
@property (nonatomic,readonly) BOOL isSecure;

/**
 *  Indicates whether the camera uses RTSP.
 */
@property (nonatomic,readonly) BOOL isRtsp;

/**
 *  Indicates whether the camera is a proxy feed.
 */
@property (nonatomic,readonly) BOOL isProxyFeed;

/**
 *  Indicates whether the camera is a RealityVision video server feed.
 */
@property (nonatomic,readonly) BOOL isVideoServerFeed;

/**
 *  Indicates whether the camera is a RealityVision video server plug-in.
 */
@property (nonatomic,readonly) BOOL isVideoServerPlugin;

/**
 *  Indicates whether the camera is a screencast.
 */
@property (nonatomic,readonly) BOOL isScreencast;

/**
 *  Indicates whether the camera is being accessed directly (i.e., not through the video server).
 */
@property (nonatomic,readonly) BOOL isDirect;

/**
 *  Indicates whether the camera was created from a FavoriteEntry.
 *  
 *  Note that this only indicates whether this particular CameraInfoWrapper object was created
 *  from a FavoriteEntry.  It does not determine whether a camera from another source type
 *  happens to be one of the user's favorites.
 */
@property (nonatomic,readonly) BOOL isFavoriteEntry;

/**
 *  Indicates whether the camera was created from a TransmitterInfo.
 *  
 *  Note that this only indicates whether this particular CameraInfoWrapper object was created
 *  from a TransmitterInfo.  It does not determine whether a camera from another source type
 *  happens to be a live user feed.
 */
@property (nonatomic,readonly) BOOL isTransmitter;

/**
 *  Indicates whether the camera was created from a Session.
 *  
 *  Note that this only indicates whether this particular CameraInfoWrapper object was created
 *  from a TransmitterInfo.  It does not determine whether a camera from another source type
 *  happens to be an archived user feed.
 */
@property (nonatomic,readonly) BOOL isArchivedSession;

/**
 *  Indicates whether the camera is a live feed (transmitter or screencast).
 */
@property (nonatomic,readonly) BOOL isLiveFeed;

/**
 *  Indicates whether the camera is an archive feed.
 */
@property (nonatomic,readonly) BOOL isArchiveFeed;

/**
 *  Indicates whether the user can bookmark this camera as a favorite.
 */
@property (nonatomic,readonly) BOOL canBeFavorite;

/**
 *  Indicates whether the camera has responded to its most recent heartbeat.
 */
@property (nonatomic,readonly) BOOL isAvailable;

/**
 *  Indicates whether the camera supports pan/tilt/zoom.
 */
@property (nonatomic,readonly) BOOL isPanTiltZoom;

/**
 *  Indicates whether the camera has location data.
 */
@property (nonatomic,readonly) BOOL hasLocation;

/**
 *  Indicates whether the camera has a start time.
 */
@property (nonatomic,readonly) BOOL hasStartTime;

/**
 *  The length of the camera feed in seconds, or -1 if ongoing or not known.
 */
@property (nonatomic,readonly) NSTimeInterval length;

/**
 *  The number of comments associated with the camera.
 */
@property (nonatomic,readonly) NSInteger numberOfComments;

/**
 *  Thumbnail for video feed.
 */
@property (strong, nonatomic,readonly) UIImage * thumbnail;

/**
 *  Used to position the camera on a map.
 */
@property (nonatomic) CLLocationCoordinate2D coordinate;

/**
 *  Indicates whether a pin representing this camera on a map should
 *  use a drop animation to display.
 *
 *  On an iPad, this defaults to YES.
 *  On an iPhone it defaults to NO.
 */
@property (nonatomic) BOOL animatesDropOnMap;

/**
 *  Initializes a CameraInfoWrapper object.
 */
- (id)initWithCamera:(CameraInfo *)camera;

/**
 *  Initializes a CameraInfoWrapper object from a transmitter.
 */
- (id)initWithTransmitter:(TransmitterInfo *)transmitter;

/**
 *  Initializes a CameraInfoWrapper object from a favorite.
 */
- (id)initWithFavorite:(FavoriteEntry *)favorite;

/**
 *  Initializes a CameraInfoWrapper object from an archived video session.
 */
- (id)initWithSession:(Session *)session;

/**
 *  Initializes a CameraInfoWrapper object from a viewed video feed.
 */
- (id)initWithViewer:(ViewerInfo *)viewer;

/**
 *  Initializes a CameraInfoWrapper object from a RealityVision CameraInfo
 *  XML document.
 */
- (id)initWithXml:(NSString *)xmlString;

/**
 *  Updates the camera data.  The receiver and newCameraInfo objects must refer
 *  to the same camera.  That is, the type of the sourceObject for both the
 *  receiver and the newCameraInfo object must be the same, and any unique
 *  identifiers for the two objects must also be the same.  All other data
 *  will be updated with the values from newCameraInfo.
 *  
 *  @param newCameraInfo Object whose values are used to update the receiver.
 *  @return YES if receiver's values changed because of the updated.
 */
- (BOOL)updateCameraInfoFrom:(CameraInfoWrapper *)newCameraInfo;

/**
 *  Returns an image that indicates whether the camera is available and/or has
 *  PTZ controls.
 */
- (UIImage *)statusImage;

/**
 *  Returns a URL for viewing an archived video feed starting at the given time.
 *
 *  @param startTime The time at which to start watching the archive.
 *  @return URL used to watch the video, or nil if feed doesn't support a start time
 */
- (NSURL *)urlForStartTime:(NSDate *)startTime;

/**
 *  Returns a URL for viewing the live video feed.
 *  
 *  This is primarily intended for getting the live feed when watching an archive of an actively 
 *  transmitting video server session.  If the feed is a transmitter, the sourceUrl will be 
 *  returned.  If the feed is a video server archive and its sourceUrl has a start time but no 
 *  end time, the returned URL will be the sourceUrl without the start time parameter.  In all 
 *  other cases, the returned URL will be nil.
 *  
 *  @return URL used to watch the live video feed, or nil if operation is not valid for this video
 */
- (NSURL *)urlForLiveFeed;

/**
 *  Returns the fully qualified URL for a pan/tilt/zoom command.
 *  
 *  @param command pan/tilt/zoom command
 *  @return URL
 */
- (NSURL *)panTiltZoomUrl:(PanTiltZoom)command;

/**
 *  Returns an NSComparisonResult value that indicates the lexical ordering of 
 *  the receiver and another CameraInfoWrapper object.  The comparison is
 *  performed on the name property of the two objects.
 *  
 *  @param camera The camera with which to compare the receiver.
 *  @return NSOrderedAscending if the receiver precedes camera; 
 *          NSOrderedSame if the receiver and camera are equivalent;
 *          and NSOrderedDescending if the receiver follows camera.
 */
- (NSComparisonResult)compare:(CameraInfoWrapper *)camera;

/**
 *  Returns an NSComparisonResult value that indicates the lexical ordering of 
 *  the receiver and another CameraInfoWrapper object.  The comparison is
 *  performed on the name property of the two objects.  If the names are 
 *  NSOrderedSame, the comparison is performed on the startTime property of 
 *  the two objects.
 *  
 *  @param camera The camera with which to compare the receiver.
 *  @return NSOrderedAscending if the receiver precedes camera; 
 *          NSOrderedSame if the receiver and camera are equivalent;
 *          and NSOrderedDescending if the receiver follows camera.
 */
- (NSComparisonResult)compareNameAndStartTime:(CameraInfoWrapper *)camera;

/**
 *  Returns an NSComparisonResult value that indicates the lexical ordering of 
 *  the receiver and another CameraInfoWrapper object.  The comparison is
 *  performed on the startTime property of the two objects.
 *  
 *  @param camera The camera with which to compare the receiver.
 *  @return NSOrderedAscending if the receiver precedes camera; 
 *          NSOrderedSame if the receiver and camera are equivalent;
 *          and NSOrderedDescending if the receiver follows camera.
 */
- (NSComparisonResult)compareStartTime:(CameraInfoWrapper *)camera;

/**
 *  If this object is a TransmitterInfo, compare a UserDevice's device ID to this
 *  object's device ID and return true if equal
 *
 *  @param userDevice The UserDevice object whose deviceId will be compared with
 *         this object's device ID, if and only if this object is a TransmitterInfo
 */
- (BOOL)isTransmitterForUserDevice:(UserDevice*)userDevice;

@end
