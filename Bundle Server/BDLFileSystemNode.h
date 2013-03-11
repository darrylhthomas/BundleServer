//
//  BDLFileSystemNode.h
//  Bundle Server
//
//  Created by Darryl H. Thomas on 3/10/13.
//

#import <Foundation/Foundation.h>

@interface BDLFileSystemNode : NSObject

@property (strong, readonly) NSURL *url;
@property (copy, readonly) NSString *displayName;
@property (strong, readonly) NSImage *icon;
@property (copy, readonly) NSArray *children;
@property (assign, readonly) BOOL isDirectory;

- (id)initWithFileURL:(NSURL *)fileURL;
- (void)invalidateChildren;
- (NSDictionary *)dictionaryRepresentation;
- (NSDictionary *)dictionaryRepresentationWithBaseURL:(NSURL *)baseURL;
- (BDLFileSystemNode *)nodeAtRelativePath:(NSString *)nodePath;
- (BDLFileSystemNode *)childWithFilename:(NSString *)childName;

@end
