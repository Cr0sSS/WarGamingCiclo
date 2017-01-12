//
//  ParsingManager.m
//  WarGamingCiclo
//
//  Created by Admin on 28.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import "ParsingManager.h"
#import "DataManager.h"
#import "ServerManager.h"

#import "Nation+CoreDataClass.h"
#import "ShipType+CoreDataClass.h"
#import "Ship+CoreDataClass.h"
#import "Module+CoreDataClass.h"
#import "Upgrade+CoreDataClass.h"


@implementation ParsingManager

+ (ParsingManager*) sharedManager {
    
    static ParsingManager* manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ParsingManager alloc] init];
    });
    
    return manager;
}


#pragma mark - Nation

- (void) nation:(Nation*)nation fillWithName:(NSString*)name andID:(NSString*)nationID {
    
    nation.nationID = nationID;
    nation.name = name;
    nation.refreshDate = [ServerManager sharedManager].currentDate;
}


#pragma mark - ShipType

- (void) shipType:(ShipType*)type fillWithID:(NSString*)typeID name:(NSString*)name imagesDict:(NSDictionary*)imagesDict {
    
    type.typeID = typeID;
    type.name = name;
    type.refreshDate = [ServerManager sharedManager].currentDate;
    
    if (imagesDict) {
        type.imageString = [imagesDict objectForKey:@"image"];
        type.premiumImageString = [imagesDict objectForKey:@"image_premium"];
        type.eliteImageString = [imagesDict objectForKey:@"image_elite"];
    }
}


#pragma mark - Ship

- (void) ship:(Ship*)ship fillWithID:(NSString*)shipID details:(NSDictionary*)dict {
    
    ship.shipID = shipID;
    ship.name = [dict objectForKey:@"name"];
    
    ship.type = [[DataManager sharedManager] getShipTypeWithID:[dict objectForKey:@"type"]];
    ship.nation = [[DataManager sharedManager] getNationWithID:[dict objectForKey:@"nation"]];
    
    ship.tier = [[dict objectForKey:@"tier"] integerValue];
    ship.isPremium = [[dict objectForKey:@"is_premium"] boolValue];
    
    NSDictionary* images = [dict objectForKey:@"images"];
    
    ship.contourImageString = [images objectForKey:@"contour"];
    ship.smallImageString = [images objectForKey:@"small"];
    ship.mediumImageString = [images objectForKey:@"medium"];
    ship.largeImageString = [images objectForKey:@"large"];
    
    ship.refreshDate = [ServerManager sharedManager].currentDate;
}


- (void) ship:(Ship*)ship parseFullDetailResponse:(NSDictionary*)dict {
    
    ship.modSlots = [[dict objectForKey:@"mod_slots"] integerValue];
    ship.review = [dict objectForKey:@"description"];
    
    //// ID всех модулей корабля
    NSArray* moduleGroups = [[dict objectForKey:@"modules"] allValues];
    NSMutableArray* moduleIDs = [NSMutableArray new];
    
    for (NSArray* group in moduleGroups) {
        for (id moduleID in group) {
            
            NSString* stringID = [moduleID stringValue];
            [moduleIDs addObject:stringID];
        }
    }
    ship.moduleIDs = [NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:moduleIDs]];
    
    
    //// ID всех апгрейдов корабля
    NSArray* upgrades = [dict objectForKey:@"upgrades"];
    NSMutableArray* upgradeStrings = [NSMutableArray new];
    
    for (id upgradeID in upgrades) {
        NSString* stringID = [upgradeID stringValue];
        [upgradeStrings addObject:stringID];
    }
    ship.upgradeIDs = [NSKeyedArchiver archivedDataWithRootObject:upgradeStrings];
    
    
    NSDictionary* defaultProfile = [dict objectForKey:@"default_profile"];
    
    ship.battleRangeMin = [[defaultProfile objectForKey:@"battle_level_range_min"] integerValue];
    ship.battleRangeMax = [[defaultProfile objectForKey:@"battle_level_range_max"] integerValue];
    
    //// Секция "Основные характеристики"
    NSArray* mainStatsArray = [NSArray arrayWithArray:[self parseMainStats:dict ofShip:ship]];
    ship.mainStats = [NSKeyedArchiver archivedDataWithRootObject:mainStatsArray];
    
    
    //// Секция "Маневренность"
    NSDictionary* mobility = [defaultProfile objectForKey:@"mobility"];
    
    if (![mobility isKindOfClass:[NSNull class]]) {
        
        NSArray* mobilityArray = [NSArray arrayWithArray:[self parseMobility:mobility]];
        ship.mobility = [NSKeyedArchiver archivedDataWithRootObject:mobilityArray];
    }
    
    
    //// Секция "Маскировка"
    NSDictionary* concealment = [defaultProfile objectForKey:@"concealment"];
    
    if (![concealment isKindOfClass:[NSNull class]]) {
        
        NSArray* concealmentArray = [NSArray arrayWithArray:[self parseConcealment:concealment]];
        ship.concealment = [NSKeyedArchiver archivedDataWithRootObject:concealmentArray];
    }
    
    
    //// Секция "ПВО"
    NSDictionary* antiAircraft = [defaultProfile objectForKey:@"anti_aircraft"];
    
    if (![antiAircraft isKindOfClass:[NSNull class]]) {
        
        NSArray* antiAircraftArray = [NSArray arrayWithArray:[self parseAntiAircraft:antiAircraft]];
        ship.antiAircraft = [NSKeyedArchiver archivedDataWithRootObject:antiAircraftArray];
    }
    
    
    //// Секция "Торпедное вооружение"
    NSDictionary* torpedoes = [defaultProfile objectForKey:@"torpedoes"];
    
    if (![torpedoes isKindOfClass:[NSNull class]]) {
        
        NSArray* torpedoesArray = [NSArray arrayWithArray:[self parseTorpedoes:torpedoes]];
        ship.torpedoes = [NSKeyedArchiver archivedDataWithRootObject:torpedoesArray];
    }
    
    
     //// Секция "Авиагруппа"
     if ([ship.type.typeID isEqual: @"AirCarrier"]) {
     
     NSArray* airGroupArray = [NSArray arrayWithArray:[self parseAirGroup:defaultProfile]];
     ship.airGroup = [NSKeyedArchiver archivedDataWithRootObject:airGroupArray];
     }
    
    
    //// Секция "Главный калибр"
    NSDictionary* artillery = [defaultProfile objectForKey:@"artillery"];
    
    if (![artillery isKindOfClass:[NSNull class]]) {
        
        NSArray* artilleryArray = [NSArray arrayWithArray:[self parseMainBattery:artillery]];
        ship.mainBattery = [NSKeyedArchiver archivedDataWithRootObject:artilleryArray];
    }
    
    
    //// Секция "Вспомогательный калибр"
    NSDictionary* atbas = [defaultProfile objectForKey:@"atbas"];
    
    if (![atbas isKindOfClass:[NSNull class]]) {
        
        NSArray* atbasArray = [NSArray arrayWithArray:[self parseAdditionalBattery:atbas]];
        ship.additionalBattery = [NSKeyedArchiver archivedDataWithRootObject:atbasArray];
    }
    
    ship.detailsRefreshDate = [ServerManager sharedManager].currentDate;
}


- (NSMutableArray*) parseMainStats:(NSDictionary*)dict ofShip:(Ship*)ship {
    
    NSDictionary* defaultProfile = [dict objectForKey:@"default_profile"];
    
    NSMutableArray* mainStatsArray = [NSMutableArray new];
    
    NSDictionary* hull = [defaultProfile objectForKey:@"hull"];
    NSDictionary* armour = [defaultProfile objectForKey:@"armour"];
    
    
    [mainStatsArray addObject:@"Стоимость исследования"];
    
    if (ship.isPremium) {
        [mainStatsArray addObject:@"премиумный"];
        
    } else {
        [mainStatsArray addObject:@"неизвестна"]; // стоимость для исследуемой техники не выдается через API
    }
    
    
    [mainStatsArray addObject:@"Цена покупки"];
    
    if (ship.isPremium) {
        NSString* price = [dict objectForKey:@"price_gold"];
        [mainStatsArray addObject:[NSString stringWithFormat:@"%@ золота", price]];
        
    } else {
        NSString* price = [dict objectForKey:@"price_credit"];
        
        if ([price isEqual:@"0"]) {
            [mainStatsArray addObject:@"неизвестна"];
        } else {
            [mainStatsArray addObject:[NSString stringWithFormat:@"%@ серебра", price]];
        }
    }
    
    
    [mainStatsArray addObject:@"Уровни боев"];
    [mainStatsArray addObject:[NSString stringWithFormat:@"%hd - %hd", ship.battleRangeMin, ship.battleRangeMax]];
    
    
    [mainStatsArray addObject:@"Боеспособность(здоровье)"];
    NSInteger healh = [[hull objectForKey:@"health"] integerValue];
    [mainStatsArray addObject:[NSString stringWithFormat:@"%ld", healh]];
    
    
    NSArray* armourPartNames = @[@"Диапазон бронирования",
                                 @"Бронирование цитадели",
                                 @"Бронирование казематов",
                                 @"Бронирование палубы",
                                 @"Бронирование оконечностей"];
    
    NSArray* armourPartKeys = @[@"range",
                                @"citadel",
                                @"casemate",
                                @"deck",
                                @"extremities"];
    
    for (NSInteger i = 0; i < [armourPartNames count]; i++) {
        [mainStatsArray addObject:[armourPartNames objectAtIndex:i]];
        
        NSDictionary* armourPart = [armour objectForKey:[armourPartKeys objectAtIndex:i]];
        [mainStatsArray addObject:[self armourRelease:armourPart]];
    }
    
    
    [mainStatsArray addObject:@"Снижение вероятности затопления"];
    NSString* floodProb = [self checkForNull:[armour objectForKey:@"flood_prob"]];
    [mainStatsArray addObject:[NSString stringWithFormat:@"%@%%", floodProb]];
    
    
    [mainStatsArray addObject:@"Снижение урона от затопления"];
    NSString* floodDamage = [self checkForNull:[armour objectForKey:@"flood_damage"]];
    [mainStatsArray addObject:[NSString stringWithFormat:@"%@%%", floodDamage]];
    
    return mainStatsArray;
}


- (NSMutableArray*) parseMobility:(NSDictionary*)mobility {
    
    NSMutableArray* mobilityArray = [NSMutableArray new];
    
    [mobilityArray addObject:@"Показатель маневренности"];
    NSString* total = [self checkForNull:[mobility objectForKey:@"total"]];
    [mobilityArray addObject:[NSString stringWithFormat:@"%@%%", total]];
    
    
    [mobilityArray addObject:@"Максимальная скорость"];
    NSString* speedValue = [self checkForNull:[mobility objectForKey:@"max_speed"]];
    
    if ([speedValue isEqual:@"NA"]) {
        [mobilityArray addObject:speedValue];
        
    } else {
        float speed = [speedValue floatValue];
        [mobilityArray addObject:[NSString stringWithFormat:@"%1.2f уз", speed]];
    }
    
    
    [mobilityArray addObject:@"Время перекладки руля"];
    NSString* rudderValue = [self checkForNull:[mobility objectForKey:@"rudder_time"]];
    
    if ([rudderValue isEqual:@"NA"]) {
        [mobilityArray addObject:rudderValue];
        
    } else {
        float rudderTime = [rudderValue floatValue];
        [mobilityArray addObject:[NSString stringWithFormat:@"%1.1f сек", rudderTime]];
    }
    
    
    [mobilityArray addObject:@"Радиус разворота"];
    NSString* radius = [self checkForNull:[mobility objectForKey:@"turning_radius"]];
    [mobilityArray addObject:[NSString stringWithFormat:@"%@ м", radius]];
    
    return mobilityArray;
}


- (NSMutableArray*) parseTorpedoes:(NSDictionary*)torpedoes {
    
    NSMutableArray* torpedoesArray = [NSMutableArray new];
    NSArray* slots = [[torpedoes objectForKey:@"slots"] allObjects];
    
    NSInteger torpedoGuns = 0;
    NSInteger torpedoBarrels = 0;
    
    
    for (NSDictionary* slot in slots) {
        NSInteger gunsInSlot = [[slot objectForKey:@"guns"] integerValue];
        torpedoGuns = torpedoGuns + gunsInSlot;
        torpedoBarrels = torpedoBarrels + [[slot objectForKey:@"barrels"] integerValue] * gunsInSlot;
    }
    
    [torpedoesArray addObject:[torpedoes objectForKey:@"torpedo_name"]];
    [torpedoesArray addObject:[NSString stringWithFormat:@"Установки: %ld; всего труб: %ld", torpedoGuns, torpedoBarrels]];
    
    
    NSString* reloadTimeString = [self checkForNull:[torpedoes objectForKey:@"reload_time"]];
    [torpedoesArray addObject:@"Скорострельность"];
    
    if ([reloadTimeString isEqual:@"NA"]) {
        [torpedoesArray addObject:reloadTimeString];
        
    } else {
        float rof = 60.f / [reloadTimeString floatValue];
        [torpedoesArray addObject:[NSString stringWithFormat:@"%1.2f выст/мин", rof]];
    }
    
    
    [torpedoesArray addObject:@"Время перезарядки"];
    [torpedoesArray addObject:[NSString stringWithFormat:@"%@ сек", reloadTimeString]];
    
    
    NSString* rotationTimeString = [self checkForNull:[torpedoes objectForKey:@"rotation_time"]];
    [torpedoesArray addObject:@"Скорость горизонтальной наводки"];
    
    if ([rotationTimeString isEqual:@"NA"]) {
        [torpedoesArray addObject:rotationTimeString];
        
    } else {
        float rotationSpeed = 180 / [rotationTimeString floatValue];
        [torpedoesArray addObject:[NSString stringWithFormat:@"%1.1f гр/сек", rotationSpeed]];
    }
    
    
    [torpedoesArray addObject:@"Время поворота ТА на 180 градусов"];
    
    if ([rotationTimeString isEqual:@"NA"]) {
        [torpedoesArray addObject:rotationTimeString];
        
    } else {
        float rotationTime = [rotationTimeString floatValue];
        [torpedoesArray addObject:[NSString stringWithFormat:@"%1.1f сек", rotationTime]];
    }
    
    
    for (NSDictionary* slot in slots) {
        
        [torpedoesArray addObject:@"Торпеда"];
        NSString* name = [self checkForNull:[slot objectForKey:@"name"]];
        [torpedoesArray addObject:name];
        
        
        [torpedoesArray addObject:@"Калибр"];
        NSString* caliber = [self checkForNull:[slot objectForKey:@"caliber"]];
        [torpedoesArray addObject:[NSString stringWithFormat:@"%@ мм", caliber]];
    }
    
    
    [torpedoesArray addObject:@"Максимальный урон"];
    NSString* damage = [self checkForNull:[torpedoes objectForKey:@"max_damage"]];
    [torpedoesArray addObject:damage];
    
    
    [torpedoesArray addObject:@"Скорость хода торпед"];
    NSString* speed = [self checkForNull:[torpedoes objectForKey:@"torpedo_speed"]];
    [torpedoesArray addObject:[NSString stringWithFormat:@"%@ уз", speed]];
    
    
    [torpedoesArray addObject:@"Дальность хода торпед"];
    NSString* distanceString = [self checkForNull:[torpedoes objectForKey:@"distance"]];
    
    if ([distanceString isEqual:@"NA"]) {
        [torpedoesArray addObject:distanceString];
        
    } else {
        float distance = [distanceString floatValue];
        [torpedoesArray addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
    }
    
    
    [torpedoesArray addObject:@"Дальность обнаружения торпед"];
    NSString* visDistanceString = [self checkForNull:[torpedoes objectForKey:@"visibility_dist"]];
    
    if ([visDistanceString isEqual:@"NA"]) {
        [torpedoesArray addObject:visDistanceString];
        
    } else {
        float visDistance = [visDistanceString floatValue];
        [torpedoesArray addObject:[NSString stringWithFormat:@"%1.1f км", visDistance]];
    }
    
    return torpedoesArray;
}


- (NSMutableArray*) parseAirGroup:(NSDictionary*)defaultProfile {
    
    NSMutableArray* airGroupArray = [NSMutableArray new];
    
    [airGroupArray addObject:@"Вместимость ангара"];
    NSString* planesCount = [self checkForNull:[[defaultProfile objectForKey:@"hull"] objectForKey:@"planes_amount"]];
    [airGroupArray addObject:[NSString stringWithFormat:@"%@ шт", planesCount]];
    
    
    NSDictionary* fighters = [defaultProfile objectForKey:@"fighters"];
    if (![fighters isKindOfClass:[NSNull class]]) {
        
        [airGroupArray addObject:@"Истребители"];
        [airGroupArray addObject:[self checkHardTextForNull:[fighters objectForKey:@"name"]]];
        
        [airGroupArray addObjectsFromArray:[self parcePlaneType:fighters]];
    }
    
    
    NSDictionary* torpedoBombers = [defaultProfile objectForKey:@"torpedo_bomber"];
    if (![torpedoBombers isKindOfClass:[NSNull class]]) {
        
        [airGroupArray addObject:@"Торпедоносцы"];
        [airGroupArray addObject:[self checkHardTextForNull:[torpedoBombers objectForKey:@"name"]]];
        
        [airGroupArray addObjectsFromArray:[self parcePlaneType:torpedoBombers]];
    }
    
    
    NSDictionary* diveBombers = [defaultProfile objectForKey:@"torpedo_bomber"];
    if (![diveBombers isKindOfClass:[NSNull class]]) {
        
        [airGroupArray addObject:@"Бомбардировщики"];
        [airGroupArray addObject:[self checkHardTextForNull:[diveBombers objectForKey:@"name"]]];
        
        [airGroupArray addObjectsFromArray:[self parcePlaneType:diveBombers]];
    }
    
    return airGroupArray;
}


- (NSMutableArray*) parseConcealment:(NSDictionary*)concealment {
    
    NSMutableArray* concealmentArray = [NSMutableArray new];
    
    [concealmentArray addObject:@"Показатель маскировки"];
    NSString* total = [self checkForNull:[concealment objectForKey:@"total"]];
    [concealmentArray addObject:[NSString stringWithFormat:@"%@%%", total]];
    
    
    [concealmentArray addObject:@"Дальность обнаружения с кораблей"];
    NSString* distanceShipValue = [self checkForNull:[concealment objectForKey:@"detect_distance_by_ship"]];
    
    if ([distanceShipValue isEqual:@"NA"]) {
        [concealmentArray addObject:distanceShipValue];
        
    } else {
        float distanceShip = [distanceShipValue floatValue];
        [concealmentArray addObject:[NSString stringWithFormat:@"%1.1f км", distanceShip]];
    }
    
    
    [concealmentArray addObject:@"Дальность обнаружения с самолетов"];
    NSString* distancePlaneValue = [self checkForNull:[concealment objectForKey:@"detect_distance_by_plane"]];
    
    if ([distancePlaneValue isEqual:@"NA"]) {
        [concealmentArray addObject:distancePlaneValue];
        
    } else {
        float distancePlane = [distancePlaneValue floatValue];
        [concealmentArray addObject:[NSString stringWithFormat:@"%1.1f км", distancePlane]];
    }
    
    return concealmentArray;
}


- (NSMutableArray*) parseMainBattery:(NSDictionary*)artillery {
    
    NSMutableArray* mainBatteryArray = [NSMutableArray new];
    
    NSArray* artillerySlots = [[artillery objectForKey:@"slots"] allObjects];
    for (NSDictionary* slot in artillerySlots) {
        
        [mainBatteryArray addObject:[slot objectForKey:@"name"]];
        NSString* slotsGuns = [[slot objectForKey:@"guns"] stringValue];
        NSString* slotsBarrels = [[slot objectForKey:@"barrels"] stringValue];
        [mainBatteryArray addObject:[NSString stringWithFormat:@"Установки: %@; стволов в каждой: %@", slotsGuns, slotsBarrels]];
    }
    
    
    [mainBatteryArray addObject:@"Скорострельность"];
    NSString* rofValue = [self checkForNull:[artillery objectForKey:@"gun_rate"]];
    
    if ([rofValue isEqual:@"NA"]) {
        [mainBatteryArray addObject:rofValue];
        
    } else {
        float rof = [rofValue floatValue];
        [mainBatteryArray addObject:[NSString stringWithFormat:@"%1.2f выстр/сек", rof]];
    }
    
    
    [mainBatteryArray addObject:@"Дальность стрельбы"];
    NSString* distanceValue = [self checkForNull:[artillery objectForKey:@"distance"]];
    
    if ([distanceValue isEqual:@"NA"]) {
        [mainBatteryArray addObject:distanceValue];
        
    } else {
        float distance = [distanceValue floatValue];
        [mainBatteryArray addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
    }
    
    
    [mainBatteryArray addObject:@"Время перезарядки"];
    NSString* reloadValue = [self checkForNull:[artillery objectForKey:@"shot_delay"]];
    
    if ([reloadValue isEqual:@"NA"]) {
        [mainBatteryArray addObject:reloadValue];
        
    } else {
        float reload = [reloadValue floatValue];
        [mainBatteryArray addObject:[NSString stringWithFormat:@"%1.2f сек", reload]];
    }
    
    
    [mainBatteryArray addObject:@"Время поворота на 180 градусов"];
    NSString* rotationTime = [self checkForNull:[artillery objectForKey:@"rotation_time"]];
    [mainBatteryArray addObject:[NSString stringWithFormat:@"%@ сек", rotationTime]];
    
    
    [mainBatteryArray addObject:@"Скорость горизонтального наведения"];
    NSString* gunRate = [self checkForNull:[artillery objectForKey:@"gun_rate"]];
    
    if ([gunRate isEqual:@"NA"]) {
        [mainBatteryArray addObject:gunRate];
        
    } else {
        float rate = [gunRate floatValue];
        [mainBatteryArray addObject:[NSString stringWithFormat:@"%1.1f гр./сек", rate]];
    }
    
    
    [mainBatteryArray addObject:@"Максимальное рассеивание"];
    NSString* dispersion = [self checkForNull:[artillery objectForKey:@"max_dispersion"]];
    [mainBatteryArray addObject:[NSString stringWithFormat:@"%@ м", dispersion]];
    
    
    NSArray* shellsArray = [[artillery objectForKey:@"shells"] allObjects];
    
    for (NSDictionary* shell in shellsArray) {
        NSString* shellType;
        
        if (shell && ![shell isKindOfClass:[NSNull class]]) {
            if ([[shell objectForKey:@"type"] isEqual:@"AP"]) {
                shellType = @"ББ";
            } else if ([[shell objectForKey:@"type"] isEqual:@"HE"]) {
                shellType = @"ОФ";
            }
            
            [mainBatteryArray addObject:[NSString stringWithFormat:@"%@ снаряд", shellType]];
            NSString* shellName = [self checkForNull:[shell objectForKey:@"name"]];
            [mainBatteryArray addObject:shellName];
            
            
            [mainBatteryArray addObject:[NSString stringWithFormat:@"Максимальный урон %@ снаряда", shellType]];
            NSString* shellDamage = [self checkForNull:[shell objectForKey:@"damage"]];
            [mainBatteryArray addObject:shellDamage];
            
            
            [mainBatteryArray addObject:[NSString stringWithFormat:@"Вероятность пожара от %@ снаряда", shellType]];
            NSString* shellBurn = [self checkForNull:[shell objectForKey:@"burn_probability"]];
            [mainBatteryArray addObject:[NSString stringWithFormat:@"%@%%", shellBurn]];
            
            
            [mainBatteryArray addObject:[NSString stringWithFormat:@"Начальная скорость %@ снаряда", shellType]];
            NSString* shellSpeed = [self checkForNull:[shell objectForKey:@"bullet_speed"]];
            [mainBatteryArray addObject:[NSString stringWithFormat:@"%@ м/сек", shellSpeed]];
            
            
            [mainBatteryArray addObject:[NSString stringWithFormat:@"Масса %@ снаряда", shellType]];
            NSString* shellMass = [self checkForNull:[shell objectForKey:@"bullet_mass"]];
            [mainBatteryArray addObject:[NSString stringWithFormat:@"%@ кг", shellMass]];
        }
    }
    return mainBatteryArray;
}


- (NSMutableArray*) parseAdditionalBattery:(NSDictionary*)atbas {
    
    NSMutableArray* additionalBatteryArray = [NSMutableArray new];
    
    NSArray* artillerySlots = [[atbas objectForKey:@"slots"] allObjects];
    
    for (NSDictionary* slot in artillerySlots) {
        
        NSMutableArray* battery = [NSMutableArray new];
        
        [battery addObject:@"Дальность стрельбы"];
        NSString* distanceValue = [self checkForNull:[atbas objectForKey:@"distance"]];
        
        if ([distanceValue isEqual:@"NA"]) {
            [battery addObject:distanceValue];
            
        } else {
            float distance = [distanceValue floatValue];
            [battery addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
        }
        
        
        [battery addObject:@"Скорость горизонтального наведения"];
        NSString* gunRate = [self checkForNull:[slot objectForKey:@"gun_rate"]];
        
        if ([gunRate isEqual:@"NA"]) {
            [battery addObject:gunRate];
            
        } else {
            float rate = [gunRate floatValue];
            [battery addObject:[NSString stringWithFormat:@"%1.1f гр/сек", rate]];
        }
        
        
        [battery addObject:@"Время перезарядки"];
        NSString* reloadValue = [self checkForNull:[slot objectForKey:@"shot_delay"]];
        
        if ([reloadValue isEqual:@"NA"]) {
            [battery addObject:reloadValue];
            
        } else {
            float reload = [reloadValue floatValue];
            [battery addObject:[NSString stringWithFormat:@"%1.2f сек", reload]];
        }
        
        NSString* shellType;
        if ([[slot objectForKey:@"type"] isEqual:@"AP"]) {
            shellType = @"ББ";
        } else if ([[slot objectForKey:@"type"] isEqual:@"HE"]) {
            shellType = @"ОФ";
        }
        
        [battery addObject:[NSString stringWithFormat:@"%@ снаряд", shellType]];
        NSString* shellName = [self checkForNull:[slot objectForKey:@"name"]];
        [battery addObject:shellName];
        
        
        [battery addObject:[NSString stringWithFormat:@"Максимальный урон %@ снаряда", shellType]];
        NSString* shellDamage = [self checkForNull:[slot objectForKey:@"damage"]];
        [battery addObject:shellDamage];
        
        
        [battery addObject:[NSString stringWithFormat:@"Вероятность пожара от %@ снаряда", shellType]];
        NSString* shellBurn = [self checkForNull:[slot objectForKey:@"burn_probability"]];
        [battery addObject:[NSString stringWithFormat:@"%@%%", shellBurn]];
        
        
        [battery addObject:[NSString stringWithFormat:@"Начальная скорость %@ снаряда", shellType]];
        NSString* shellSpeed = [self checkForNull:[slot objectForKey:@"bullet_speed"]];
        [battery addObject:[NSString stringWithFormat:@"%@ м/сек", shellSpeed]];
        
        
        [battery addObject:[NSString stringWithFormat:@"Масса %@ снаряда", shellType]];
        NSString* shellMass = [self checkForNull:[slot objectForKey:@"bullet_mass"]];
        [battery addObject:[NSString stringWithFormat:@"%@ кг", shellMass]];
        
        [additionalBatteryArray addObject:battery];
    }
    
    return additionalBatteryArray;
}


- (NSMutableArray*) parseAntiAircraft:(NSDictionary*)antiAircraft {
    
    NSMutableArray* antiAircraftArray = [NSMutableArray new];
    
    [antiAircraftArray addObject:@"Эффективность ПВО"];
    NSString* defenseValue = [self checkForNull:[antiAircraft objectForKey:@"defense"]];
    [antiAircraftArray addObject:[NSString stringWithFormat:@"%@%%", defenseValue]];
    
    
    NSArray* slots = [[antiAircraft objectForKey:@"slots"] allValues];
    for (NSDictionary* slot in slots) {
        
        [antiAircraftArray addObject:[slot objectForKey:@"name"]];
        NSString* guns = [self checkForNull:[slot objectForKey:@"guns"]];
        [antiAircraftArray addObject:[NSString stringWithFormat:@"%@ шт", guns]];
        
        
        [antiAircraftArray addObject:@"....калибр"];
        NSString* caliber = [self checkForNull:[slot objectForKey:@"caliber"]];
        [antiAircraftArray addObject:[NSString stringWithFormat:@"%@ мм", caliber]];
        
        
        [antiAircraftArray addObject:@"....средний урон в секунду"];
        NSString* damage = [self checkForNull:[slot objectForKey:@"avg_damage"]];
        [antiAircraftArray addObject:damage];
        
        
        [antiAircraftArray addObject:@"....дальность стрельбы"];
        NSString* distanceValue = [self checkForNull:[slot objectForKey:@"distance"]];
        
        if ([distanceValue isEqual:@"NA"]) {
            [antiAircraftArray addObject:distanceValue];
            
        } else {
            float distance = [distanceValue floatValue];
            [antiAircraftArray addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
        }
    }
    return antiAircraftArray;
}


- (NSMutableArray*) parcePlaneType:(NSDictionary*)planeType {
    
    NSMutableArray* typeArray = [NSMutableArray new];
    
    [typeArray addObject:@"....уровень"];
    [typeArray addObject:[self checkForNull:[planeType objectForKey:@"plane_level"]]];
    
    [typeArray addObject:@"....самолетов в ангаре"];
    NSString* squads = [self checkHardTextForNull:[planeType objectForKey:@"squadrons"]];
    NSString* planesInSquad = [self checkHardTextForNull:[[planeType objectForKey:@"count_in_squadron"] objectForKey:@"max"]];
    
    if ([squads isEqual:@"NA"] && [planesInSquad isEqual:@"NA"]) {
        [typeArray addObject:planesInSquad];
        
    } else {
        [typeArray addObject:[NSString stringWithFormat:@"Эскадрильи: %@ по %@ самолетов", squads, planesInSquad]];
    }
    
    return typeArray;
}


- (NSString*) armourRelease:(NSDictionary*)armourPart {
    
    NSString* valueMin = [armourPart objectForKey:@"min"];
    NSString* valueMax = [armourPart objectForKey:@"max"];
    
    if ([valueMin isEqual:valueMax]) {
        
        if ([valueMin integerValue] == 0) {
            return @"нет бронирования";
            
        } else {
            return [NSString stringWithFormat:@"%@ мм", valueMin];
        }
        
    } else {
        return [NSString stringWithFormat:@"%@ - %@ мм", valueMin, valueMax];
    }
}


#pragma mark - Module

- (void) module:(Module*)module fillWithResponse:(NSDictionary*)response forShip:(Ship*)ship {
    
    [self module:module addShip:ship];
    
    module.moduleID = [[response objectForKey:@"module_id"] stringValue];
    module.name = [response objectForKey:@"name"];
    
    module.type = [response objectForKey:@"type"];
    module.price = [[response objectForKey:@"price_credit"] intValue];
    
    module.imageString = [response objectForKey:@"image"];
    
    module.refreshDate = [ServerManager sharedManager].currentDate;
    
    NSMutableArray* stats;
    NSDictionary* profile = [response objectForKey:@"profile"];
    
    if ([module.type isEqual:@"Engine"]) {
        module.typeLocalized = @"Двигатель";
        stats = [self parseEngineModule:[profile objectForKey:@"engine"]];
        
    } else if ([module.type isEqual:@"Hull"]) {
        module.typeLocalized = @"Корпус";
        stats = [self parseHullModule:[profile objectForKey:@"hull"]];
        
    } else if ([module.type isEqual:@"Suo"]) {
        module.typeLocalized = @"Система управления огнем";
        stats = [self parseFireControlModule:[profile objectForKey:@"fire_control"]];
        
    } else if ([module.type isEqual:@"Artillery"]) {
        module.typeLocalized = @"Главный калибр";
        stats = [self parseArtilleryModule:[profile objectForKey:@"artillery"]];
        
    } else if ([module.type isEqual:@"Torpedoes"]) {
        module.typeLocalized = @"Торпедные аппараты";
        stats = [self parseTorpedoesModule:[profile objectForKey:@"torpedoes"]];
        
    } else if ([module.type isEqual:@"FlightControl"]) {
        module.typeLocalized = @"Контроль полетов";
        stats = [self parseFlightControlModule:[profile objectForKey:@"flight_control"]];
        
    } else if ([module.type isEqual:@"Fighter"]) {
        module.typeLocalized = @"Истребители";
        stats = [self parseFightersModule:[profile objectForKey:@"fighter"]];
        
    } else if ([module.type isEqual:@"TorpedoBomber"]) {
        module.typeLocalized = @"Торпедоносцы";
        stats = [self parseTorpedoBombersModule:[profile objectForKey:@"torpedo_bomber"]];
        
    } else if ([module.type isEqual:@"DiveBomber"]) {
        module.typeLocalized = @"Пикирующие бомбардировщики";
        stats = [self parseDiveBombersModule:[profile objectForKey:@"dive_bomber"]];
    }
    
    NSArray* statsArray = [NSArray arrayWithArray:stats];
    module.stats = [NSKeyedArchiver archivedDataWithRootObject:statsArray];
}


//// Соединение Модуля с Кораблем без повторов
- (void) module:(Module *)module addShip:(Ship *)ship {
    
    if (![module.ships containsObject:ship]) {
        [module addShipsObject:ship];
    }
}


- (NSMutableArray*) parseEngineModule:(NSDictionary*)engine {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Максимальная скорость"];
    NSString* maxSpeed = [self checkForNull:[engine objectForKey:@"max_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", maxSpeed]];
    
    return details;
}


- (NSMutableArray*) parseHullModule:(NSDictionary*)hull {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Боеспособность (здоровье)"];
    NSString* health = [self checkForNull:[hull objectForKey:@"health"]];
    [details addObject:health];
    
    
    [details addObject:@"Диапазон бронирования"];
    NSString* valueMin = [[hull objectForKey:@"range"] objectForKey:@"min"];
    NSString* valueMax = [[hull objectForKey:@"range"] objectForKey:@"max"];
    
    if ([valueMin integerValue] == 0) {
        [details addObject: @"нет бронирования"];
        
    } else {
        [details addObject:[NSString stringWithFormat:@"%@ - %@ мм", valueMin, valueMax]];
    }
    
    
    [details addObject:@"Башен главного калибра"];
    NSString* artillery = [self checkForNull:[hull objectForKey:@"artillery_barrels"]];
    [details addObject:artillery];
    
    
    [details addObject:@"Башен вспомогательного калибра"];
    NSString* atbas = [self checkForNull:[hull objectForKey:@"atba_barrels"]];
    [details addObject:atbas];
    
    
    [details addObject:@"Точек ПВО"];
    NSString* antiAir = [self checkForNull:[hull objectForKey:@"anti_aircraft_barrels"]];
    [details addObject:antiAir];
    
    
    [details addObject:@"Торпедных аппаратов"];
    NSString* torpedoes = [self checkForNull:[hull objectForKey:@"torpedoes_barrels"]];
    [details addObject:torpedoes];
    
    
    [details addObject:@"Вместимость ангара"];
    NSString* hangar = [self checkForNull:[hull objectForKey:@"planes_amount"]];
    [details addObject:hangar];
    
    return details;
}


- (NSMutableArray*) parseFireControlModule:(NSDictionary*)fireControl {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Дальность стрельбы"];
    NSString* distanceString = [self checkForNull:[fireControl objectForKey:@"distance"]];
    
    if ([distanceString isEqual:@"NA"]) {
        [details addObject:distanceString];
        
    } else {
        float distance = [distanceString floatValue];
        [details addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
    }
    
    
    [details addObject:@"Увеличение дальности стрельбы"];
    NSString* distIncrease = [self checkForNull:[fireControl objectForKey:@"distance_increase"]];
    [details addObject:[NSString stringWithFormat:@"%@%%", distIncrease]];
    
    return details;
}


- (NSMutableArray*) parseArtilleryModule:(NSDictionary*)artillery {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Скорострельность"];
    NSString* gunRateString = [self checkForNull:[artillery objectForKey:@"gun_rate"]];
    
    if ([gunRateString isEqual:@"NA"]) {
        [details addObject:gunRateString];
        
    } else {
        float gunRate = [gunRateString floatValue];
        [details addObject:[NSString stringWithFormat:@"%1.2f выст/мин", gunRate]];
    }
    
    
    [details addObject:@"Время перезарядки"];
    
    if ([gunRateString isEqual:@"NA"]) {
        [details addObject:gunRateString];
        
    } else {
        float reloadTime = 60.f / [gunRateString floatValue];
        [details addObject:[NSString stringWithFormat:@"%1.2f сек", reloadTime]];
    }
    
    
    [details addObject:@"Максимальный урон ОФ снарядом"];
    NSString* damageHE = [self checkForNull:[artillery objectForKey:@"max_damage_HE"]];
    [details addObject:damageHE];
    
    
    [details addObject:@"Максимальный урон ББ снарядом"];
    NSString* damageAP = [self checkForNull:[artillery objectForKey:@"max_damage_AP"]];
    [details addObject:damageAP];
    
    
    return details;
}


- (NSMutableArray*) parseTorpedoesModule:(NSDictionary*)torpedoes {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Максимальный урон"];
    NSString* damage = [self checkForNull:[torpedoes objectForKey:@"max_damage"]];
    [details addObject:damage];
    
    
    [details addObject:@"Время перезарядки"];
    NSString* shotSpeedString = [self checkForNull:[torpedoes objectForKey:@"shot_speed"]];
    
    if ([shotSpeedString isEqual:@"NA"]) {
        [details addObject:shotSpeedString];
        
    } else {
        float shotSpeed = [shotSpeedString floatValue];
        [details addObject:[NSString stringWithFormat:@"%1.2f сек", shotSpeed]];
    }
    
    
    [details addObject:@"Скорость хода"];
    NSString* speed = [self checkForNull:[torpedoes objectForKey:@"torpedo_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", speed]];
    
    
    [details addObject:@"Дальность хода"];
    NSString* distanceString = [self checkForNull:[torpedoes objectForKey:@"distance"]];
    
    if ([distanceString isEqual:@"NA"]) {
        [details addObject:distanceString];
        
    } else {
        float distance = [distanceString floatValue];
        [details addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
    }
    
    return details;
}


- (NSMutableArray*) parseFlightControlModule:(NSDictionary*)flightControl {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Эскадрилий истребителей"];
    [details addObject:[[flightControl objectForKey:@"fighter_squadrons"] stringValue]];
    
    
    [details addObject:@"Эскадрилий бомбардировщиков"];
    [details addObject:[[flightControl objectForKey:@"bomber_squadrons"] stringValue]];
    
    
    [details addObject:@"Эскадрилий торпедоносцев"];
    [details addObject:[[flightControl objectForKey:@"torpedo_squadrons"] stringValue]];
    
    return details;
}


- (NSMutableArray*) parseFightersModule:(NSDictionary*)fighters {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Крейсерская скорость"];
    NSString* speed = [self checkForNull:[fighters objectForKey:@"cruise_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", speed]];
    
    
    [details addObject:@"Средний урон в секунду"];
    NSString* damage = [self checkForNull:[fighters objectForKey:@"avg_damage"]];
    [details addObject:damage];
    
    
    [details addObject:@"Боеспособность (здоровье)"];
    NSString* health = [self checkForNull:[fighters objectForKey:@"max_health"]];
    [details addObject:health];
    
    
    [details addObject:@"Боекомплект"];
    NSString* ammo = [self checkForNull:[fighters objectForKey:@"max_ammo"]];
    [details addObject:ammo];
    
    return details;
}


- (NSMutableArray*) parseTorpedoBombersModule:(NSDictionary*)torpedoBombers {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Крейсерская скорость"];
    NSString* speed = [self checkForNull:[torpedoBombers objectForKey:@"cruise_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", speed]];
    
    
    [details addObject:@"Боеспособность (здоровье)"];
    NSString* health = [self checkForNull:[torpedoBombers objectForKey:@"max_health"]];
    [details addObject:health];
    
    
    [details addObject:@"Максимальный урон торпедой"];
    NSString* damage = [self checkForNull:[torpedoBombers objectForKey:@"torpedo_damage"]];
    [details addObject:damage];
    
    
    [details addObject:@"Максимальная скорость торпеды"];
    NSString* torpedoSpeed = [self checkForNull:[torpedoBombers objectForKey:@"torpedo_max_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", torpedoSpeed]];
    
    // На данный момент вместо названия - строковый ID торпеды
    [details addObject:@"Торпеда"];
    NSString* torpedoName = [self checkHardTextForNull:[torpedoBombers objectForKey:@"torpedo_name"]];
    [details addObject:torpedoName];
    
    
    [details addObject:@"Дальность пуска "];
    NSString* distanceString = [self checkForNull:[torpedoBombers objectForKey:@"distance"]];
    
    if ([distanceString isEqual:@"NA"]) {
        [details addObject:distanceString];
        
    } else {
        float distance = [distanceString floatValue];
        [details addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
    }
    
    return details;
}


- (NSMutableArray*) parseDiveBombersModule:(NSDictionary*)diveBombers {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Крейсерская скорость"];
    NSString* speed = [self checkForNull:[diveBombers objectForKey:@"cruise_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", speed]];
    
    
    [details addObject:@"Боеспособность (здоровье)"];
    NSString* health = [self checkForNull:[diveBombers objectForKey:@"max_health"]];
    [details addObject:health];
    
    
    [details addObject:@"Максимальный урон бомбой"];
    NSString* maxDamage = [self checkForNull:[diveBombers objectForKey:@"max_damage"]];
    [details addObject:maxDamage];
    
    
    [details addObject:@"Шанс пожара при попадании"];
    NSString* burnProb = [diveBombers objectForKey:@"bomb_burn_probability"];
    [details addObject:[NSString stringWithFormat:@"%@%%", burnProb]];
    
    
    [details addObject:@"Точность бомбометания"];
    NSDictionary* accuracyRange = [diveBombers objectForKey:@"accuracy"];
    
    float accuracyMin = [[accuracyRange objectForKey:@"min"] floatValue];
    float accuracyMax = [[accuracyRange objectForKey:@"max"] floatValue];
    
    if (accuracyMin == 0.f && accuracyMax == 0.f) {
        [details addObject:@"NA"];
        
    } else {
        [details addObject:[NSString stringWithFormat:@"%1.1f - %1.1f", accuracyMin, accuracyMax]];
        
    }
    
    return details;
}


#pragma mark - Upgrade

- (void) upgrade:(Upgrade*)upgrade fillWithResponse:(NSDictionary*)response forShip:(Ship*)ship {
    
    [self upgrade:upgrade addShip:ship];
    
    upgrade.upgradeID = [[response objectForKey:@"upgrade_id"] stringValue];
    
    NSString* nameString = [response objectForKey:@"name"];
    NSArray* nameComponents = [nameString componentsSeparatedByString:@"Модификация"];
    
    upgrade.name = [nameComponents firstObject];
    upgrade.mode = [[nameComponents lastObject] intValue];
    
    upgrade.price = [[response objectForKey:@"price"] intValue];
    
    upgrade.type = [response objectForKey:@"type"];
    upgrade.review = [response objectForKey:@"description"];
    
    upgrade.imageString = [response objectForKey:@"image"];
    
    upgrade.refreshDate = [ServerManager sharedManager].currentDate;
    
    NSMutableArray* stats;
    NSDictionary* uprgadeInfo = [[response objectForKey:@"profile"] objectForKey:upgrade.type];
    
    if ([upgrade.type isEqualToString:@"powder"]) {
        stats = [self parsePowderUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"steering"]) {
        stats = [self parseSteeringUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"guidance"]) {
        stats = [self parseGuidanceUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"damage_control"]) {
        stats = [self parseDamageControlUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"mainweapon"]) {
        stats = [self parseMainWeaponUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"secondweapon"]) {
        stats = [self parseSecondWeaponUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"artillery"]) {
        stats = [self parseArtilleryUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"engine"]) {
        stats = [self parseEngineUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"anti_aircraft"]) {
        stats = [self parseAntiAircraftUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"flight_control"]) {
        stats = [self parseFlightControlUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"planes"]) {
        stats = [self parsePlanesUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"atba"]) {
        stats = [self parseAtbaUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"concealment"]) {
        stats = [self parseConcealmentUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"spotting"]) {
        stats = [self parseSpottingUpgrade:uprgadeInfo];
        
    } else if ([upgrade.type isEqualToString:@"torpedoes"]) {
        stats = [self parseTorpedoesUpgrade:uprgadeInfo];
    }
    
    NSArray* statsArray = [NSArray arrayWithArray:stats];
    upgrade.stats = [NSKeyedArchiver archivedDataWithRootObject:statsArray];
}


//// Соединение Апгрейда с Кораблем без повторов
- (void) upgrade:(Upgrade*)upgrade addShip:(Ship*)ship {
    
    if (![upgrade.ships containsObject:ship]) {
        [upgrade addShipsObject:ship];
    }
}


- (NSMutableArray*) parsePowderUpgrade:(NSDictionary*)powder {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Шанс взрыва погреба"];
    NSString* probString = [powder objectForKey:@"detonation_prob"];
    
    float prob = [probString floatValue] * 100.f ;
    [details addObject:[NSString stringWithFormat:@"-%1.0f%%", prob]];
    
    return details;
}


- (NSMutableArray*) parseSteeringUpgrade:(NSDictionary*)steering {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Скорость ремонта"];
    NSString* repairTime = [steering objectForKey:@"repair_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:repairTime sign:@"+"]];
    
    [details addObject:@"Шанс крит.повреждения"];
    NSString* critDamage = [steering objectForKey:@"critical_damage_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:critDamage sign:@"-"]];
    
    [details addObject:@"Скорость перекладки рулей"];
    NSString* rudderTime = [steering objectForKey:@"rudder_time_coef"];
    [details addObject:[self percentFloatOneMinusValue: rudderTime sign:@"+"]];
    
    return details;
}


- (NSMutableArray*) parseGuidanceUpgrade:(NSDictionary*)guidance {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Скорость поворота установок ГК"];
    NSString* artRotation = [guidance objectForKey:@"artillery_rotation_speed"];
    [details addObject:[self percentFloatValueMinusOne:artRotation sign:@"+"]];
    
    [details addObject:@"Кучность стрельбы орудий ГК"];
    NSString* artAccuracy = [guidance objectForKey:@"artillery_shoot_accuracy"];
    [details addObject:[self percentFloatOneMinusValue:artAccuracy sign:@"+"]];
    
    [details addObject:@"Дальность стрельбы орудий ПМК"];
    NSString* atbaDistance = [guidance objectForKey:@"atba_max_dist"];
    [details addObject:[self percentFloatValueMinusOne:atbaDistance sign:@"+"]];
    
    [details addObject:@"Скорость поворота орудий ПМК"];
    NSString* atbaRotation = [guidance objectForKey:@"atba_rotation_speed"];
    [details addObject:[self percentFloatValueMinusOne:atbaRotation sign:@"+"]];
    
    [details addObject:@"Кучность стрельбы орудий ПМК"];
    NSString* atbaAccuracy = [guidance objectForKey:@"atba_shoot_accuracy"];
    [details addObject:[self percentFloatOneMinusValue:atbaAccuracy sign:@"+"]];
    
    return details;
}


- (NSMutableArray*) parseDamageControlUpgrade:(NSDictionary*)damageControl {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Вероятность пожара"];
    NSString* fireChance = [damageControl objectForKey:@"fire_starting_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:fireChance sign:@"-"]];
    
    [details addObject:@"Скорость тушения пожара"];
    NSString* fireTime = [damageControl objectForKey:@"burning_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:fireTime sign:@"+"]];
    
    [details addObject:@"Вероятность затопления"];
    NSString* floodChance = [damageControl objectForKey:@"flood_starting_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:floodChance sign:@"-"]];
    
    [details addObject:@"Скорость устранения затопления"];
    NSString* floodTime = [damageControl objectForKey:@"flooding_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:floodTime sign:@"+"]];
    
    return details;
}


- (NSMutableArray*) parseMainWeaponUpgrade:(NSDictionary*)mainWeapon {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Шанс выхода из строя ГК"];
    NSString* artDamage = [mainWeapon objectForKey:@"artillery_damage_prob"];
    [details addObject:[self percentFloatOneMinusValue:artDamage sign:@"-"]];
    
    [details addObject:@"Живучесть ГК"];
    NSString* artHealth = [mainWeapon objectForKey:@"artillery_max_hp"];
    [details addObject:[self percentFloatValueMinusOne:artHealth sign:@"+"]];
    
    [details addObject:@"Время ремонта ГК"];
    NSString* artRepair = [mainWeapon objectForKey:@"artillery_repair_time"];
    [details addObject:[self percentFloatOneMinusValue:artRepair sign:@"-"]];
    
    [details addObject:@"Вероятность выхода из строя ТА"];
    NSString* torpDamage = [mainWeapon objectForKey:@"tpd_damage_prob"];
    [details addObject:[self percentFloatOneMinusValue:torpDamage sign:@"-"]];
    
    [details addObject:@"Живучесть ТА"];
    NSString* torpHealth = [mainWeapon objectForKey:@"tpd_max_hp"];
    [details addObject:[self percentFloatValueMinusOne:torpHealth sign:@"+"]];
    
    [details addObject:@"Время ремонта ТА"];
    NSString* torpRepair = [mainWeapon objectForKey:@"tpd_repair_time"];
    [details addObject:[self percentFloatOneMinusValue:torpRepair sign:@"-"]];
    
    return details;
}


- (NSMutableArray*) parseSecondWeaponUpgrade:(NSDictionary*)secondWeapon {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Живучесть установок ПМК"];
    NSString* atbaHealth = [secondWeapon objectForKey:@"atba_max_hp"];
    [details addObject:[self percentFloatValueMinusOne:atbaHealth sign:@"+"]];
    
    [details addObject:@"Живучесть установок ПВО"];
    NSString* aaHealth = [secondWeapon objectForKey:@"air_defense_max_hp"];
    [details addObject:[self percentFloatValueMinusOne:aaHealth sign:@"+"]];
    
    return details;
}


- (NSMutableArray*) parseArtilleryUpgrade:(NSDictionary*)artillery {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Шанс крит.повреждения погреба боеприпасов"];
    NSString* ammoCritChance = [artillery objectForKey:@"ammo_critical_damage_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:ammoCritChance sign:@"-"]];
    
    [details addObject:@"Шанс взрыва погреба боеприпасов"];
    NSString* detonChance = [artillery objectForKey:@"ammo_detonation_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:detonChance sign:@"-"]];
    
    [details addObject:@"Скорость ремонта погреба боеприпасов"];
    NSString* ammoRepairTime = [artillery objectForKey:@"ammo_repair_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:ammoRepairTime sign:@"+"]];
    
    [details addObject:@"Шанс крит.повреждения установки ГК"];
    NSString* artCritChance = [artillery objectForKey:@"critical_damage_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:artCritChance sign:@"-"]];
    
    [details addObject:@"Время перезарядки ГК"];
    NSString* reloadTime = [artillery objectForKey:@"reload_time_coef"];
    [details addObject:[self percentFloatValueMinusOne:reloadTime sign:@"+"]];
    
    [details addObject:@"Скорость ремонта ГК"];
    NSString* artRepairTime = [artillery objectForKey:@"repair_time_coef"];
    [details addObject:[self percentFloatValueMinusOne:artRepairTime sign:@"+"]];
    
    [details addObject:@"Скорость наведения башен ГК"];
    NSString* rotationTime = [artillery objectForKey:@"rotation_time_coef"];
    [details addObject:[self percentFloatValueMinusOne:rotationTime sign:@"+"]];
    
    return details;
}


- (NSMutableArray*) parseEngineUpgrade:(NSDictionary*)engine {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Время набора максимальной скорости вперед"];
    NSString* maxForward = [engine objectForKey:@"max_forward_power_coef"];
    [details addObject:[self percentFloatOneMinusValue:maxForward sign:@"-"]];
    
    [details addObject:@"Время набора максимальной скорости назад"];
    NSString* maxBackfard = [engine objectForKey:@"max_backward_power_coef"];
    [details addObject:[self percentFloatOneMinusValue:maxBackfard sign:@"-"]];
    
    [details addObject:@"Шанс крит.повреждения"];
    NSString* critChance = [engine objectForKey:@"critical_damage_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:critChance sign:@"-"]];
    
    [details addObject:@"Время ремонта"];
    NSString* repairTime = [engine objectForKey:@"repair_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:repairTime sign:@"-"]];
    
    return details;
}



- (NSMutableArray*) parseAntiAircraftUpgrade:(NSDictionary*)antiAircraft {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Дальность стрельбы ПВО"];
    NSString* distance = [antiAircraft objectForKey:@"distance_coef"];
    [details addObject:[self percentFloatValueMinusOne:distance sign:@"+"]];
    
    [details addObject:@"Эффективность ПВО"];
    NSString* efficiency = [antiAircraft objectForKey:@"efficiency_coef"];
    [details addObject:[self percentFloatValueMinusOne:efficiency sign:@"+"]];
    
    [details addObject:@"Живучесть установок ПВО"];
    NSString* heath = [antiAircraft objectForKey:@"health_coef"];
    [details addObject:[self percentFloatValueMinusOne:heath sign:@"+"]];
    
    return details;
}


- (NSMutableArray*) parseFlightControlUpgrade:(NSDictionary*)flightControl {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Время подготовки самолетов"];
    NSString* time = [flightControl objectForKey:@"prepare_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:time sign:@"-"]];
    
    [details addObject:@"Скорость самолетов"];
    NSString* speed = [flightControl objectForKey:@"speed_coef"];
    [details addObject:[self percentFloatValueMinusOne:speed sign:@"+"]];
    
    return details;
}


- (NSMutableArray*) parsePlanesUpgrade:(NSDictionary*)planes {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Живучесть истребителей"];
    NSString* fighterHealth = [planes objectForKey:@"fighter_health_coef"];
    [details addObject:[self percentFloatValueMinusOne:fighterHealth sign:@"+"]];
    
    [details addObject:@"Живучесть бомбардировщиков"];
    NSString* bomberHealth = [planes objectForKey:@"bomber_health_coef"];
    [details addObject:[self percentFloatValueMinusOne:bomberHealth sign:@"+"]];
    
    [details addObject:@"Эффективность стрелкового вооружения"];
    NSString* efficiency = [planes objectForKey:@"efficiency_coef"];
    [details addObject:[self percentFloatValueMinusOne:efficiency sign:@"+"]];
    
    return details;
}


- (NSMutableArray*) parseAtbaUpgrade:(NSDictionary*)atba {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Кучность стрельбы ПМК"];
    NSString* accuracy = [atba objectForKey:@"accuracy_coef"];
    [details addObject:[self percentFloatOneMinusValue:accuracy sign:@"+"]];
    
    [details addObject:@"Дальность стрельбы ПМК"];
    NSString* distance = [atba objectForKey:@"distance_coef"];
    [details addObject:[self percentFloatValueMinusOne:distance sign:@"+"]];
    
    [details addObject:@"Живучесть установок ПМК"];
    NSString* health = [atba objectForKey:@"health_coef"];
    [details addObject:[self percentFloatValueMinusOne:health sign:@"+"]];
    
    [details addObject:@"Время перезарядки ПМК"];
    NSString* reloadTime = [atba objectForKey:@"reload_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:reloadTime sign:@"-"]];
    
    return details;
}


- (NSMutableArray*) parseConcealmentUpgrade:(NSDictionary*)concealment {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Заметность"];
    NSString* detectDist = [concealment objectForKey:@"detect_distance_coef"];
    [details addObject:[self percentFloatOneMinusValue:detectDist sign:@"-"]];
    
    return details;
}


- (NSMutableArray*) parseSpottingUpgrade:(NSDictionary*)spotting {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Дальность обнаружения"];
    NSString* spotDist = [spotting objectForKey:@"spot_distance_coef"];
    [details addObject:[self percentFloatValueMinusOne:spotDist sign:@"+"]];
    
    return details;
}


- (NSMutableArray*) parseTorpedoesUpgrade:(NSDictionary*)torpedoes {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Шанс крит.повреждения ТА"];
    NSString* critChance = [torpedoes objectForKey:@"critical_damage_chance_coef"];
    [details addObject:[self percentFloatValueMinusOne:critChance sign:@"+"]];
    
    [details addObject:@"Время перезарядки"];
    NSString* reloadTime = [torpedoes objectForKey:@"reload_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:reloadTime sign:@"-"]];
    
    [details addObject:@"Время ремонта ТА"];
    NSString* repairTime = [torpedoes objectForKey:@"repair_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:repairTime sign:@"-"]];
    
    [details addObject:@"Скорость поворота ТА"];
    NSString* rotationTime = [torpedoes objectForKey:@"rotation_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:rotationTime sign:@"-"]];
    
    return details;
}


- (NSString*) percentFloatValueMinusOne:(NSString*)value sign:(NSString*)sign {
    
    NSString* checkedValue = [self checkForNull:value];
    
    if ([checkedValue isEqual:@"NA"]) {
        return checkedValue;
        
    } else {
        float percent = ([checkedValue floatValue] - 1.f) * 100.f;
        
        if (percent < 0.f) {
            return [NSString stringWithFormat:@"%1.0f%%", percent];
            
        } else {
            return [NSString stringWithFormat:@"%@%1.0f%%", sign, percent];
        }
    }
}


- (NSString*) percentFloatOneMinusValue:(NSString*)value sign:(NSString*)sign {
    
    NSString* checkedValue = [self checkForNull:value];
    
    if ([checkedValue isEqual:@"NA"]) {
        return checkedValue;
        
    } else {
        float percent = (1.f - [checkedValue floatValue]) * 100.f;
        
        if (percent < 0.f) {
            return [NSString stringWithFormat:@"%1.0f%%", percent];
            
        } else {
            return [NSString stringWithFormat:@"%@%1.0f%%", sign, percent];
        }
    }
}


#pragma mark - Checking

//// Метка пустой строки для значения, которое не может быть нулевым. Проверяется при отображении детального инфо
- (NSString*) checkForNull:(id)value {
    if ([value isKindOfClass:[NSNull class]]) {
        return @"NA";
        
    } else if ([value isEqual:@"0"] || value == nil || ([value integerValue] == 0 && [value floatValue] == 0.f)) {
        return @"NA";
        
    } else {
        
        if ([value isKindOfClass:[NSNumber class]]) {
            value = [value stringValue];
        } else {
            value = (NSString*)value;
        }
        return value;
    }
}


//// Проверка строк названий (буквы + цифры + символы)
- (NSString*) checkHardTextForNull:(id)value {
    if ([value isKindOfClass:[NSNull class]] || value == nil) {
        return @"NA";
        
    } else {
        
        if ([value isKindOfClass:[NSNumber class]]) {
            value = [value stringValue];
        } else {
            value = (NSString*)value;
        }
        return value;
    }
}

@end
