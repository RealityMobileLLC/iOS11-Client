//
//  BrowseCameraCategory.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 11/14/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//


/**
 *  The categories of cameras that can be displayed in a BrowseViewController.
 *
 *  @todo consider getting rid of this and relying entirely on CameraDataSource
 */
typedef enum
{
	BC_Favorites,
	BC_Transmitters,
	BC_Cameras,
	BC_Screencasts,
	BC_Files,
	BC_MyVideos
} BrowseCameraCategory;
