//
//  DownloadManager.m
//  RealityVision
//
//  Created by Thomas Aylesworth on 8/16/10.
//  Copyright 2010 Reality Mobile LLC. All rights reserved.
//

#import "DownloadManager.h"
#import "AuthenticationHandler.h"
#import "RealityVisionAppDelegate.h"
#import "RvError.h"
#import "DDLog.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation DownloadManager
{
	NSURLConnection       * connection;
	AuthenticationHandler * authenticationHandler;
	id                      fileHandle;
	NSUInteger              bytesReceived;
}

@synthesize url;
@synthesize delegate;
@synthesize mimeType;
@synthesize filePath;
@synthesize responseError;
@synthesize contentLength;
@synthesize isComplete;


#pragma mark - Initialization and cleanup

- (id)initWithUrl:(NSURL *)downloadUrl andDelegate:(id <DownloadDelegate>)downloadDelegate
{
	self = [super init];
	if (self != nil)
	{
		url = downloadUrl;
		delegate = downloadDelegate;
		authenticationHandler = [[AuthenticationHandler alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[self cancel];
    [self deleteDownloadedFile];
}


#pragma mark - Public methods

- (BOOL)startDownload:(NSError **)error
{
	NSAssert(connection==nil,@"Can't start a new download until the previous one finishes");
	DDLogInfo(@"DownloadManager startDownload");
	
	filePath = nil;
	mimeType = nil;
	responseError = nil;
	contentLength = 0;
	bytesReceived = 0;
	isComplete = NO;
	
	return [self createDownloadFile:error] && [self startHttpRequest:error];
}

- (void)cancel
{
	if (! self.isComplete)
	{
		DDLogInfo(@"DownloadManager cancel");
		[connection cancel];
		
		fileHandle = nil;
		connection = nil;
		isComplete = YES;
		
		[RealityVisionAppDelegate didStopNetworking];
	}
}

- (float)progress
{
	return (float)bytesReceived / (float)contentLength;
}

+ (void)deleteDownloadedFiles
{
	DDLogInfo(@"DownloadManager deleteDownloadedFiles");
	
	NSError * error = nil;
    NSFileManager * fileManager = [NSFileManager defaultManager];
	NSString * path = [self downloadsDirectory];
	
	if (([fileManager fileExistsAtPath:path isDirectory:NULL]) && 
	    (! [fileManager removeItemAtPath:path error:&error]))
	{
		DDLogError(@"Unable to delete downloads directory: %@", error);
	}
}


#pragma mark - Private methods

+ (NSString *)downloadsDirectory
{
    return [[RealityVisionAppDelegate documentDirectory] stringByAppendingPathComponent:@"downloads"];
}

- (BOOL)createBaseDirectory:(NSString *)path fileManager:(NSFileManager *)fileManager error:(NSError **)error
{
	BOOL isDirectory;
	BOOL exists = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
	
	if (! exists)
	{
		exists = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:error];
	}
	
	return exists;
}

- (BOOL)createDownloadFile:(NSError **)error
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
	NSString * path = [DownloadManager downloadsDirectory];
	
	if (! [self createBaseDirectory:path fileManager:fileManager error:error]) 
	{
		return NO;
	}
	
	filePath = [path stringByAppendingPathComponent:[self.url lastPathComponent]];
	if (! [fileManager createFileAtPath:filePath contents:nil attributes:nil])
	{
		if (error != nil)
		{
			*error = [RvError rvErrorWithLocalizedDescription:@"Unable to create file"];
		}
		return NO;
	}
	
	fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
	return fileHandle != nil;
}

- (void)deleteDownloadedFile
{
    NSError * error = nil;
    if (! [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:&error])
    {
		DDLogError(@"Unable to delete downloaded file: %@", error);
    }
}

- (BOOL)startHttpRequest:(NSError **)error
{
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:self.url 
																 cachePolicy:NSURLRequestUseProtocolCachePolicy 
															 timeoutInterval:60];
	if (request == nil)
	{
		if (error != NULL)
		{ 
			*error = [RvError rvErrorWithLocalizedDescription:@"Unable to create HTTP request"];
		}
		
		return NO;
	}
	
	// create connection to send request and manage response
	connection = [NSURLConnection connectionWithRequest:request delegate:self];
	if (connection == nil)
	{
		if (error != NULL)
		{
			*error = [RvError rvErrorWithLocalizedDescription:@"Unable to create URL connection"];
		}
		
		return NO;
	}
	
	[RealityVisionAppDelegate didStartNetworking];
	
	return YES;
}


#pragma mark - NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
     NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode != 200)
	{
		responseError = [RvError rvErrorWithHttpStatus:httpResponse.statusCode message:nil];
		return;
    }
	
	NSDictionary * headers = [httpResponse allHeaderFields];
	mimeType = [headers objectForKey:@"Content-Type"];
	NSNumber * length = [headers objectForKey:@"Content-Length"];
	contentLength = length ? [length intValue] : 0;
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	if ([data length] > 0)
	{
		[fileHandle writeData:data];
		bytesReceived += [data length];
		
		if (contentLength > 0)
		{
			[self.delegate downloadProgress:self.progress];
		}
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
    DDLogVerbose(@"DownloadManager didFinishLoading");
	[self connectionIsComplete];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
	DDLogError(@"DownloadManager didFailWithError: %@", error);
	responseError = authenticationHandler.authenticationError ? authenticationHandler.authenticationError : error;
	[self connectionIsComplete];
}

- (void)connectionIsComplete
{
	// deallocating the handle also closes the file
	fileHandle = nil;
	connection = nil;
	isComplete = YES;
	[RealityVisionAppDelegate didStopNetworking];
	[authenticationHandler connectionIsComplete:connection];
	[self.delegate didFinishDownloadingFile:self.filePath ofType:self.mimeType error:self.responseError];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)conn
{
	return [authenticationHandler connectionShouldUseCredentialStorage:conn];
}

- (BOOL)connection:(NSURLConnection *)conn canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
	return [authenticationHandler connection:conn canAuthenticateAgainstProtectionSpace:protectionSpace];
}

- (void)connection:(NSURLConnection *)conn didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	return [authenticationHandler connection:conn didReceiveAuthenticationChallenge:challenge];
}

@end
