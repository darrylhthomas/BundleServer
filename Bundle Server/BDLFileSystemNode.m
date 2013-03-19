//
//  BDLFileSystemNode.m
//  Bundle Server
//
//  Created by Darryl H. Thomas on 3/10/13.
//

#import "BDLFileSystemNode.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation BDLFileSystemNode
{
    NSArray *_children;
    BOOL _childrenAreDirty;
    NSString *_md5String;
}

@dynamic displayName;
@dynamic children;
@dynamic isDirectory;
@dynamic icon;
@dynamic md5String;

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

- (NSString *)abbreviatedPathWithInitialLetters
{
    NSArray *pathComponents = [self.url pathComponents];
    NSUInteger count = [pathComponents count];
    NSUInteger lastIndex = count - 1;
    NSMutableArray *abbreviatedPathComponents = [[NSMutableArray alloc] initWithCapacity:count];
    [pathComponents enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, BOOL *stop) {
        if (idx == lastIndex || [component length] < 1) {
            [abbreviatedPathComponents addObject:component];
        } else {
            NSString *abbreviatedComponent = [component substringWithRange:NSMakeRange(0, 1)];
            [abbreviatedPathComponents addObject:abbreviatedComponent];
        }
    }];
    
    NSURL *url = [NSURL fileURLWithPathComponents:abbreviatedPathComponents];
    return [url path];
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

- (NSUInteger)fileSize
{
    if (self.isDirectory)
        return 0;
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[self.url path] error:NULL];
    
    return [attributes fileSize];
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

- (NSString *)md5String
{
    if (self.isDirectory)
        return nil;
    
    if (!_md5String) {
        NSData *data = [[NSData alloc] initWithContentsOfURL:self.url options:NSDataReadingMapped error:NULL];
        if (!data)
            return @"";
        
        CC_MD5_CTX context;
        CC_MD5_Init(&context);
        NSUInteger totalLength = [data length];
        NSUInteger bufferLen = MIN(16 * 1024 * 1024, totalLength);
        if (bufferLen == 0)
            return @"";
        
        NSUInteger offset = 0;
        uint8_t *buffer = calloc(bufferLen, sizeof(uint8_t));
        if (buffer == NULL)
            return @"";
        
        while (offset < totalLength) {
            NSRange range = NSMakeRange(offset, bufferLen);
            [data getBytes:buffer range:range];
            CC_MD5_Update(&context, buffer, (CC_LONG)bufferLen);
            
            offset += bufferLen;
            bufferLen = MIN(16 * 1024 * 1024, totalLength - offset);
        }
        free(buffer), buffer = NULL;
        
        unsigned char result[CC_MD5_DIGEST_LENGTH];
        CC_MD5_Final(result, &context);
        
        _md5String = [[NSString alloc] initWithFormat:
                      @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                      result[0], result[1], result[2], result[3],
                      result[4], result[5], result[6], result[7],
                      result[8], result[9], result[10], result[11],
                      result[12], result[13], result[14], result[15]];
        
    }
    
    return [_md5String copy];
}

- (NSArray *)children
{
    if (!self.isDirectory)
        return nil;
    
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

- (NSDictionary *)dictionaryRepresentation
{
    return [self dictionaryRepresentationWithBaseURL:self.url];
}

- (NSDictionary *)dictionaryRepresentationWithBaseURL:(NSURL *)baseURL
{
    return [self dictionaryRepresentationWithBaseURL:baseURL isRootNode:YES];
}

- (NSDictionary *)dictionaryRepresentationWithBaseURL:(NSURL *)baseURL isRootNode:(BOOL)isRootNode
{
    NSURL *url = nil;
    if (isRootNode) {
        url = baseURL;
    } else if (![baseURL isEqual:self.url]) {
        url = [baseURL URLByAppendingPathComponent:[self.url lastPathComponent] isDirectory:self.isDirectory];
    }
    
    NSMutableArray *children = nil;
    if (self.isDirectory) {
        children = [[NSMutableArray alloc] initWithCapacity:[self.children count]];
        for (BDLFileSystemNode *child in self.children) {
            [children addObject:[child dictionaryRepresentationWithBaseURL:url isRootNode:NO]];
        }
    }
    
    return @{
             @"url" : [url absoluteString],
             @"name" : isRootNode ? @"/" : [self.url lastPathComponent],
             @"isDirectory" : @(self.isDirectory),
             @"children" : self.isDirectory ? [children copy] : [NSNull null],
             @"md5Sum" : self.isDirectory ? [NSNull null] : self.md5String,
             @"size" : @(self.fileSize),
             };
}

- (BDLFileSystemNode *)nodeAtRelativePath:(NSString *)nodePath
{
    BDLFileSystemNode *result = self;
    NSArray *pathComponents = [nodePath pathComponents];
    for (NSString *component in pathComponents) {
        if ([component isEqualToString:@"/"])
            continue;
        
        result = [result childWithFilename:component];
        if (!result)
            break;
    }
    
    return result;
}

- (BDLFileSystemNode *)childWithFilename:(NSString *)childName
{
    NSParameterAssert(childName);
    
    BDLFileSystemNode *result = nil;
    for (BDLFileSystemNode *child in self.children) {
        if ([[child.url lastPathComponent] isEqualToString:childName]) {
            result = child;
            break;
        }
    }
    
    return result;
}

@end
