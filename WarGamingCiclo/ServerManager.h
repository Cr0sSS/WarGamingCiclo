//
//  ServerManager.h
//  WarGamingCiclo
//
//  Created by Admin on 06.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Ship, Module, Upgrade;

@interface ServerManager : NSObject

@property (strong, nonatomic) NSString* currentDate;

+ (ServerManager*)sharedManager;

- (void)getTypesAndNationsFromServerOnSuccess:(void(^)(NSDictionary* response))success
                                     onFailure:(void(^)(NSError* error))failure;

- (void)getShipsFromServerWithType:(NSString*)typeID
                             nation:(NSString*)nationID
                          onSuccess:(void(^)(NSDictionary* responseObject))success
                          onFailure:(void(^)(NSError* error))failure;

- (void)getShipDetailsFromServerWithShip:(Ship*)ship
                        onSuccess:(void(^)(void))success
                        onFailure:(void(^)(NSError* error))failure;

- (void)getModuleFromServerWithID:(NSString*)moduleID
                         onSuccess:(void(^)(NSDictionary* response))success
                         onFailure:(void(^)(NSError* error))failure;

- (void)getUpgradeFromServerWithID:(NSString*)upgradeID
                          onSuccess:(void(^)(NSDictionary* response))success
                          onFailure:(void(^)(NSError* error))failure;

@end
