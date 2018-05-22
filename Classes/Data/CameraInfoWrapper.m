//
//  CameraInfoWrapper.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/19/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "CameraInfoWrapper.h"
#import "CameraInfoHandler.h"
#import "QueryString.h"
#import "XmlFactory.h"
#import "ConfigurationManager.h"
#import "SystemUris.h"
#import "CameraInfo.h"
#import "Command.h"
#import "Comment.h"
#import "Device.h"
#import "DirectiveType.h"
#import "FavoriteEntry.h"
#import "Session.h"
#import "TransmitterInfo.h"
#import "ViewerInfo.h"
#import "UIImage+RealityVision.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


static const int TYPE_HTTPS              = 0x01;
static const int TYPE_PROXIED            = 0x02;
static const int TYPE_VIDEOSERVER        = 0x04;
static const int TYPE_SCREENCAST         = 0x08;
static const int TYPE_RTSP               = 0x12;
static const int TYPE_VIDEOFILE          = 0x22;
static const int TYPE_VIDEOSERVER_PLUGIN = 0x40;
static const int TYPE_NOT_FIXED_CAMERA   = 0x6C;  // if any of these bits are set, the source is not a fixed camera or proxy
static const int TYPE_NOT_DIRECT         = 0x7E;  // if any of these bits are set, the source is the RealityVision video server

static NSString * const VIDEO_JPG_DEVICE   = @"video.jpg?device=";
static NSString * const ARCHIVE_START_TIME = @"starttime";
static NSString * const ARCHIVE_STOP_TIME  = @"stoptime";
static NSString * const INCLUDE_SESSION    = @"includesession";

static CGSize THUMBNAIL_SIZE;


// @todo if/when realityvision moves to a sane method of identifying an invalid coordinate, this should be removed 
const CLLocationCoordinate2D RVLocationCoordinate2DInvalid = {0.0, 0.0};

BOOL RVLocationCoordinate2DIsValid(CLLocationCoordinate2D coord)
{
	return coord.latitude != 0.0 || coord.longitude != 0.0;
}


@implementation CameraInfoWrapper
{
	Command * viewCameraCommandForFavorite;
	NSURL   * sourceUrl;
	
	// map annotation members
	CLLocationCoordinate2D coordinate;
    BOOL hasLocation;
    BOOL animatesDropOnMap;
}

@synthesize cameraInfo;
@synthesize sourceObject;
@synthesize coordinate;
@synthesize hasLocation;
@synthesize animatesDropOnMap;
@synthesize cameraViewer;


#pragma mark - Initialization and cleanup

+ (void)initialize
{
	if (self == [CameraInfoWrapper class]) 
	{
		THUMBNAIL_SIZE = CGSizeMake(68.0, 60.0);
	}
}

- (id)initWithCamera:(CameraInfo *)camera
{
	self = [super init];
	if (self != nil)
	{
		cameraInfo = camera;
		sourceObject = camera;
		sourceUrl = nil;
		viewCameraCommandForFavorite = nil;
        hasLocation = NO;
        coordinate = kCLLocationCoordinate2DInvalid;
		
		if (camera.thumbnail != nil)
		{
			camera.thumbnail = [UIImage image:camera.thumbnail resizedTo:THUMBNAIL_SIZE];
		}
		
		[self updateLocation];
	}
	return self;
}

- (id)initWithTransmitter:(TransmitterInfo *)transmitter
{
	self = [super init];
	if (self != nil)
	{
		NSURL * videoServerUrl = [ConfigurationManager instance].systemUris.videoStreamingBase;
		
		cameraInfo = [[CameraInfo alloc] init];
		cameraInfo.caption = transmitter.fullName;
		cameraInfo.description = transmitter.deviceName;
		cameraInfo.startTime = transmitter.startTime;
		cameraInfo.server = [videoServerUrl host];
		cameraInfo.port = [[videoServerUrl port] longLongValue];
		cameraInfo.uri = transmitter.deviceId;
		cameraInfo.cameraType = TYPE_VIDEOSERVER;
		cameraInfo.latitude = transmitter.latitude;
		cameraInfo.longitude = transmitter.longitude;
		
		sourceObject = transmitter;
		sourceUrl = nil;
		viewCameraCommandForFavorite = nil;
        hasLocation = NO;
        coordinate = kCLLocationCoordinate2DInvalid;
		
		if (transmitter.thumbnail != nil)
		{
			cameraInfo.thumbnail = [UIImage image:transmitter.thumbnail resizedTo:THUMBNAIL_SIZE];
		}
		
		[self updateLocation];
	}
	return self;
}

- (id)initWithFavorite:(FavoriteEntry *)favorite
{
	self = [super init];
	if (self != nil)
	{
		NSData * xml = [favorite.openCommand.parameter dataUsingEncoding:NSUnicodeStringEncoding 
													allowLossyConversion:YES];
		cameraInfo = [self parseCameraInfoXml:xml];
		sourceObject = favorite;
		sourceUrl = nil;
		viewCameraCommandForFavorite = nil;
        hasLocation = NO;
        coordinate = kCLLocationCoordinate2DInvalid;
		[self updateLocation];
	}
	return self;
}

- (id)initWithSession:(Session *)session
{
	self = [super init];
	if (self != nil)
	{
		NSURL * videoServerUrl = [ConfigurationManager instance].systemUris.videoStreamingBase;
		
		cameraInfo = [[CameraInfo alloc] init];
		cameraInfo.caption = session.deviceDescription;
		cameraInfo.description = [NSDateFormatter localizedStringFromDate:session.startTime 
																dateStyle:NSDateFormatterMediumStyle    
																timeStyle:NSDateFormatterMediumStyle];
		cameraInfo.startTime = session.startTime;
		cameraInfo.server = [videoServerUrl host];
		cameraInfo.port = [[videoServerUrl port] longLongValue];
		cameraInfo.uri = [self uriForSession:session];
		cameraInfo.cameraType = TYPE_VIDEOSERVER;
		
		sourceObject = session;
		sourceUrl = nil;
		viewCameraCommandForFavorite = nil;
        hasLocation = NO;
        coordinate = kCLLocationCoordinate2DInvalid;
		
		if (session.thumbnail != nil)
		{
			cameraInfo.thumbnail = [UIImage image:session.thumbnail resizedTo:THUMBNAIL_SIZE];
		}
		
		[self updateLocation];
	}
	return self;
}


- (id)initWithViewer:(ViewerInfo *)viewer
{
	self = [super init];
	if (self != nil)
	{
		cameraInfo = [[CameraInfo alloc] init];
		cameraInfo.cameraType = viewer.cameraType;
		
		if ((cameraInfo.cameraType & TYPE_PROXIED) || 
			(cameraInfo.cameraType & TYPE_SCREENCAST) || 
			(cameraInfo.cameraType & TYPE_VIDEOSERVER_PLUGIN))
		{
			cameraInfo.uri = viewer.uri;
			cameraInfo.server = viewer.server;
			cameraInfo.port = viewer.port;
			cameraInfo.caption = viewer.caption;
			cameraInfo.description = viewer.description;
		}
		else 
		{
			cameraInfo.uri = viewer.deviceId;
			cameraInfo.description = viewer.deviceName;
			cameraInfo.caption = viewer.fullName;
			cameraInfo.startTime = viewer.archiveStartTime;
			
			NSURL * videoServerUrl = [ConfigurationManager instance].systemUris.videoStreamingBase;
			cameraInfo.server = [videoServerUrl host];
			cameraInfo.port = [[videoServerUrl port] longLongValue];
		}
		
		sourceObject = viewer;
		sourceUrl = nil;
		viewCameraCommandForFavorite = nil;
        hasLocation = NO;
        coordinate = kCLLocationCoordinate2DInvalid;
		
		if (viewer.thumbnail != nil)
		{
			cameraInfo.thumbnail = [UIImage image:viewer.thumbnail resizedTo:THUMBNAIL_SIZE];
		}
		
		[self updateLocation];
	}
	return self;
}

- (id)initWithXml:(NSString *)xmlString
{
	NSData * xml = [xmlString dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES];
	CameraInfo * camera = [self parseCameraInfoXml:xml];
	
	self = [self initWithCamera:camera];
	return self;
}


#pragma mark - Public methods

- (BOOL)updateCameraInfoFrom:(CameraInfoWrapper *)newCameraInfo
{
    if ((newCameraInfo == self) || (! [self isEqual:newCameraInfo]))
    {
        // should never happen but just in case ...
        DDLogWarn(@"CameraInfoWrapper updateCameraInfoFrom: called with invalid new camera");
        return NO;
    }
    
    // return YES only if something has changed that affects how the camera is displayed on a map (location, heartbeat, etc.)
	BOOL hasChanged = NO;
    
    if (sourceObject != newCameraInfo.sourceObject)
    {
        sourceObject = newCameraInfo.sourceObject;
    }
    
    sourceUrl = nil;
    
    if ([sourceObject isKindOfClass:[TransmitterInfo class]])
    {
        TransmitterInfo * transmitter = sourceObject;
        if ((cameraInfo.latitude != transmitter.latitude) || (cameraInfo.longitude != transmitter.longitude))
        {
            cameraInfo.latitude = transmitter.latitude;
            cameraInfo.longitude = transmitter.longitude;
            hasChanged = YES;
        }
    }
    else if ([sourceObject isKindOfClass:[FavoriteEntry class]])
    {
        FavoriteEntry * favorite = sourceObject;
		NSData * xml = [favorite.openCommand.parameter dataUsingEncoding:NSUnicodeStringEncoding 
													allowLossyConversion:YES];
		cameraInfo = [self parseCameraInfoXml:xml];
    }
    else if ([sourceObject isKindOfClass:[CameraInfo class]])
    {
        CameraInfo * camera = newCameraInfo.sourceObject;
        hasChanged = ((cameraInfo.latitude != camera.latitude) || 
                      (cameraInfo.longitude != camera.longitude) || 
                      (cameraInfo.hasHeartbeat != camera.hasHeartbeat));
		cameraInfo = camera;
    }
    else 
    {
        NSAssert(NO,@"Unknown source type for CameraInfoWrapper");
    }
    
	[self updateLocation];
	
	return hasChanged;
}

- (NSString *)name 
{
	if ([sourceObject isKindOfClass:[Session class]])
	{
		Session * session = sourceObject;
		return [NSDateFormatter localizedStringFromDate:session.startTime 
											  dateStyle:NSDateFormatterMediumStyle    
											  timeStyle:NSDateFormatterMediumStyle];
	}
	
	return cameraInfo.caption;
}

- (NSString *)description
{
	if ([sourceObject isKindOfClass:[TransmitterInfo class]])
	{
		// user feeds show start time for description
		TransmitterInfo * transmitter = sourceObject;
		return [NSDateFormatter localizedStringFromDate:transmitter.startTime 
											  dateStyle:NSDateFormatterMediumStyle    
											  timeStyle:NSDateFormatterMediumStyle];
	}
	
	if ([sourceObject isKindOfClass:[Session class]])
	{
		// video history shows first session comment as description
        Session * session = sourceObject;
        
        if ((session.comments == nil) || ([session.comments count] < 1))
        {
            return @"";
        }
        
        Comment * comment = [session.comments objectAtIndex:0];
        return comment.comments;
	}
	
	if ((self.isScreencast) || ([sourceObject isKindOfClass:[FavoriteEntry class]] && self.isVideoServerFeed))
	{
		// screencasts and favorited archive feeds show start time for description
		return (cameraInfo.startTime == nil) ? @""
		                                     : [NSDateFormatter localizedStringFromDate:cameraInfo.startTime 
																			  dateStyle:NSDateFormatterMediumStyle    
																			  timeStyle:NSDateFormatterMediumStyle];
	}
	
	return cameraInfo.description;
}

- (NSString *)categories
{
	NSMutableString * categoriesString = [NSMutableString stringWithCapacity:100];
	
	if (! NSStringIsNilOrEmpty(cameraInfo.country))
	{
		[categoriesString appendString:cameraInfo.country];
	}
	
	if (! NSStringIsNilOrEmpty(cameraInfo.province))
	{
		[categoriesString appendFormat:@", %@",cameraInfo.province];
	}
	
	if (! NSStringIsNilOrEmpty(cameraInfo.city))
	{
		[categoriesString appendFormat:@", %@",cameraInfo.city];
	}
	
	return categoriesString;
}

- (CameraInfoWrapper *)camera
{
    return self;
}

- (BOOL)isVideoFile
{
	return (cameraInfo.cameraType & TYPE_VIDEOFILE) == TYPE_VIDEOFILE;
}

- (BOOL)isSecure
{
	return (cameraInfo.cameraType & TYPE_HTTPS) == TYPE_HTTPS;
}

- (BOOL)isRtsp
{
	return (cameraInfo.cameraType & TYPE_RTSP) == TYPE_RTSP;
}

- (BOOL)isProxyFeed
{
	return (cameraInfo.cameraType & TYPE_PROXIED) == TYPE_PROXIED;
}

- (BOOL)isVideoServerFeed
{
	return (cameraInfo.cameraType & TYPE_VIDEOSERVER) == TYPE_VIDEOSERVER;
}

- (BOOL)isVideoServerPlugin
{
	return (cameraInfo.cameraType & TYPE_VIDEOSERVER_PLUGIN) == TYPE_VIDEOSERVER_PLUGIN;
}

- (BOOL)isScreencast
{
	return (cameraInfo.cameraType & TYPE_SCREENCAST) == TYPE_SCREENCAST;
}

- (BOOL)isDirect
{
	return (cameraInfo.cameraType & TYPE_NOT_DIRECT) == 0;
}

- (BOOL)isTransmitter
{
	return [self.sourceObject isKindOfClass:[TransmitterInfo class]];
}

- (BOOL)isFavoriteEntry
{
	return [self.sourceObject isKindOfClass:[FavoriteEntry class]];
}

- (BOOL)isArchivedSession
{
	return [self.sourceObject isKindOfClass:[Session class]];
}

- (BOOL)isLiveFeed
{
	return ! self.isArchiveFeed;
}

- (BOOL)isArchiveFeed
{
    if ([self.sourceObject isKindOfClass:[Session class]])
        return YES;
    
    if ([self.sourceObject isKindOfClass:[CameraInfo class]] || 
        [self.sourceObject isKindOfClass:[FavoriteEntry class]])
    {
        NSRange pos = [self.cameraInfo.uri rangeOfString:[NSString stringWithFormat:@"%@=",ARCHIVE_START_TIME]];
        return (pos.location != NSNotFound);
    }
    
    return NO;
}

- (BOOL)canBeFavorite
{
    // currently only fixed cameras can be favorited
    return (cameraInfo.cameraType & TYPE_NOT_FIXED_CAMERA) == 0;
}

- (BOOL)isAvailable
{
    // video server feeds are always available; direct feeds are available if they have a heartbeat
	return (! self.isDirect) || (cameraInfo.hasHeartbeat);
}

- (BOOL)isPanTiltZoom
{
	return ! NSStringIsNilOrEmpty(cameraInfo.controlStub);
}

- (BOOL)hasStartTime
{
	return self.cameraInfo.startTime != nil;
}

- (NSTimeInterval)length
{
	NSTimeInterval length = -1;
	
	if ([self.sourceObject isKindOfClass:[Session class]])
	{
		Session * session = self.sourceObject;
		if (session.stopTime != nil)
		{
			length = [session.stopTime timeIntervalSinceDate:session.startTime];
		}
	}
	
	return length;
}

- (NSInteger)numberOfComments
{
	NSInteger comments = 0;
	
	if ([self.sourceObject isKindOfClass:[Session class]])
	{
		Session * session = self.sourceObject;
		if (session.comments != nil)
		{
			comments = [session.comments count];
		}
	}
	
	return comments;
}

- (UIImage *)thumbnail
{
	return cameraInfo.thumbnail;
}

- (NSURL *)sourceUrl
{
	if (sourceUrl == nil)
	{
		SystemUris * systemUris  = [ConfigurationManager instance].systemUris;
		NSString   * relativeUrl = [NSString stringWithString:cameraInfo.uri];
		
		if ([relativeUrl characterAtIndex:0] == '/')
		{
			relativeUrl = [relativeUrl substringFromIndex:1];
		}
		
		if (self.isScreencast)
		{
			// url encode the screencast id ... which is more complicated than it should be because 
			// if it's a screencast archive it may have a starttime parameter
			NSMutableArray * queryParameters = [QueryString getParametersFromQuery:relativeUrl];
			NSString * screencastId = [queryParameters objectAtIndex:0];
			[queryParameters replaceObjectAtIndex:0 withObject:[QueryString urlEncodeString:screencastId]];
			
			QueryString * queryString = [[QueryString alloc] initWithParameters:queryParameters];
			relativeUrl = queryString.query;
		}
		
		if (self.isVideoServerFeed || self.isScreencast) 
		{
			if ([relativeUrl hasPrefix:VIDEO_JPG_DEVICE])
			{
				relativeUrl = [relativeUrl stringByReplacingOccurrencesOfString:VIDEO_JPG_DEVICE withString:@""];
			}
			
			// if camera feed is an archive of a user feed (not a screencast), add parameter to include session data
			if (! self.isScreencast)
			{
				NSRange pos = [relativeUrl rangeOfString:[NSString stringWithFormat:@"%@=",ARCHIVE_START_TIME]];
				if (pos.location != NSNotFound)
				{
					relativeUrl = [relativeUrl stringByAppendingString:[NSString stringWithFormat:@"&%@=%@",INCLUDE_SESSION,@"true"]];
				}
			}
			
			sourceUrl = [[NSURL alloc] initWithString:relativeUrl relativeToURL:systemUris.videoStreamingBase];
		} 
		else if (self.isVideoServerPlugin)
		{
			sourceUrl = [[NSURL alloc] initWithString:relativeUrl relativeToURL:systemUris.videoSourceBase];
		}
		else 
		{
			NSString * scheme;
			if (self.isSecure)
			{
				scheme = @"https";
			}
			else if (self.isRtsp)
			{
				scheme = @"rtsp";
			}
			else if (self.isVideoFile)
			{
				scheme = @"file";
			}
			else 
			{
				scheme = @"http";
			}
			
			NSString * urlString = (self.isVideoFile) ? [NSString stringWithFormat:@"%@:///%@", scheme, relativeUrl]
			                                          : [NSString stringWithFormat:@"%@://%@:%lld/%@", scheme, cameraInfo.server, cameraInfo.port, relativeUrl];
			
			if (self.isProxyFeed)
			{
				urlString = [[systemUris.videoProxyViewerBase absoluteString] stringByAppendingString:[QueryString urlEncodeString:urlString]];
			}
			
			sourceUrl = [[NSURL alloc] initWithString:urlString];
		}
	}
	
	return sourceUrl;
}

- (NSURL *)urlForStartTime:(NSDate *)startTime
{
	NSURL * url = nil;
	
	if ((self.isVideoServerFeed && (! self.isProxyFeed)) || self.isScreencast)
	{
        BOOL hasIncludeSession = NO;
		BOOL replacedStartTime = NO;
		NSMutableArray * queryParameters = [QueryString getParametersFromQuery:[[self sourceUrl] absoluteString]];
		
		for (NSUInteger index = 1; index < [queryParameters count]; index++) 
		{
			NSString * nameValuePair = [queryParameters objectAtIndex:index];
			NSRange pos = [nameValuePair rangeOfString:@"="];
			
			NSString * name = (pos.location == NSNotFound) ? nameValuePair : [nameValuePair substringToIndex:pos.location];
			
			if ([name isEqualToString:ARCHIVE_START_TIME])
			{
				NSString * newStartTime = [NSString stringWithFormat:@"%@=%@", 
										                             ARCHIVE_START_TIME, 
										                             [XmlFactory formatDate:startTime]];
				
				[queryParameters removeObjectAtIndex:index];
				[queryParameters insertObject:newStartTime atIndex:index];
				replacedStartTime = YES;
			}
            
            if ([name isEqualToString:INCLUDE_SESSION])
            {
                hasIncludeSession = YES;
            }
		}
		
		QueryString * newQuery = [[QueryString alloc] initWithParameters:queryParameters];
		
		if (! replacedStartTime)
		{
			NSString * newStartTime = [XmlFactory formatDate:startTime];
			[newQuery append:ARCHIVE_START_TIME stringValue:newStartTime];
		}
        
        if ((! self.isScreencast) && (! hasIncludeSession))
        {
            [newQuery append:INCLUDE_SESSION stringValue:@"true"];
        }
		
        NSString * urlString = newQuery.query;
 		url = [NSURL URLWithString:urlString];
	}
	
	return url;
}

- (NSURL *)urlForLiveFeed
{
	NSURL * url = nil;
	
    if (self.isLiveFeed)
    {
        return self.sourceUrl;
    }
    
	if ((self.isVideoServerFeed && (! self.isProxyFeed)) || self.isScreencast)
	{
        NSInteger startTimeIndex = -1;
		NSInteger stopTimeIndex = -1;
		NSMutableArray * queryParameters = [QueryString getParametersFromQuery:[[self sourceUrl] absoluteString]];
		
		for (NSUInteger index = 1; index < [queryParameters count]; index++) 
		{
			NSString * nameValuePair = [queryParameters objectAtIndex:index];
			NSRange pos = [nameValuePair rangeOfString:@"="];
			
			NSString * name = (pos.location == NSNotFound) ? nameValuePair : [nameValuePair substringToIndex:pos.location];
			
			if ([name isEqualToString:ARCHIVE_START_TIME])
			{
                startTimeIndex = index;
			}
            
            if ([name isEqualToString:ARCHIVE_STOP_TIME])
            {
                stopTimeIndex = index;
            }
		}
		
        // see if query has a start time but no stop time
        if (startTimeIndex > 0 && stopTimeIndex == -1)
        {
            // remove start time and build new query without it
            [queryParameters removeObjectAtIndex:startTimeIndex];
            QueryString * newQuery = [[QueryString alloc] initWithParameters:queryParameters];
            url = [NSURL URLWithString:newQuery.query];
        }
	}
	
	return url;
}

- (Command *)viewCameraCommandForFavorite
{
	if (viewCameraCommandForFavorite == nil)
	{
		CameraInfo * newCameraInfo = cameraInfo;
		
		if (self.isTransmitter)
		{
			// live feeds get favorited as archive feeds
			newCameraInfo = [[CameraInfo alloc] init];
			
			newCameraInfo.caption = cameraInfo.description;
			newCameraInfo.description = [NSDateFormatter localizedStringFromDate:cameraInfo.startTime 
																	dateStyle:NSDateFormatterMediumStyle    
																	timeStyle:NSDateFormatterMediumStyle];
			
			newCameraInfo.cameraType = TYPE_VIDEOSERVER;
			newCameraInfo.startTime = cameraInfo.startTime;
			newCameraInfo.server = cameraInfo.server;
			newCameraInfo.port = cameraInfo.port;
			newCameraInfo.thumbnail = cameraInfo.thumbnail;
			
			TransmitterInfo * transmitter = sourceObject;
			newCameraInfo.uri = [NSString stringWithFormat:@"%@?%@=%@",transmitter.deviceId,ARCHIVE_START_TIME,[XmlFactory formatDate:cameraInfo.startTime]];
		}
		else if (self.isScreencast && self.hasStartTime)
		{
			// archived screencasts get favorited as archive feeds
			newCameraInfo.uri = [NSString stringWithFormat:@"%@?%@=%@",newCameraInfo.uri,ARCHIVE_START_TIME,[XmlFactory formatDate:cameraInfo.startTime]];
		}
		
		NSData * xmlDocument = [XmlFactory dataWithCameraInfoElement:newCameraInfo];
		NSString * xmlString = [[NSString alloc] initWithData:xmlDocument encoding:NSUnicodeStringEncoding];
		
		viewCameraCommandForFavorite           = [[Command alloc] init];
		viewCameraCommandForFavorite.commandId = @"00000000-0000-0000-0000-000000000000";
		viewCameraCommandForFavorite.directive = [[DirectiveType alloc] initWithValue:DT_ViewCameraInfo];
		viewCameraCommandForFavorite.parameter = xmlString;
		viewCameraCommandForFavorite.eventTime = [NSDate date];
		viewCameraCommandForFavorite.retrieved = YES;
	}
	
	return viewCameraCommandForFavorite;
}

- (NSURL *)panTiltZoomUrl:(PanTiltZoom)command 
{
	NSString * ptzFragment = nil;
	
	switch(command)
	{
		case PTZ_LEFT:
			ptzFragment = cameraInfo.controlLeft;
			break;
			
		case PTZ_RIGHT:
			ptzFragment = cameraInfo.controlRight;
			break;
			
		case PTZ_UP:
			ptzFragment = cameraInfo.controlUp;
			break;
			
		case PTZ_DOWN:
			ptzFragment = cameraInfo.controlDown;
			break;
			
		case PTZ_ZOOM_IN:
			ptzFragment = cameraInfo.controlZoomIn;
			break;
			
		case PTZ_ZOOM_OUT:
			ptzFragment = cameraInfo.controlZoomOut;
			break;
			
		case PTZ_HOME:
			ptzFragment = cameraInfo.controlHome;
			break;
			
		default: 
			ptzFragment = nil;
			break;
	}
	
	NSString * qualifiedUrl = nil;
	NSString * controlStub  = cameraInfo.controlStub;
	
	if ((! NSStringIsNilOrEmpty(controlStub)) && 
		(! NSStringIsNilOrEmpty(ptzFragment)))
	{
		if (self.isVideoServerPlugin)
		{
			qualifiedUrl = [NSString stringWithFormat:@"%@%@%@", 
							                          [[ConfigurationManager instance].systemUris.videoSourceBase absoluteString], 
							                          controlStub, 
							                          ptzFragment];
		}
		else
		{
			NSString * scheme = self.isSecure ? @"https" : @"http";
			NSString * endPtz = [NSString stringWithFormat:@"%@://%@:%lld%@%@", 
								 scheme, 
								 cameraInfo.server, 
								 cameraInfo.port, 
								 controlStub, 
								 ptzFragment];
			
			if (self.isProxyFeed)
			{
				NSString * ptzBase = [[ConfigurationManager instance].systemUris.videoProxyPtzBase absoluteString]; 
				qualifiedUrl = [ptzBase stringByAppendingString:[QueryString urlEncodeString:endPtz]];
			}
			else 
			{
				qualifiedUrl = endPtz;
			}
		}
	}
	
	return (qualifiedUrl == nil) ? nil : [NSURL URLWithString:qualifiedUrl];
}

- (UIImage *)statusImage
{
	if (! self.isAvailable)
	{
		return [UIImage imageNamed:@"ic_list_inactive"];
	} 
	
	if (self.isPanTiltZoom)
	{
		return [UIImage imageNamed:@"ic_list_directional"];
	}
	
	return nil;
}


#pragma mark - Sort operators

- (NSComparisonResult)compare:(CameraInfoWrapper *)camera
{
	return [self.name localizedCaseInsensitiveCompare:camera.name];
}

- (NSComparisonResult)compareNameAndStartTime:(CameraInfoWrapper *)camera
{
	NSComparisonResult result = [self.name localizedCaseInsensitiveCompare:camera.name];
	return (result != NSOrderedSame) ? result : [self compareStartTime:camera];
}

- (NSComparisonResult)compareStartTime:(CameraInfoWrapper *)camera
{
	// put nil start times after non-nil start times
	if (self.cameraInfo.startTime == nil)
	{
		return (camera.cameraInfo.startTime == nil) ? NSOrderedSame : NSOrderedDescending;
	}
	
	if (camera.cameraInfo.startTime == nil)
	{
		return NSOrderedAscending;
	}

	return [self.cameraInfo.startTime compare:camera.cameraInfo.startTime];
}

- (NSString *)cameraType
{
	if (self.isVideoFile)
	{
		return @"Video File";
	}
	
	if (self.isScreencast)
	{
		return @"Screencast";
	}
	
	if ([sourceObject isKindOfClass:[Session class]] ||
		([sourceObject isKindOfClass:[FavoriteEntry class]] && self.isVideoServerFeed))
	{
		return @"Video History";
	}
		  
	if (self.isVideoServerFeed)
	{
		return @"User Feed";
	}
	
	return @"Camera";
}


#pragma mark - MKAnnotation methods

- (NSString *)title
{
	return self.name;
}

- (NSString *)subtitle
{
	return self.description;
}


#pragma mark - Equality overrides

- (BOOL)isEqualToCameraInfoWrapper:(CameraInfoWrapper *)camera 
{
	return [self.sourceObject isEqual:camera.sourceObject];
}

- (BOOL)isEqual:(id)other 
{
    if (other == self)
        return YES;

    if ((other == nil) || (! [other isKindOfClass:[self class]]))
        return NO;
    
	return [self isEqualToCameraInfoWrapper:other];
}

// hash algorithm from http://stackoverflow.com/questions/254281/best-practices-for-overriding-isequal-and-hash
- (NSUInteger)hash 
{
	return [self.sourceObject hash];
}


#pragma mark - Private methods

- (void)updateLocation
{
    hasLocation = (cameraInfo.latitude  != RVLocationCoordinate2DInvalid.latitude) && 
                  (cameraInfo.longitude != RVLocationCoordinate2DInvalid.longitude);
    
    // only update the coordinate if we have a valid location (see BUG-3424)
    if (hasLocation)
    {
        self.coordinate = CLLocationCoordinate2DMake(cameraInfo.latitude, cameraInfo.longitude);
    }
    
    self.animatesDropOnMap = NO;
}

- (CameraInfo *)parseCameraInfoXml:(NSData *)xml
{
	CameraInfoHandler * cameraInfoHandler = [[CameraInfoHandler alloc] init];
	NSXMLParser * parser = [[NSXMLParser alloc] initWithData:xml];
    [parser setDelegate:cameraInfoHandler];
    [parser setShouldResolveExternalEntities:YES];
    
	BOOL success = [parser parse];
	CameraInfo * result = (success) ? cameraInfoHandler.result : nil;
	
	return result;
}

- (NSString *)uriForSession:(Session *)session
{
	NSMutableString * uri = [NSMutableString stringWithFormat:@"%@?%@=%@",session.deviceId,ARCHIVE_START_TIME,[XmlFactory formatDate:session.startTime]];
	
	if (session.stopTime != nil)
	{
		[uri appendFormat:@"&%@=%@",ARCHIVE_STOP_TIME,[XmlFactory formatDate:session.stopTime]];
	}
	
	return uri;
}

- (BOOL)isTransmitterForUserDevice:(UserDevice*)userDevice
{
	return [self isTransmitter] && [((TransmitterInfo*)self.sourceObject).deviceId isEqualToString:userDevice.device.deviceId];
}


@end
