//
//  APIController.h
//
//  Created by Kedar Kulkarni on 10/01/17.
//  Copyright (c) 2017 Kedar Kulkarni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPRequestOperationManager.h"
#import "AFURLSessionManager.h"

@interface APIController : NSObject

+ (id)sharedApiController;

#pragma mark - API Methods

-(void)getArrayOf:(NSString *)methodName withParameters:(NSMutableDictionary *)paramDict success:(void (^)(NSArray *))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *))failure;
- (void)getObject:(NSString *)methodName withParameters:(NSMutableDictionary *)paramDict success:(void (^)(NSString *dictionary))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
- (void)getDictOf:(NSString *)methodName withParameters:(NSMutableDictionary *)paramDict success:(void (^)(NSDictionary *))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *))failure;
- (AFURLSessionManager *)download:(NSString *)urlString withParameters:(NSMutableDictionary *)paramDict success:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler uniqueFileName:(NSString *)fileName;

@end
