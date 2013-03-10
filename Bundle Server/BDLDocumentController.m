//
//  BDLDocumentController.m
//  Bundle Server
//
//  Created by Darryl H. Thomas on 3/9/13.
//  Copyright (c) 2013 Darryl H. Thomas. All rights reserved.
//

#import "BDLDocumentController.h"
#import "BDLDocument.h"

@implementation BDLDocumentController

-(Class)documentClassForType:(NSString *)typeName
{
    if ([typeName isEqualToString:@"fold"])
        return [BDLDocument class];
    
    Class result = [super documentClassForType:typeName];
    
    return result;
}

-(NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)types
{
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    
    return [super runModalOpenPanel:openPanel forTypes:types];
}

- (NSString *)typeForContentsOfURL:(NSURL *)url error:(NSError *__autoreleasing *)outError
{
    NSString *path = [url path];
    BOOL isDirectory = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (exists && isDirectory) {
        return @"fold";
    }
    
    NSString *result = [super typeForContentsOfURL:url error:outError];
    
    return result;
}

@end
