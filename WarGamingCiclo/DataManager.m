//
//  DataManager.m
//  WarGamingCiclo
//
//  Created by Admin on 23.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import "DataManager.h"
#import "ParsingManager.h"

#import "Nation+CoreDataClass.h"
#import "ShipType+CoreDataClass.h"
#import "Ship+CoreDataClass.h"
#import "Module+CoreDataClass.h"
#import "Upgrade+CoreDataClass.h"


@implementation DataManager

static NSArray* moduleTypes;
static NSArray* upgradeTypes;

+ (DataManager*)sharedManager {
    
    static DataManager* manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DataManager alloc] init];
        
        moduleTypes = @[@"Engine", @"Hull", @"Suo",
                      @"Artillery", @"Torpedoes", @"FlightControl",
                      @"Fighter", @"TorpedoBomber", @"DiveBomber"];
        
        upgradeTypes = @[@"powder", @"steering", @"guidance",
                         @"damage_control", @"mainweapon", @"secondweapon",
                         @"artillery", @"engine", @"anti_aircraft",
                         @"flight_control", @"planes", @"atba",
                         @"concealment", @"spotting", @"torpedoes"];
    });
    
    return manager;
}


#pragma mark - Creates

- (void)nationWithName:(NSString*)name andID:(NSString*)nationID {
    
    Nation* nation = [NSEntityDescription insertNewObjectForEntityForName:@"Nation"
                                                   inManagedObjectContext:self.persistentContainer.viewContext];
    [[ParsingManager sharedManager] nation:nation
                                       fillWithName:name
                                              andID:nationID];
}


- (void)shipTypeWithID:(NSString*)typeID name:(NSString*)name imagesDict:(NSDictionary*)imagesDict {
    
    ShipType* type = [NSEntityDescription insertNewObjectForEntityForName:@"ShipType"
                                                   inManagedObjectContext:self.persistentContainer.viewContext];
    [[ParsingManager sharedManager] shipType:type
                                         fillWithID:typeID
                                               name:name
                                         imagesDict:imagesDict];
}


- (void)shipWithID:(NSString*)shipID details:(NSDictionary*)dict {
    
    Ship* ship = [NSEntityDescription insertNewObjectForEntityForName:@"Ship"
                                                   inManagedObjectContext:self.persistentContainer.viewContext];
    [[ParsingManager sharedManager] ship:ship
                              fillWithID:shipID
                                 details:dict];
}


- (void)moduleWithResponse:(NSDictionary*)response forShip:(Ship*)ship {
    
    Module* module = [NSEntityDescription insertNewObjectForEntityForName:@"Module"
                                                   inManagedObjectContext:self.persistentContainer.viewContext];
    
    [[ParsingManager sharedManager] module:module fillWithResponse:response forShip:ship];
}


- (void)upgradeWithResponse:(NSDictionary*)response forShip:(Ship*)ship {
    
    Upgrade* upgrade = [NSEntityDescription insertNewObjectForEntityForName:@"Upgrade"
                                                     inManagedObjectContext:self.persistentContainer.viewContext];
    
    [[ParsingManager sharedManager] upgrade:upgrade fillWithResponse:response forShip:ship];
}



#pragma mark - Gets

- (NSArray*)getAllEntities:(NSString*)entityName {
    
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:entityName
                                                   inManagedObjectContext:self.persistentContainer.viewContext];

    [request setEntity:entity];
    
    NSSortDescriptor* descriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [request setSortDescriptors:@[descriptor]];
    
    NSArray* resultArray = [self.persistentContainer.viewContext executeFetchRequest:request error:nil];
    
    return resultArray;
}


- (NSArray*)getShipsForNation:(Nation*)nation orShipType:(ShipType*)type {
    
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Ship"
                                              inManagedObjectContext:self.persistentContainer.viewContext];
    [request setEntity:entity];
    
    NSPredicate* predicate;
    if (nation) {
        predicate = [NSPredicate predicateWithFormat:@"nation == %@", nation];

    } else if (type) {
        predicate = [NSPredicate predicateWithFormat:@"type == %@", type];
    }
    
    [request setPredicate:predicate];
    [request setFetchBatchSize:10];
    
    NSSortDescriptor* tierDescriptor = [[NSSortDescriptor alloc] initWithKey:@"tier" ascending:YES];
    NSSortDescriptor* nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [request setSortDescriptors:@[tierDescriptor, nameDescriptor]];

    NSArray* resultArray = [self.persistentContainer.viewContext executeFetchRequest:request error:nil];
    
    return resultArray;
}


- (Nation*)getNationWithID:(NSString*)nationID {
    
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Nation"
                                              inManagedObjectContext:self.persistentContainer.viewContext];
    [request setEntity:entity];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"nationID == %@", nationID];
    [request setPredicate:predicate];
    
    NSArray* resultArray = [self.persistentContainer.viewContext executeFetchRequest:request error:nil];
    Nation* nation = [resultArray firstObject];
    
    return nation;
}


- (ShipType*)getShipTypeWithID:(NSString*)typeID {
    
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"ShipType"
                                              inManagedObjectContext:self.persistentContainer.viewContext];
    [request setEntity:entity];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"typeID == %@", typeID];
    [request setPredicate:predicate];
    
    NSArray* resultArray = [self.persistentContainer.viewContext executeFetchRequest:request error:nil];
    ShipType* type = [resultArray firstObject];
    
    return type;
}


- (NSArray*)getEntities:(NSString*)entityName forShip:(Ship*)ship {
    
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:entityName
                                              inManagedObjectContext:self.persistentContainer.viewContext];
    [request setEntity:entity];
    
    NSMutableArray* groupsArray = [NSMutableArray new];
    
    NSArray* types;
    
    NSSortDescriptor* mainDescriptor;
    NSSortDescriptor* nameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    
    if ([entityName isEqualToString:@"Module"]) {
        types = moduleTypes;
        mainDescriptor = [[NSSortDescriptor alloc] initWithKey:@"price" ascending:YES];
        
    } else if ([entityName isEqualToString:@"Upgrade"]) {
        types = upgradeTypes;
        mainDescriptor = [[NSSortDescriptor alloc] initWithKey:@"mode" ascending:YES];
    }
    
    [request setSortDescriptors:@[mainDescriptor, nameDescriptor]];
    
    for (NSString* type in types) {
        
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"ships CONTAINS %@ && type == %@", ship, type];
        [request setPredicate:predicate];
        
        NSArray* resultArray = [self.persistentContainer.viewContext executeFetchRequest:request error:nil];
        
        if ([resultArray count] != 0) {
            [groupsArray addObject:resultArray];
        }
    }
    
    return [NSArray arrayWithArray:groupsArray];
}


- (NSArray*)getModuleWithID:(NSString*)moduleID {
    
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Module"
                                              inManagedObjectContext:self.persistentContainer.viewContext];
    [request setEntity:entity];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"moduleID == %@", moduleID];
    [request setPredicate:predicate];
    
    NSArray* resultArray = [self.persistentContainer.viewContext executeFetchRequest:request error:nil];
    
    return resultArray;
}


- (NSArray*)getUpgradeWithID:(NSString*)upgradeID {
    
    NSFetchRequest* request = [[NSFetchRequest alloc] init];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"Upgrade"
                                              inManagedObjectContext:self.persistentContainer.viewContext];
    [request setEntity:entity];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"upgradeID == %@", upgradeID];
    [request setPredicate:predicate];
    
    NSArray* resultArray = [self.persistentContainer.viewContext executeFetchRequest:request error:nil];
    
    return resultArray;
}


#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:@"WarGamingCiclo"];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    abort();
                }
            }];
        }
    }
    return _persistentContainer;
}


#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *context = self.persistentContainer.viewContext;
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
}

@end
