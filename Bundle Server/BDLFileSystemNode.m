//
//  BDLFileSystemNode.m
//  Bundle Server
//
//  Created by Darryl H. Thomas on 3/10/13.
//

#import "BDLFileSystemNode.h"

@implementation BDLFileSystemNode
{
    NSArray *_children;
    BOOL _childrenAreDirty;
}

@dynamic displayName;
@dynamic children;
@dynamic isDirectory;
@dynamic icon;

- (id)initWithFileURL:(NSURL *)fileURL
{
    NSParameterAssert([fileURL isFileURL]);
    
    self = [super init];
    if (self) {
        _url = fileURL;
    }
    
    return self;
}

- (NSString *)displayName
{
    id value = nil;
    NSError *error = nil;
    NSString *result = nil;
    
    if ([self.url getResourceValue:&value forKey:NSURLLocalizedNameKey error:&error]) {
        result = value;
    } else {
        result = [error localizedDescription];
    }
    
    return result;
}

- (NSImage *)icon
{
    return [[NSWorkspace sharedWorkspace] iconForFile:[self.url path]];
}

- (BOOL)isDirectory
{
    id value = nil;
    BOOL result = NO;
    
    if ([self.url getResourceValue:&value forKey:NSURLIsDirectoryKey error:NULL]) {
        result = [value boolValue];
    }
    
    return result;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[BDLFileSystemNode class]]) {
        BDLFileSystemNode *other = (BDLFileSystemNode *)object;
        
        return [other.url isEqual:self.url];
    }
    
    return NO;
}

- (NSUInteger)hash
{
    return [self.url hash];
}

- (NSArray *)children
{
    if (_children == nil || _childrenAreDirty) {
        NSMutableArray *children = [[NSMutableArray alloc] init];
        
        CFURLEnumeratorRef enumerator = CFURLEnumeratorCreateForDirectoryURL(NULL, (__bridge CFURLRef)_url, kCFURLEnumeratorSkipInvisibles, (__bridge CFArrayRef)[NSArray array]);
        
        NSURL *childURL = nil;
        CFURLRef childURLRef = NULL;
        CFURLEnumeratorResult enumeratorResult;
        do {
            enumeratorResult = CFURLEnumeratorGetNextURL(enumerator, &childURLRef, NULL);
            if (enumeratorResult == kCFURLEnumeratorSuccess) {
                childURL = (__bridge NSURL *)childURLRef;
                BDLFileSystemNode *childNode = [[BDLFileSystemNode alloc] initWithFileURL:childURL];
                
                if (_children) {
                    NSUInteger oldIndex = [_children indexOfObject:childNode];
                    if (oldIndex != NSNotFound) {
                        childNode = _children[oldIndex];
                    }
                }
                [children addObject:childNode];
            }
        } while (enumeratorResult != kCFURLEnumeratorEnd);
        
        CFRelease(enumerator);
        
        _childrenAreDirty = NO;
        _children = nil;
        
        _children = [children sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *obj1Name = [obj1 displayName];
            NSString *obj2Name = [obj2 displayName];
            
            NSComparisonResult result = [obj1Name compare:obj2Name options:NSNumericSearch | NSCaseInsensitiveSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch range:NSMakeRange(0, [obj1Name length]) locale:[NSLocale currentLocale]];
            
            return result;
        }];
    }
    
    return _children;
}

- (void)invalidateChildren
{
    _childrenAreDirty = YES;
    
    [_children makeObjectsPerformSelector:@selector(invalidateChildren)];
}

@end
