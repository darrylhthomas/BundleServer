//
//  BDLBundleConnection.m
//  Bundle Server
//
//  Created by Darryl H. Thomas on 3/9/13.
//  Copyright (c) 2013 Darryl H. Thomas. All rights reserved.
//

#import "BDLBundleConnection.h"
#import "HTTPServer.h"
#import "HTTPDataResponse.h"
#import "HTTPAsyncFileResponse.h"
#import "BDLFileSystemNode.h"

@implementation BDLBundleConnection
{
    BDLFileSystemNode *_rootNode;
    FSEventStreamRef _eventStreamRef;
}

void bdlbundleconnection_fsevents_callback(ConstFSEventStreamRef streamRef, void *userData, size_t eventCount, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[])
{
    BDLBundleConnection *connection = (__bridge BDLBundleConnection *)userData;

    [connection->_rootNode invalidateChildren];
}

- (void)dealloc
{
    [self teardownFSEventStream];
}

- (BDLFileSystemNode *)rootNode
{
    if (_rootNode == nil) {
        NSString *path = [config documentRoot];
        _rootNode = [[BDLFileSystemNode alloc] initWithFileURL:[NSURL fileURLWithPath:path]];
        [self setupFSEventStreamForPaths:@[path]];
    }
    
    return _rootNode;
}

- (void)setupFSEventStreamForPaths:(NSArray *)paths
{
    [self teardownFSEventStream];
    
    void *selfPointer = (__bridge void *)self;
    FSEventStreamContext context = {0, selfPointer, NULL, NULL, NULL};
    CFAbsoluteTime latency = 0.1;
    
    _eventStreamRef = FSEventStreamCreate(NULL, &bdlbundleconnection_fsevents_callback, &context, (__bridge CFArrayRef)paths, 0, latency, kFSEventStreamCreateFlagUseCFTypes);
    
    FSEventStreamScheduleWithRunLoop(_eventStreamRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(_eventStreamRef);
}

- (void)teardownFSEventStream
{
    if (_eventStreamRef == NULL)
        return;
    
    FSEventStreamStop(_eventStreamRef);
    FSEventStreamInvalidate(_eventStreamRef);
    _eventStreamRef = NULL;
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    NSString *filePath = [self filePathForURI:path allowDirectory:YES];
    BOOL isDirectory = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
    
    if (exists) {
        if (isDirectory) {
        BDLFileSystemNode *node = [[self rootNode] nodeAtRelativePath:path];
        if (!node) {
            return nil;
        }
        
        NSString *scheme = [self isSecureServer] ? @"https" : @"http";
        HTTPServer *server = [config server];
        NSString *host = [NSString stringWithFormat:@"%@.%@:%u", [server publishedName], [server domain], (unsigned int)[server listeningPort]];
        NSString *urlString = [NSString stringWithFormat:@"%@://%@%@", scheme, host, path];
        NSURL *baseURL = [[NSURL alloc] initWithString:urlString];
        
        NSDictionary *indexDictionary = [node dictionaryRepresentationWithBaseURL:baseURL];
        if (!indexDictionary) {
            return nil;
        }
        NSError *error = nil;
        NSData *indexData = [NSJSONSerialization dataWithJSONObject:indexDictionary options:NSJSONWritingPrettyPrinted error:&error];
        
        return [[HTTPDataResponse alloc] initWithData:indexData];
        } else {
            return [[HTTPAsyncFileResponse alloc] initWithFilePath:filePath forConnection:self];
        }
    }

    return nil;
}

@end
