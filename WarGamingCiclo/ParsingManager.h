//
//  ParsingManager.h
//  WarGamingCiclo
//
//  Created by Admin on 28.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Nation, ShipType, Ship, Module, Upgrade;


@interface ParsingManager : NSObject

+ (ParsingManager*)sharedManager;

- (void)nation:(Nation*)nation fillWithName:(NSString*)name andID:(NSString*)nationID;

- (void)shipType:(ShipType*)type fillWithID:(NSString*)typeID name:(NSString*)name imagesDict:(NSDictionary*)imagesDict;

- (void)ship:(Ship*)ship fillWithID:(NSString*)shipID details:(NSDictionary*)dict;
- (void)ship:(Ship*)ship parseFullDetailResponse:(NSDictionary*)dict;

- (void)module:(Module*)module fillWithResponse:(NSDictionary*)response forShip:(Ship*)ship;
- (void)module:(Module *)module addShip:(Ship *)ship;

- (void)upgrade:(Upgrade*)upgrade fillWithResponse:(NSDictionary*)response forShip:(Ship*)ship;
- (void)upgrade:(Upgrade*)upgrade addShip:(Ship*)ship;


@end
