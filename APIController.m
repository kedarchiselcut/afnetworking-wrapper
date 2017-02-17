//
//  APIController.m
//
//  Created by Kedar Kulkarni on 10/01/17.
//  Copyright (c) 2017 Kedar Kulkarni. All rights reserved.
//

#import "APIController.h"

#define BASE_URL @"" //TODO: Enter your base URL here

@interface APIController()

@property (nonatomic, strong) AFHTTPRequestOperationManager *requestManager;

@end

@implementation APIController

#pragma mark - Initialisation Methods

+ (id)sharedApiController {
    static APIController *apiController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        apiController = [[self alloc] init];
    });
    return apiController;
}

- (id)init {
    self = [super init];
    if (self) {
        _requestManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[self baseURLForString:BASE_URL]];
        _requestManager.responseSerializer = [AFHTTPResponseSerializer serializer];

        [self setReachabilityMonitor];
    }
    return self;
}

- (void)setReachabilityMonitor {
    AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:BASE_URL]]; //url can be something you want to reach
    
    NSOperationQueue *operationQueue = manager.operationQueue;
    [manager.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status)
        {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
                NSLog(@"REACHABLE");
                [operationQueue setSuspended:NO]; //or do whatever you want
                break;
            }
                
            case AFNetworkReachabilityStatusNotReachable:
            default:
            {
                NSLog(@"UNREACHABLE");
                [operationQueue setSuspended:YES];
                //not reachable,inform user perhaps
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No Internet Connection" message:@"Your Internet Connection appears to be offline. Some features may be disabled." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alertView show];
                break;
            }
        }
    }];
    [manager.reachabilityManager startMonitoring];
}

- (NSURL *)baseURLForString:(NSString *)baseURLString {
    NSURL *baseURL = [NSURL URLWithString:[baseURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    return baseURL;
}

- (NSString *)initialiseIndividualTimestampComponent:(NSString *)component {
    NSString *dayFormat = [NSDateFormatter dateFormatFromTemplate:component options:0 locale:[NSLocale currentLocale]];
    NSDateFormatter *dayTimestampFormatter = [[NSDateFormatter alloc] init];
    [dayTimestampFormatter setDateFormat:dayFormat];
    
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dayTimestampFormatter setTimeZone:gmt];
    NSString *timestamp = [dayTimestampFormatter stringFromDate:[NSDate date]];
    
    return timestamp;
}

- (NSString *)getInitialTimestamp {
    NSString *day = [self initialiseIndividualTimestampComponent:@"dd"];
    NSString *month = [self initialiseIndividualTimestampComponent:@"MM"];
    NSString *year = [self initialiseIndividualTimestampComponent:@"yyyy"];
    NSString *hour = [self initialiseIndividualTimestampComponent:@"HH"];
    NSString *minute = [self initialiseIndividualTimestampComponent:@"mm"];
    if ([minute length] == 1) {
        minute = [NSString stringWithFormat:@"0%@", minute];
    }
    NSString *second = [self initialiseIndividualTimestampComponent:@"ss"];
    if ([second length] == 1) {
        second = [NSString stringWithFormat:@"0%@", second];
    }
    
    NSString *timestamp = [NSString stringWithFormat:@"%@%@%@%@%@%@", day, month, year, hour, minute, second];
    
    return timestamp;
}

- (NSURLRequest *)urlRequestForDownloadTask:(NSString *)urlString WithParameters:(NSMutableDictionary *)paramDict {
    if (!paramDict) {
        paramDict = [[NSMutableDictionary alloc] init];
    }
    
    NSMutableURLRequest *request = [_requestManager.requestSerializer requestWithMethod:@"GET" URLString:[NSURL URLWithString:urlString] parameters:paramDict error:nil];
    return (NSURLRequest *)request;
}

#pragma mark - API Methods

-(void)getArrayOf:(NSString *)methodName withParameters:(NSMutableDictionary *)paramDict success:(void (^)(NSArray *))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *))failure {
    if (!paramDict) {
        paramDict = [[NSMutableDictionary alloc] init];
    }
    
    NSLog(@"Get array of %@ - %@", methodName, paramDict);
    
    [_requestManager GET:methodName parameters:paramDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *responseData = (NSData *)responseObject;
        NSError *error;
        NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error];
        if (!responseArray) {
            responseArray = [NSArray array];
        }
        success(responseArray);
    } failure:failure];
}

- (void)getDictOf:(NSString *)methodName withParameters:(NSMutableDictionary *)paramDict success:(void (^)(NSDictionary *))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *))failure {
    if (!paramDict) {
        paramDict = [[NSMutableDictionary alloc] init];
    }
    
    [_requestManager GET:methodName parameters:paramDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *responseData = (NSData *)responseObject;
        NSError *error;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error];
        success(responseDict);
    } failure:failure];
}

- (void)getObject:(NSString *)methodName withParameters:(NSMutableDictionary *)paramDict success:(void (^)(NSString *))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    NSLog(@"Get Object %@ - %@", methodName, paramDict);

    if (!paramDict) {
        paramDict = [[NSMutableDictionary alloc] init];
    }

    [_requestManager GET:methodName parameters:paramDict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSData *responseData = (NSData *)responseObject;
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        success(responseString);
    } failure:failure];
}

- (AFURLSessionManager *)download:(NSString *)urlString withParameters:(NSMutableDictionary *)paramDict success:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler uniqueFileName:(NSString *)fileName {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURLRequest *request = [self urlRequestForDownloadTask:urlString WithParameters:paramDict];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:fileName];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        completionHandler(response, filePath, error);
        if (![[NSData dataWithContentsOfFile:[filePath path]] bytes]) {
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:[filePath path] error:&error];
        }
    }];
    [downloadTask resume];
    return manager;
}

@end
