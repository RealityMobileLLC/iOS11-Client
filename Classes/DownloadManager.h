//
//  DownloadManager.h
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  Delegate used by the DownloadManager to provide status for a download.
 */
@protocol DownloadDelegate

/**
 *  Called to indicate current download progress.
 * 
 *  @param progress percent complete between 0.0 and 1.0
 */
- (void)downloadProgress:(float)progress;

/**
 *  Called when the download task is done, either having successfully 
 *  downloaded and saved the file or exited with an error.
 *
 *  @param filename Name of downloaded file.
 *  @param mimeType MIME type of downloaded file.
 *  @param error    An error that occured while trying to download the file,
 *                  or nil if download was successful.
 */
- (void)didFinishDownloadingFile:(NSString *)filename ofType:(NSString *)mimeType error:(NSError *)error;

@end


/**
 *  Manages the asynchronous download of a file.
 */
@interface DownloadManager : NSObject 

/**
 *  The URL of the file to download.
 */
@property (strong, nonatomic) NSURL * url;

/**
 *  Delegate to notify with status updates.
 */
@property (nonatomic,weak) id <DownloadDelegate> delegate;

/**
 *  Path of the downloaded file on the client.
 */
@property (strong, nonatomic,readonly) NSString * filePath;

/**
 *  MIME type of the downloaded file.
 */
@property (strong, nonatomic,readonly) NSString * mimeType;

/**
 *  Error received in HTTP response, or nil if no error occurred.
 */
@property (strong, nonatomic,readonly) NSError * responseError;

/**
 *  Length of file in bytes.
 */
@property (nonatomic,readonly) NSUInteger contentLength;

/**
 *  A value from 0.0 to 1.0 indicating download progress.
 */
@property (nonatomic,readonly) float progress;

/**
 *  Indicates whether download has completed.
 */
@property (nonatomic,readonly) BOOL isComplete;

/**
 *  Initializes a new DownloadManager object.
 *
 *  @param downloadUrl URL of the file to download.
 *  @param delegate    Delegate to notify with status updates.
 *
 *  returns DownloadManager object or nil if object could not be initialized
 */
- (id)initWithUrl:(NSURL *)downloadUrl andDelegate:(id <DownloadDelegate>)delegate;

/**
 *  Starts the asynchronous download process.
 *
 *  @param error A pointer to a NSError object to use if an error occurs while
 *               trying to start the download.
 *
 *  @return YES if download started successfully or NO if an error occurred.
 */
- (BOOL)startDownload:(NSError **)error;

/**
 *  Cancels an existing download.
 */
- (void)cancel;

/**
 *  Deletes all downloaded files.
 */
+ (void)deleteDownloadedFiles;

@end
