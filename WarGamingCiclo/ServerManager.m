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

+ (ServerManager*)sharedManager {
    
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


- (void)getTypesAndNationsFromServerOnSuccess:(void(^)(NSDictionary* response))success
                                     onFailure:(void(^)(NSError* error))failure {
    
    NSDictionary* params = @{@"application_id" : appID,
                             @"language" : @"ru",
                             @"fields" : @"ship_types,ship_type_images,ship_nations,ships_updated_at"};
    
    [self.sessionManager GET:@"info/"
                  parameters:params
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         
                         NSDictionary* response = responseObject[@"data"];
                         [ServerManager sharedManager].currentDate = [response[@"ships_updated_at"] stringValue];
                                                  
                         if (success) {
                             success(response);
                         }
                     }
                     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         if (failure) {
                             failure(error);
                         }
                     }];
}


- (void)getShipsFromServerWithType:(NSString*)typeID
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
    
    NSDictionary* params = @{@"application_id" : appID,
                             @"language" : @"ru",
                             @"fields" : @"ship_id,name,is_premium,tier,type,nation,images",
                             sortKey : sortObj};
    
    [self.sessionManager GET:@"ships/"
                  parameters:params
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         
                         if (success) {
                             success(responseObject);
                         }
                     }
                     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         if (failure) {
                             failure(error);
                         }
                     }];
}


- (void)getShipDetailsFromServerWithShip:(Ship*)ship
                        onSuccess:(void(^)(void))success
                        onFailure:(void(^)(NSError* error))failure {
 
    NSDictionary* params = @{@"application_id" : appID,
                             @"language" : @"ru",
                             @"ship_id" : ship.shipID};
    
    [self.sessionManager GET:@"ships/"
                  parameters:params
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         
                         NSDictionary* response = responseObject[@"data"];
                         NSDictionary* shipDetails = response[ship.shipID];
                                                  
                         [[ParsingManager sharedManager] ship:ship
                                       parseFullDetailResponse:shipDetails];
                         
                         if (success) {
                             success();
                         }
    }
                     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         if (failure) {
                             failure(error);
                         }
                     }];
}


- (void)getModuleFromServerWithID:(NSString*)moduleID
                                onSuccess:(void(^)(NSDictionary* response))success
                                onFailure:(void(^)(NSError* error))failure {
    
    NSDictionary* params = @{@"application_id" : appID,
                             @"language" : @"ru",
                             @"module_id" : moduleID};
    
    [self.sessionManager GET:@"modules/"
                  parameters:params
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         
                         NSDictionary* response = responseObject[@"data"][moduleID];
                         
                         if (success) {
                             success(response);
                         }
                     }
                     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         if (failure) {
                             failure(error);
                         }
                     }];
}


- (void)getUpgradeFromServerWithID:(NSString*)upgradeID
                         onSuccess:(void(^)(NSDictionary* response))success
                         onFailure:(void(^)(NSError* error))failure {
    
    NSDictionary* params = @{@"application_id" : appID,
                             @"language" : @"ru",
                             @"upgrade_id" : upgradeID};
    
    [self.sessionManager GET:@"upgrades/"
                  parameters:params
                    progress:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         
                         NSDictionary* response = responseObject[@"data"][upgradeID];
                         
                         if (success) {
                             success(response);
                         }
                     }
                     failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         if (failure) {
                             failure(error);
                         }
                     }];
}

@end
