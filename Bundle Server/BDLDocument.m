//
//  BDLDocument.m
//  Bundle Server
//
//  Created by Darryl H. Thomas on 3/9/13.
//  Copyright (c) 2013 Darryl H. Thomas. All rights reserved.
//

#import "BDLDocument.h"
#import "HTTPServer.h"
#import "BDLBundleConnection.h"

@implementation BDLDocument
{
    HTTPServer *_server;
    NSURL *_rootURL;
}

- (id)init
{
    self = [super init];
    if (self) {
        _server = [[HTTPServer alloc] init];
        [_server setConnectionClass:[BDLBundleConnection class]];
        [_server setType:@"_http._tcp."];
        
        NSError *error = nil;
        if (![_server start:&error]) {
            NSLog(@"Error starting bundle server: %@", [error localizedDescription]);
            return nil;
        }
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"BDLDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    _rootURL = url;
    [_server setDocumentRoot:[_rootURL path]];
    
    return YES;
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return [[NSFileWrapper alloc] initWithURL:_rootURL options:0 error:outError];
}

@end
