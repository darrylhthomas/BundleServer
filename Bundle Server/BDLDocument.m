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
#import "BDLFileSystemNode.h"
#import "BDLFileSystemNodeCell.h"

@implementation BDLDocument
{
    HTTPServer *_server;
    BDLFileSystemNode *_rootNode;
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

- (void)awakeFromNib
{
    [self.browser setCellClass:[BDLFileSystemNodeCell class]];
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
    return NO;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    _rootNode = [[BDLFileSystemNode alloc] initWithFileURL:url];
    [_server setDocumentRoot:[url path]];
    
    [self.browser loadColumnZero];
    
    return (_rootNode != nil);
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    return nil;
}

#pragma mark - NSBrowserDelegate

- (id)browser:(NSBrowser *)browser child:(NSInteger)index ofItem:(id)item
{
    BDLFileSystemNode *node = (BDLFileSystemNode *)item;
    
    return node.children[index];
}

- (id)browser:(NSBrowser *)browser objectValueForItem:(id)item
{
    BDLFileSystemNode *node = (BDLFileSystemNode *)item;
    
    return node.displayName;
}

- (NSInteger)browser:(NSBrowser *)browser numberOfChildrenOfItem:(id)item
{
    BDLFileSystemNode *node = (BDLFileSystemNode *)item;
    
    return [node.children count];
}

- (BOOL)browser:(NSBrowser *)browser isLeafItem:(id)item
{
    BDLFileSystemNode *node = (BDLFileSystemNode *)item;
    
    return !(node.isDirectory);
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(BDLFileSystemNodeCell *)cell atRow:(NSInteger)row column:(NSInteger)column
{
    NSIndexPath *indexPath = [sender indexPathForColumn:column];
    indexPath = [indexPath indexPathByAddingIndex:row];
    
    BDLFileSystemNode *node = [sender itemAtIndexPath:indexPath];
    cell.image = node.icon;
}

- (id)rootItemForBrowser:(NSBrowser *)browser
{
    return _rootNode;
}

- (CGFloat)browser:(NSBrowser *)browser shouldSizeColumn:(NSInteger)columnIndex forUserResize:(BOOL)forUserResize toWidth:(CGFloat)suggestedWidth
{
    if (!forUserResize) {
        id item = [browser parentForItemsInColumn:columnIndex];
        if ([self browser:browser isLeafItem:item]) {
            suggestedWidth = 200.0f;
        }
    }
    
    return suggestedWidth;
}

@end
