//
//  ServerManager.m
//  WarGamingCiclo
//
//  Created by Admin on 06.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import "ServerManager.h"
#import "ParsingManager.h"

#import "AFNetworking.h"

#import "Nation+CoreDataClass.h"
#import "ShipType+CoreDataClass.h"
#import "Ship+CoreDataClass.h"
#import "Module+CoreDataClass.h"
#import "Upgrade+CoreDataClass.h"


@interface ServerManager()

@property (strong, nonatomic) NSString* serverStringURL;
@property (strong, nonatomic) AFHTTPSessionManager* sessionManager;

@end

@implementation ServerManager

static NSString* const appID = @"8e83a4094b23556bd9f4a5a71aa5194d";

+ (ServerManager*) sharedManager {
    
    static ServerManager* manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ServerManager alloc] init];
    });
    
    return manager;
}


- (instancetype) init {
    self = [super init];
    
    if (self) {
        self.serverStringURL = @"https://api.worldofwarships.ru/wows/encyclopedia/";
        NSURL* url = [NSURL URLWithString:self.serverStringURL];
        self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    }
    return self;
}


- (void) getTypesAndNationsFromServerOnSuccess:(void(^)(NSDictionary* response))success
                                     onFailure:(void(^)(NSError* error))failure {
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            appID,@"application_id",
                            @"ru",@"language",
                            @"ship_types,ship_type_images,ship_nations,ships_updated_at",@"fields",
                            nil];
    
    [self.sessionManager GET:@"info/"
                  parameters:params
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         
                         NSDictionary* response = [responseObject objectForKey:@"data"];
                         [ServerManager sharedManager].currentDate = [[response objectForKey:@"ships_updated_at"] stringValue];
                                                  
                         if (success) {
                             success(response);
                         }
    }
                     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         NSLog(@"SERVER MANAGER ERROR\nLoading types&nations:%@", [error localizedDescription]);
    }];
}


- (void) getShipsFromServerWithType:(NSString*)typeID
                             nation:(NSString*)nationID
                          onSuccess:(void(^)(NSDictionary* responseObject))success
                          onFailure:(void(^)(NSError* error))failure {
    
    NSString* sortObj;
    NSString* sortKey;
    
    //// Определение поля для выборки. Нельзя послать в запрос nil
    if (!typeID) {
        sortKey = @"nation";
        sortObj = nationID;
        
    } else if (!nationID) {
        sortKey = @"type";
        sortObj = typeID;
    }
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            appID,@"application_id",
                            @"ru",@"language",
                            @"ship_id,name,is_premium,tier,type,nation,images",@"fields",
                            sortObj,sortKey,
                            nil];
    
    [self.sessionManager GET:@"ships/"
                  parameters:params
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         
                         if (success) {
                             success(responseObject);
                         }
    }
                     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         NSLog(@"SERVER MANAGER ERROR\nLoading group of ships:%@", [error localizedDescription]);

    }];
}


- (void) getShipDetailsFromServerWithShip:(Ship*)ship
                        onSuccess:(void(^)(void))success
                        onFailure:(void(^)(NSError* error))failure {
 
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            appID,@"application_id",
                            @"ru",@"language",
                            ship.shipID,@"ship_id",
                            nil];
    
    [self.sessionManager GET:@"ships/"
                  parameters:params
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         
                         NSDictionary* response = [responseObject objectForKey:@"data"];
                         NSDictionary* shipDetails = [response objectForKey:ship.shipID];
                                                  
                         [[ParsingManager sharedManager] ship:ship
                                       parseFullDetailResponse:shipDetails];
                         
                         if (success) {
                             success();
                         }
    }
                     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         NSLog(@"SERVER MANAGER ERROR\nLoading ship details:%@", [error localizedDescription]);
    }];
}


- (void) getModuleFromServerWithID:(NSString*)moduleID
                                onSuccess:(void(^)(NSDictionary* response))success
                                onFailure:(void(^)(NSError* error))failure {
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            appID,@"application_id",
                            @"ru",@"language",
                            moduleID,@"module_id",
                            nil];
    
    [self.sessionManager GET:@"modules/"
                  parameters:params
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         
                         NSDictionary* response = [[responseObject objectForKey:@"data"] objectForKey:moduleID];
                         
                         if (success) {
                             success(response);
                         }
                     }
                     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         NSLog(@"SERVER MANAGER ERROR\nLoading module details:%@", [error localizedDescription]);
                     }];
}


- (void) getUpgradeFromServerWithID:(NSString*)upgradeID
                         onSuccess:(void(^)(NSDictionary* response))success
                         onFailure:(void(^)(NSError* error))failure {
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            appID,@"application_id",
                            @"ru",@"language",
                            upgradeID,@"upgrade_id",
                            nil];
    
    [self.sessionManager GET:@"upgrades/"
                  parameters:params
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         
                         NSDictionary* response = [[responseObject objectForKey:@"data"] objectForKey:upgradeID];
                         
                         if (success) {
                             success(response);
                         }
                     }
                     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         NSLog(@"SERVER MANAGER ERROR\nLoading upgrade details:%@", [error localizedDescription]);
                     }];
}

@end