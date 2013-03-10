//
//  BDLBundleConnection.m
//  Bundle Server
//
//  Created by Darryl H. Thomas on 3/9/13.
//  Copyright (c) 2013 Darryl H. Thomas. All rights reserved.
//

#import "BDLBundleConnection.h"
#import "HTTPDataResponse.h"

@implementation BDLBundleConnection

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    NSData *data = [[config documentRoot] dataUsingEncoding:NSUTF8StringEncoding];
    
    HTTPDataResponse *response = [[HTTPDataResponse alloc] initWithData:data];
    
    return response;
}

@end
