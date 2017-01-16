//
//  DataManager.h
//  WarGamingCiclo
//
//  Created by Admin on 23.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Nation, ShipType, Ship, Module, Upgrade;

@interface DataManager : NSObject

@property (readonly, strong) NSPersistentContainer *persistentContainer;

+ (DataManager*)sharedManager;

- (void)saveContext;

- (void)nationWithName:(NSString*)name andID:(NSString*)nationID;
- (void)shipTypeWithID:(NSString*)typeID name:(NSString*)name imagesDict:(NSDictionary*)imagesDict;

- (void)shipWithID:(NSString*)shipID details:(NSDictionary*)dict;

- (void)moduleWithResponse:(NSDictionary*)response forShip:(Ship*)ship;

- (void)upgradeWithResponse:(NSDictionary*)response forShip:(Ship*)ship;


- (NSArray*)getAllEntities:(NSString*)entityName;

- (Nation*)getNationWithID:(NSString*)nationID;
- (ShipType*)getShipTypeWithID:(NSString*)typeID;

- (NSArray*)getShipsForNation:(Nation*)nation orShipType:(ShipType*)type;

- (NSArray*)getEntities:(NSString*)entityName forShip:(Ship*)ship;

- (NSArray*)getModuleWithID:(NSString*)moduleID;
- (NSArray*)getUpgradeWithID:(NSString*)upgradeID;

@end
