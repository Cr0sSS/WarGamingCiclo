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

+ (ParsingManager*)sharedManager {
    
    static ParsingManager* manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ParsingManager alloc] init];
    });
    
    return manager;
}


#pragma mark - Nation

- (void)nation:(Nation*)nation fillWithName:(NSString*)name andID:(NSString*)nationID {
    
    nation.nationID = nationID;
    nation.name = name;
    nation.refreshDate = [ServerManager sharedManager].currentDate;
}


#pragma mark - ShipType

- (void)shipType:(ShipType*)type fillWithID:(NSString*)typeID name:(NSString*)name imagesDict:(NSDictionary*)imagesDict {
    
    type.typeID = typeID;
    type.name = name;
    type.refreshDate = [ServerManager sharedManager].currentDate;
    
    if (imagesDict) {
        type.imageString = imagesDict[@"image"];
        type.premiumImageString = imagesDict[@"image_premium"];
        type.eliteImageString = imagesDict[@"image_elite"];
    }
}


#pragma mark - Ship

- (void)ship:(Ship*)ship fillWithID:(NSString*)shipID details:(NSDictionary*)dict {
    
    ship.shipID = shipID;
    ship.name = dict[@"name"];
    
    ship.type = [[DataManager sharedManager] getShipTypeWithID:dict[@"type"]];
    ship.nation = [[DataManager sharedManager] getNationWithID:dict[@"nation"]];
    
    ship.tier = [dict[@"tier"] integerValue];
    ship.isPremium = [dict[@"is_premium"] boolValue];
    
    NSDictionary* images = dict[@"images"];
    
    ship.contourImageString = images[@"contour"];
    ship.smallImageString = images[@"small"];
    ship.mediumImageString = images[@"medium"];
    ship.largeImageString = images[@"large"];
    
    ship.refreshDate = [ServerManager sharedManager].currentDate;
}


- (void)ship:(Ship*)ship parseFullDetailResponse:(NSDictionary*)dict {
    
    ship.modSlots = [dict[@"mod_slots"] integerValue];
    ship.review = dict[@"description"];
    
    //// ID всех модулей корабля
    NSArray* moduleGroups = [dict[@"modules"] allValues];
    NSMutableArray* moduleIDs = [NSMutableArray new];
    
    for (NSArray* group in moduleGroups) {
        for (id moduleID in group) {
            
            NSString* stringID = [moduleID stringValue];
            [moduleIDs addObject:stringID];
        }
    }
    ship.moduleIDs = [NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:moduleIDs]];
    
    
    //// ID всех апгрейдов корабля
    NSArray* upgrades = dict[@"upgrades"];
    NSMutableArray* upgradeStrings = [NSMutableArray new];
    
    for (id upgradeID in upgrades) {
        NSString* stringID = [upgradeID stringValue];
        [upgradeStrings addObject:stringID];
    }
    ship.upgradeIDs = [NSKeyedArchiver archivedDataWithRootObject:upgradeStrings];
    
    
    NSDictionary* defaultProfile = dict[@"default_profile"];
    
    ship.battleRangeMin = [defaultProfile[@"battle_level_range_min"] integerValue];
    ship.battleRangeMax = [defaultProfile[@"battle_level_range_max"] integerValue];
    
    //// Секция "Основные характеристики"
    NSArray* mainStatsArray = [NSArray arrayWithArray:[self parseMainStats:dict ofShip:ship]];
    ship.mainStats = [NSKeyedArchiver archivedDataWithRootObject:mainStatsArray];
    
    
    //// Секция "Маневренность"
    NSDictionary* mobility = defaultProfile[@"mobility"];
    
    if (![mobility isKindOfClass:[NSNull class]]) {
        
        NSArray* mobilityArray = [NSArray arrayWithArray:[self parseMobility:mobility]];
        ship.mobility = [NSKeyedArchiver archivedDataWithRootObject:mobilityArray];
    }
    
    
    //// Секция "Маскировка"
    NSDictionary* concealment = defaultProfile[@"concealment"];
    
    if (![concealment isKindOfClass:[NSNull class]]) {
        
        NSArray* concealmentArray = [NSArray arrayWithArray:[self parseConcealment:concealment]];
        ship.concealment = [NSKeyedArchiver archivedDataWithRootObject:concealmentArray];
    }
    
    
    //// Секция "ПВО"
    NSDictionary* antiAircraft = defaultProfile[@"anti_aircraft"];
    
    if (![antiAircraft isKindOfClass:[NSNull class]]) {
        
        NSArray* antiAircraftArray = [NSArray arrayWithArray:[self parseAntiAircraft:antiAircraft]];
        ship.antiAircraft = [NSKeyedArchiver archivedDataWithRootObject:antiAircraftArray];
    }
    
    
    //// Секция "Торпедное вооружение"
    NSDictionary* torpedoes = defaultProfile[@"torpedoes"];
    
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
    NSDictionary* artillery = defaultProfile[@"artillery"];
    
    if (![artillery isKindOfClass:[NSNull class]]) {
        
        NSArray* artilleryArray = [NSArray arrayWithArray:[self parseMainBattery:artillery]];
        ship.mainBattery = [NSKeyedArchiver archivedDataWithRootObject:artilleryArray];
    }
    
    
    //// Секция "Вспомогательный калибр"
    NSDictionary* atbas = defaultProfile[@"atbas"];
    
    if (![atbas isKindOfClass:[NSNull class]]) {
        
        NSArray* atbasArray = [NSArray arrayWithArray:[self parseAdditionalBattery:atbas]];
        ship.additionalBattery = [NSKeyedArchiver archivedDataWithRootObject:atbasArray];
    }
    
    ship.detailsRefreshDate = [ServerManager sharedManager].currentDate;
}


- (NSMutableArray*)parseMainStats:(NSDictionary*)dict ofShip:(Ship*)ship {
    
    NSDictionary* defaultProfile = dict[@"default_profile"];
    
    NSMutableArray* mainStatsArray = [NSMutableArray new];
    
    NSDictionary* hull = defaultProfile[@"hull"];
    NSDictionary* armour = defaultProfile[@"armour"];
    
    
    [mainStatsArray addObject:@"Стоимость исследования"];
    
    if (ship.isPremium) {
        [mainStatsArray addObject:@"премиумный"];
        
    } else {
        [mainStatsArray addObject:@"неизвестна"]; // стоимость исследования техники не выдается через API (16.01.2017)
    }
    
    
    [mainStatsArray addObject:@"Цена покупки"];
    
    if (ship.isPremium) {
        NSString* price = dict[@"price_gold"];
        [mainStatsArray addObject:[NSString stringWithFormat:@"%@ золота", price]];
        
    } else {
        NSString* price = [dict[@"price_credit"] stringValue];
        
        if ([price isEqual:@"0"]) {
            [mainStatsArray addObject:@"неизвестна"];
        } else {
            [mainStatsArray addObject:[NSString stringWithFormat:@"%@ серебра", price]];
        }
    }
    
    
    [mainStatsArray addObject:@"Уровни боев"];
    [mainStatsArray addObject:[NSString stringWithFormat:@"%hd - %hd", ship.battleRangeMin, ship.battleRangeMax]];
    
    
    [mainStatsArray addObject:@"Боеспособность(здоровье)"];
    NSInteger healh = [hull[@"health"] integerValue];
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
        [mainStatsArray addObject:armourPartNames[i]];
        
        NSDictionary* armourPart = armour[armourPartKeys[i]];
        [mainStatsArray addObject:[self armourRelease:armourPart]];
    }
    
    
    [mainStatsArray addObject:@"Снижение вероятности затопления"];
    NSString* floodProb = [self checkForNull:armour[@"flood_prob"]];
    [mainStatsArray addObject:[NSString stringWithFormat:@"%@%%", floodProb]];
    
    
    [mainStatsArray addObject:@"Снижение урона от затопления"];
    NSString* floodDamage = [self checkForNull:armour[@"flood_damage"]];
    [mainStatsArray addObject:[NSString stringWithFormat:@"%@%%", floodDamage]];
    
    return mainStatsArray;
}


- (NSMutableArray*)parseMobility:(NSDictionary*)mobility {
    
    NSMutableArray* mobilityArray = [NSMutableArray new];
    
    [mobilityArray addObject:@"Показатель маневренности"];
    NSString* total = [self checkForNull:mobility[@"total"]];
    [mobilityArray addObject:[NSString stringWithFormat:@"%@%%", total]];
    
    
    [mobilityArray addObject:@"Максимальная скорость"];
    NSString* speedValue = [self checkForNull:mobility[@"max_speed"]];
    
    if ([speedValue isEqual:@"NA"]) {
        [mobilityArray addObject:speedValue];
        
    } else {
        float speed = [speedValue floatValue];
        [mobilityArray addObject:[NSString stringWithFormat:@"%1.2f уз", speed]];
    }
    
    
    [mobilityArray addObject:@"Время перекладки руля"];
    NSString* rudderValue = [self checkForNull:mobility[@"rudder_time"]];
    
    if ([rudderValue isEqual:@"NA"]) {
        [mobilityArray addObject:rudderValue];
        
    } else {
        float rudderTime = [rudderValue floatValue];
        [mobilityArray addObject:[NSString stringWithFormat:@"%1.1f сек", rudderTime]];
    }
    
    
    [mobilityArray addObject:@"Радиус разворота"];
    NSString* radius = [self checkForNull:mobility[@"turning_radius"]];
    [mobilityArray addObject:[NSString stringWithFormat:@"%@ м", radius]];
    
    return mobilityArray;
}


- (NSMutableArray*)parseTorpedoes:(NSDictionary*)torpedoes {
    
    NSMutableArray* torpedoesArray = [NSMutableArray new];
    NSArray* slots = [torpedoes[@"slots"] allObjects];
    
    NSInteger torpedoGuns = 0;
    NSInteger torpedoBarrels = 0;
    
    
    for (NSDictionary* slot in slots) {
        NSInteger gunsInSlot = [slot[@"guns"] integerValue];
        torpedoGuns = torpedoGuns + gunsInSlot;
        torpedoBarrels = torpedoBarrels + [slot[@"barrels"] integerValue] * gunsInSlot;
    }
    
    [torpedoesArray addObject:torpedoes[@"torpedo_name"]];
    [torpedoesArray addObject:[NSString stringWithFormat:@"Установки: %ld; всего труб: %ld", torpedoGuns, torpedoBarrels]];
    
    
    NSString* reloadTimeString = [self checkForNull:torpedoes[@"reload_time"]];
    [torpedoesArray addObject:@"Скорострельность"];
    
    if ([reloadTimeString isEqual:@"NA"]) {
        [torpedoesArray addObject:reloadTimeString];
        
    } else {
        float rof = 60.f / [reloadTimeString floatValue];
        [torpedoesArray addObject:[NSString stringWithFormat:@"%1.2f выст/мин", rof]];
    }
    
    
    [torpedoesArray addObject:@"Время перезарядки"];
    [torpedoesArray addObject:[NSString stringWithFormat:@"%@ сек", reloadTimeString]];
    
    
    NSString* rotationTimeString = [self checkForNull:torpedoes[@"rotation_time"]];
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
        NSString* name = [self checkForNull:slot[@"name"]];
        [torpedoesArray addObject:name];
        
        
        [torpedoesArray addObject:@"Калибр"];
        NSString* caliber = [self checkForNull:slot[@"caliber"]];
        [torpedoesArray addObject:[NSString stringWithFormat:@"%@ мм", caliber]];
    }
    
    
    [torpedoesArray addObject:@"Максимальный урон"];
    NSString* damage = [self checkForNull:torpedoes[@"max_damage"]];
    [torpedoesArray addObject:damage];
    
    
    [torpedoesArray addObject:@"Скорость хода торпед"];
    NSString* speed = [self checkForNull:torpedoes[@"torpedo_speed"]];
    [torpedoesArray addObject:[NSString stringWithFormat:@"%@ уз", speed]];
    
    
    [torpedoesArray addObject:@"Дальность хода торпед"];
    NSString* distanceString = [self checkForNull:torpedoes[@"distance"]];
    
    if ([distanceString isEqual:@"NA"]) {
        [torpedoesArray addObject:distanceString];
        
    } else {
        float distance = [distanceString floatValue];
        [torpedoesArray addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
    }
    
    
    [torpedoesArray addObject:@"Дальность обнаружения торпед"];
    NSString* visDistanceString = [self checkForNull:torpedoes[@"visibility_dist"]];
    
    if ([visDistanceString isEqual:@"NA"]) {
        [torpedoesArray addObject:visDistanceString];
        
    } else {
        float visDistance = [visDistanceString floatValue];
        [torpedoesArray addObject:[NSString stringWithFormat:@"%1.1f км", visDistance]];
    }
    
    return torpedoesArray;
}


- (NSMutableArray*)parseAirGroup:(NSDictionary*)defaultProfile {
    
    NSMutableArray* airGroupArray = [NSMutableArray new];
    
    [airGroupArray addObject:@"Вместимость ангара"];
    NSString* planesCount = [self checkForNull:defaultProfile[@"hull"][@"planes_amount"]];
    [airGroupArray addObject:[NSString stringWithFormat:@"%@ шт", planesCount]];
    
    
    NSDictionary* fighters = defaultProfile[@"fighters"];
    if (![fighters isKindOfClass:[NSNull class]]) {
        
        [airGroupArray addObject:@"Истребители"];
        [airGroupArray addObject:[self checkHardTextForNull:fighters[@"name"]]];
        
        [airGroupArray addObjectsFromArray:[self parcePlaneType:fighters]];
    }
    
    
    NSDictionary* torpedoBombers = defaultProfile[@"torpedo_bomber"];
    if (![torpedoBombers isKindOfClass:[NSNull class]]) {
        
        [airGroupArray addObject:@"Торпедоносцы"];
        [airGroupArray addObject:[self checkHardTextForNull:torpedoBombers[@"name"]]];
        
        [airGroupArray addObjectsFromArray:[self parcePlaneType:torpedoBombers]];
    }
    
    
    NSDictionary* diveBombers = defaultProfile[@"torpedo_bomber"];
    if (![diveBombers isKindOfClass:[NSNull class]]) {
        
        [airGroupArray addObject:@"Бомбардировщики"];
        [airGroupArray addObject:[self checkHardTextForNull:diveBombers[@"name"]]];
        
        [airGroupArray addObjectsFromArray:[self parcePlaneType:diveBombers]];
    }
    
    return airGroupArray;
}


- (NSMutableArray*)parseConcealment:(NSDictionary*)concealment {
    
    NSMutableArray* concealmentArray = [NSMutableArray new];
    
    [concealmentArray addObject:@"Показатель маскировки"];
    NSString* total = [self checkForNull:concealment[@"total"]];
    [concealmentArray addObject:[NSString stringWithFormat:@"%@%%", total]];
    
    
    [concealmentArray addObject:@"Дальность обнаружения с кораблей"];
    NSString* distanceShipValue = [self checkForNull:concealment[@"detect_distance_by_ship"]];
    
    if ([distanceShipValue isEqual:@"NA"]) {
        [concealmentArray addObject:distanceShipValue];
        
    } else {
        float distanceShip = [distanceShipValue floatValue];
        [concealmentArray addObject:[NSString stringWithFormat:@"%1.1f км", distanceShip]];
    }
    
    
    [concealmentArray addObject:@"Дальность обнаружения с самолетов"];
    NSString* distancePlaneValue = [self checkForNull:concealment[@"detect_distance_by_plane"]];
    
    if ([distancePlaneValue isEqual:@"NA"]) {
        [concealmentArray addObject:distancePlaneValue];
        
    } else {
        float distancePlane = [distancePlaneValue floatValue];
        [concealmentArray addObject:[NSString stringWithFormat:@"%1.1f км", distancePlane]];
    }
    
    return concealmentArray;
}


- (NSMutableArray*)parseMainBattery:(NSDictionary*)artillery {
    
    NSMutableArray* mainBatteryArray = [NSMutableArray new];
    
    NSArray* artillerySlots = [artillery[@"slots"] allObjects];
    for (NSDictionary* slot in artillerySlots) {
        
        [mainBatteryArray addObject:slot[@"name"]];
        NSString* slotsGuns = [slot[@"guns"] stringValue];
        NSString* slotsBarrels = [slot[@"barrels"] stringValue];
        [mainBatteryArray addObject:[NSString stringWithFormat:@"Установки: %@; стволов в каждой: %@", slotsGuns, slotsBarrels]];
    }
    
    
    [mainBatteryArray addObject:@"Скорострельность"];
    NSString* rofValue = [self checkForNull:artillery[@"gun_rate"]];
    
    if ([rofValue isEqual:@"NA"]) {
        [mainBatteryArray addObject:rofValue];
        
    } else {
        float rof = [rofValue floatValue];
        [mainBatteryArray addObject:[NSString stringWithFormat:@"%1.2f выстр/сек", rof]];
    }
    
    
    [mainBatteryArray addObject:@"Дальность стрельбы"];
    NSString* distanceValue = [self checkForNull:artillery[@"distance"]];
    
    if ([distanceValue isEqual:@"NA"]) {
        [mainBatteryArray addObject:distanceValue];
        
    } else {
        float distance = [distanceValue floatValue];
        [mainBatteryArray addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
    }
    
    
    [mainBatteryArray addObject:@"Время перезарядки"];
    NSString* reloadValue = [self checkForNull:artillery[@"shot_delay"]];
    
    if ([reloadValue isEqual:@"NA"]) {
        [mainBatteryArray addObject:reloadValue];
        
    } else {
        float reload = [reloadValue floatValue];
        [mainBatteryArray addObject:[NSString stringWithFormat:@"%1.2f сек", reload]];
    }
    
    
    [mainBatteryArray addObject:@"Время поворота на 180 градусов"];
    NSString* rotationTime = [self checkForNull:artillery[@"rotation_time"]];
    [mainBatteryArray addObject:[NSString stringWithFormat:@"%@ сек", rotationTime]];
    
    
    [mainBatteryArray addObject:@"Скорость горизонтального наведения"];
    NSString* gunRate = [self checkForNull:artillery[@"gun_rate"]];
    
    if ([gunRate isEqual:@"NA"]) {
        [mainBatteryArray addObject:gunRate];
        
    } else {
        float rate = [gunRate floatValue];
        [mainBatteryArray addObject:[NSString stringWithFormat:@"%1.1f гр./сек", rate]];
    }
    
    
    [mainBatteryArray addObject:@"Максимальное рассеивание"];
    NSString* dispersion = [self checkForNull:artillery[@"max_dispersion"]];
    [mainBatteryArray addObject:[NSString stringWithFormat:@"%@ м", dispersion]];
    
    
    NSArray* shellsArray = [artillery[@"shells"] allObjects];
    
    for (NSDictionary* shell in shellsArray) {
        NSString* shellType;
        
        if (shell && ![shell isKindOfClass:[NSNull class]]) {
            if ([shell[@"type"] isEqual:@"AP"]) {
                shellType = @"ББ";
                
            } else if ([shell[@"type"] isEqual:@"HE"]) {
                shellType = @"ОФ";
            }
            
            [mainBatteryArray addObject:[NSString stringWithFormat:@"%@ снаряд", shellType]];
            NSString* shellName = [self checkForNull:shell[@"name"]];
            [mainBatteryArray addObject:shellName];
            
            
            [mainBatteryArray addObject:[NSString stringWithFormat:@"Максимальный урон %@ снаряда", shellType]];
            NSString* shellDamage = [self checkForNull:shell[@"damage"]];
            [mainBatteryArray addObject:shellDamage];
            
            
            [mainBatteryArray addObject:[NSString stringWithFormat:@"Вероятность пожара от %@ снаряда", shellType]];
            NSString* shellBurn = [self checkForNull:shell[@"burn_probability"]];
            [mainBatteryArray addObject:[NSString stringWithFormat:@"%@%%", shellBurn]];
            
            
            [mainBatteryArray addObject:[NSString stringWithFormat:@"Начальная скорость %@ снаряда", shellType]];
            NSString* shellSpeed = [self checkForNull:shell[@"bullet_speed"]];
            [mainBatteryArray addObject:[NSString stringWithFormat:@"%@ м/сек", shellSpeed]];
            
            
            [mainBatteryArray addObject:[NSString stringWithFormat:@"Масса %@ снаряда", shellType]];
            NSString* shellMass = [self checkForNull:shell[@"bullet_mass"]];
            [mainBatteryArray addObject:[NSString stringWithFormat:@"%@ кг", shellMass]];
        }
    }
    return mainBatteryArray;
}


- (NSMutableArray*)parseAdditionalBattery:(NSDictionary*)atbas {
    
    NSMutableArray* additionalBatteryArray = [NSMutableArray new];
    
    NSArray* artillerySlots = [atbas[@"slots"] allObjects];
    
    for (NSDictionary* slot in artillerySlots) {
        
        NSMutableArray* battery = [NSMutableArray new];
        
        [battery addObject:@"Дальность стрельбы"];
        NSString* distanceValue = [self checkForNull:atbas[@"distance"]];
        
        if ([distanceValue isEqual:@"NA"]) {
            [battery addObject:distanceValue];
            
        } else {
            float distance = [distanceValue floatValue];
            [battery addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
        }
        
        
        [battery addObject:@"Скорость горизонтального наведения"];
        NSString* gunRate = [self checkForNull:slot[@"gun_rate"]];
        
        if ([gunRate isEqual:@"NA"]) {
            [battery addObject:gunRate];
            
        } else {
            float rate = [gunRate floatValue];
            [battery addObject:[NSString stringWithFormat:@"%1.1f гр/сек", rate]];
        }
        
        
        [battery addObject:@"Время перезарядки"];
        NSString* reloadValue = [self checkForNull:slot[@"shot_delay"]];
        
        if ([reloadValue isEqual:@"NA"]) {
            [battery addObject:reloadValue];
            
        } else {
            float reload = [reloadValue floatValue];
            [battery addObject:[NSString stringWithFormat:@"%1.2f сек", reload]];
        }
        
        NSString* shellType;
        if ([slot[@"type"] isEqual:@"AP"]) {
            shellType = @"ББ";
            
        } else if ([slot[@"type"] isEqual:@"HE"]) {
            shellType = @"ОФ";
        }
        
        [battery addObject:[NSString stringWithFormat:@"%@ снаряд", shellType]];
        NSString* shellName = [self checkForNull:slot[@"name"]];
        [battery addObject:shellName];
        
        
        [battery addObject:[NSString stringWithFormat:@"Максимальный урон %@ снаряда", shellType]];
        NSString* shellDamage = [self checkForNull:slot[@"damage"]];
        [battery addObject:shellDamage];
        
        
        [battery addObject:[NSString stringWithFormat:@"Вероятность пожара от %@ снаряда", shellType]];
        NSString* shellBurn = [self checkForNull:slot[@"burn_probability"]];
        [battery addObject:[NSString stringWithFormat:@"%@%%", shellBurn]];
        
        
        [battery addObject:[NSString stringWithFormat:@"Начальная скорость %@ снаряда", shellType]];
        NSString* shellSpeed = [self checkForNull:slot[@"bullet_speed"]];
        [battery addObject:[NSString stringWithFormat:@"%@ м/сек", shellSpeed]];
        
        
        [battery addObject:[NSString stringWithFormat:@"Масса %@ снаряда", shellType]];
        NSString* shellMass = [self checkForNull:slot[@"bullet_mass"]];
        [battery addObject:[NSString stringWithFormat:@"%@ кг", shellMass]];
        
        [additionalBatteryArray addObject:battery];
    }
    
    return additionalBatteryArray;
}


- (NSMutableArray*)parseAntiAircraft:(NSDictionary*)antiAircraft {
    
    NSMutableArray* antiAircraftArray = [NSMutableArray new];
    
    [antiAircraftArray addObject:@"Эффективность ПВО"];
    NSString* defenseValue = [self checkForNull:antiAircraft[@"defense"]];
    [antiAircraftArray addObject:[NSString stringWithFormat:@"%@%%", defenseValue]];
    
    
    NSArray* slots = [antiAircraft[@"slots"] allValues];
    for (NSDictionary* slot in slots) {
        
        [antiAircraftArray addObject:slot[@"name"]];
        NSString* guns = [self checkForNull:slot[@"guns"]];
        [antiAircraftArray addObject:[NSString stringWithFormat:@"%@ шт", guns]];
        
        
        [antiAircraftArray addObject:@"....калибр"];
        NSString* caliber = [self checkForNull:slot[@"caliber"]];
        [antiAircraftArray addObject:[NSString stringWithFormat:@"%@ мм", caliber]];
        
        
        [antiAircraftArray addObject:@"....средний урон в секунду"];
        NSString* damage = [self checkForNull:slot[@"avg_damage"]];
        [antiAircraftArray addObject:damage];
        
        
        [antiAircraftArray addObject:@"....дальность стрельбы"];
        NSString* distanceValue = [self checkForNull:slot[@"distance"]];
        
        if ([distanceValue isEqual:@"NA"]) {
            [antiAircraftArray addObject:distanceValue];
            
        } else {
            float distance = [distanceValue floatValue];
            [antiAircraftArray addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
        }
    }
    return antiAircraftArray;
}


- (NSMutableArray*)parcePlaneType:(NSDictionary*)planeType {
    
    NSMutableArray* typeArray = [NSMutableArray new];
    
    [typeArray addObject:@"....уровень"];
    [typeArray addObject:[self checkForNull:planeType[@"plane_level"]]];
    
    [typeArray addObject:@"....самолетов в ангаре"];
    NSString* squads = [self checkHardTextForNull:planeType[@"squadrons"]];
    NSString* planesInSquad = [self checkHardTextForNull:planeType[@"count_in_squadron"][@"max"]];
    
    if ([squads isEqual:@"NA"] && [planesInSquad isEqual:@"NA"]) {
        [typeArray addObject:planesInSquad];
        
    } else {
        [typeArray addObject:[NSString stringWithFormat:@"Эскадрильи: %@ по %@ самолетов", squads, planesInSquad]];
    }
    
    return typeArray;
}


- (NSString*)armourRelease:(NSDictionary*)armourPart {
    
    NSString* valueMin = armourPart[@"min"];
    NSString* valueMax = armourPart[@"max"];
    
    if ([valueMin isEqual:valueMax]) {
        return [valueMin integerValue] ? [NSString stringWithFormat:@"%@ мм", valueMin] : @"нет бронирования";
        
    } else {
        return [NSString stringWithFormat:@"%@ - %@ мм", valueMin, valueMax];
    }
}


#pragma mark - Module

- (void)module:(Module*)module fillWithResponse:(NSDictionary*)response forShip:(Ship*)ship {
    
    [self module:module addShip:ship];
    
    module.moduleID = [response[@"module_id"] stringValue];
    module.name = response[@"name"];
    
    module.type = response[@"type"];
    module.price = [response[@"price_credit"] intValue];
    
    module.imageString = response[@"image"];
    
    module.refreshDate = [ServerManager sharedManager].currentDate;
    
    NSMutableArray* stats;
    NSDictionary* profile = response[@"profile"];
    
    if ([module.type isEqual:@"Engine"]) {
        module.typeLocalized = @"Двигатель";
        stats = [self parseEngineModule:profile[@"engine"]];
        
    } else if ([module.type isEqual:@"Hull"]) {
        module.typeLocalized = @"Корпус";
        stats = [self parseHullModule:profile[@"hull"]];
        
    } else if ([module.type isEqual:@"Suo"]) {
        module.typeLocalized = @"Система управления огнем";
        stats = [self parseFireControlModule:profile[@"fire_control"]];
        
    } else if ([module.type isEqual:@"Artillery"]) {
        module.typeLocalized = @"Главный калибр";
        stats = [self parseArtilleryModule:profile[@"artillery"]];
        
    } else if ([module.type isEqual:@"Torpedoes"]) {
        module.typeLocalized = @"Торпедные аппараты";
        stats = [self parseTorpedoesModule:profile[@"torpedoes"]];
        
    } else if ([module.type isEqual:@"FlightControl"]) {
        module.typeLocalized = @"Контроль полетов";
        stats = [self parseFlightControlModule:profile[@"flight_control"]];
        
    } else if ([module.type isEqual:@"Fighter"]) {
        module.typeLocalized = @"Истребители";
        stats = [self parseFightersModule:profile[@"fighter"]];
        
    } else if ([module.type isEqual:@"TorpedoBomber"]) {
        module.typeLocalized = @"Торпедоносцы";
        stats = [self parseTorpedoBombersModule:profile[@"torpedo_bomber"]];
        
    } else if ([module.type isEqual:@"DiveBomber"]) {
        module.typeLocalized = @"Пикирующие бомбардировщики";
        stats = [self parseDiveBombersModule:profile[@"dive_bomber"]];
    }
    
    NSArray* statsArray = [NSArray arrayWithArray:stats];
    module.stats = [NSKeyedArchiver archivedDataWithRootObject:statsArray];
}


//// Соединение Модуля с Кораблем без повторов
- (void)module:(Module *)module addShip:(Ship *)ship {
    
    if (![module.ships containsObject:ship]) {
        [module addShipsObject:ship];
    }
}


- (NSMutableArray*)parseEngineModule:(NSDictionary*)engine {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Максимальная скорость"];
    NSString* maxSpeed = [self checkForNull:engine[@"max_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", maxSpeed]];
    
    return details;
}


- (NSMutableArray*)parseHullModule:(NSDictionary*)hull {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Боеспособность (здоровье)"];
    NSString* health = [self checkForNull:hull[@"health"]];
    [details addObject:health];
    
    
    [details addObject:@"Диапазон бронирования"];
    NSString* valueMin = hull[@"range"][@"min"];
    NSString* valueMax = hull[@"range"][@"max"];
    
    if ([valueMin integerValue] == 0) {
        [details addObject: @"нет бронирования"];
        
    } else {
        [details addObject:[NSString stringWithFormat:@"%@ - %@ мм", valueMin, valueMax]];
    }
    
    
    [details addObject:@"Башен главного калибра"];
    NSString* artillery = [self checkForNull:hull[@"artillery_barrels"]];
    [details addObject:artillery];
    
    
    [details addObject:@"Башен вспомогательного калибра"];
    NSString* atbas = [self checkForNull:hull[@"atba_barrels"]];
    [details addObject:atbas];
    
    
    [details addObject:@"Точек ПВО"];
    NSString* antiAir = [self checkForNull:hull[@"anti_aircraft_barrels"]];
    [details addObject:antiAir];
    
    
    [details addObject:@"Торпедных аппаратов"];
    NSString* torpedoes = [self checkForNull:hull[@"torpedoes_barrels"]];
    [details addObject:torpedoes];
    
    
    [details addObject:@"Вместимость ангара"];
    NSString* hangar = [self checkForNull:hull[@"planes_amount"]];
    [details addObject:hangar];
    
    return details;
}


- (NSMutableArray*)parseFireControlModule:(NSDictionary*)fireControl {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Дальность стрельбы"];
    NSString* distanceString = [self checkForNull:fireControl[@"distance"]];
    
    if ([distanceString isEqual:@"NA"]) {
        [details addObject:distanceString];
        
    } else {
        float distance = [distanceString floatValue];
        [details addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
    }
    
    
    [details addObject:@"Увеличение дальности стрельбы"];
    NSString* distIncrease = [self checkForNull:fireControl[@"distance_increase"]];
    [details addObject:[NSString stringWithFormat:@"%@%%", distIncrease]];
    
    return details;
}


- (NSMutableArray*)parseArtilleryModule:(NSDictionary*)artillery {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Скорострельность"];
    NSString* gunRateString = [self checkForNull:artillery[@"gun_rate"]];
    
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
    NSString* damageHE = [self checkForNull:artillery[@"max_damage_HE"]];
    [details addObject:damageHE];
    
    
    [details addObject:@"Максимальный урон ББ снарядом"];
    NSString* damageAP = [self checkForNull:artillery[@"max_damage_AP"]];
    [details addObject:damageAP];
    
    return details;
}


- (NSMutableArray*)parseTorpedoesModule:(NSDictionary*)torpedoes {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Максимальный урон"];
    NSString* damage = [self checkForNull:torpedoes[@"max_damage"]];
    [details addObject:damage];
    
    
    [details addObject:@"Время перезарядки"];
    NSString* shotSpeedString = [self checkForNull:torpedoes[@"shot_speed"]];
    
    if ([shotSpeedString isEqual:@"NA"]) {
        [details addObject:shotSpeedString];
        
    } else {
        float shotSpeed = [shotSpeedString floatValue];
        [details addObject:[NSString stringWithFormat:@"%1.2f сек", shotSpeed]];
    }
    
    
    [details addObject:@"Скорость хода"];
    NSString* speed = [self checkForNull:torpedoes[@"torpedo_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", speed]];
    
    
    [details addObject:@"Дальность хода"];
    NSString* distanceString = [self checkForNull:torpedoes[@"distance"]];
    
    if ([distanceString isEqual:@"NA"]) {
        [details addObject:distanceString];
        
    } else {
        float distance = [distanceString floatValue];
        [details addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
    }
    
    return details;
}


- (NSMutableArray*)parseFlightControlModule:(NSDictionary*)flightControl {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Эскадрилий истребителей"];
    [details addObject:[flightControl[@"fighter_squadrons"] stringValue]];
    
    
    [details addObject:@"Эскадрилий бомбардировщиков"];
    [details addObject:[flightControl[@"bomber_squadrons"] stringValue]];
    
    
    [details addObject:@"Эскадрилий торпедоносцев"];
    [details addObject:[flightControl[@"torpedo_squadrons"] stringValue]];
    
    return details;
}


- (NSMutableArray*)parseFightersModule:(NSDictionary*)fighters {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Крейсерская скорость"];
    NSString* speed = [self checkForNull:fighters[@"cruise_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", speed]];
    
    
    [details addObject:@"Средний урон в секунду"];
    NSString* damage = [self checkForNull:fighters[@"avg_damage"]];
    [details addObject:damage];
    
    
    [details addObject:@"Боеспособность (здоровье)"];
    NSString* health = [self checkForNull:fighters[@"max_health"]];
    [details addObject:health];
    
    
    [details addObject:@"Боекомплект"];
    NSString* ammo = [self checkForNull:fighters[@"max_ammo"]];
    [details addObject:ammo];
    
    return details;
}


- (NSMutableArray*)parseTorpedoBombersModule:(NSDictionary*)torpedoBombers {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Крейсерская скорость"];
    NSString* speed = [self checkForNull:torpedoBombers[@"cruise_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", speed]];
    
    
    [details addObject:@"Боеспособность (здоровье)"];
    NSString* health = [self checkForNull:torpedoBombers[@"max_health"]];
    [details addObject:health];
    
    
    [details addObject:@"Максимальный урон торпедой"];
    NSString* damage = [self checkForNull:torpedoBombers[@"torpedo_damage"]];
    [details addObject:damage];
    
    
    [details addObject:@"Максимальная скорость торпеды"];
    NSString* torpedoSpeed = [self checkForNull:torpedoBombers[@"torpedo_max_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", torpedoSpeed]];
    
    // На данный момент вместо названия - строковый ID торпеды
    [details addObject:@"Торпеда"];
    NSString* torpedoName = [self checkHardTextForNull:torpedoBombers[@"torpedo_name"]];
    [details addObject:torpedoName];
    
    
    [details addObject:@"Дальность пуска "];
    NSString* distanceString = [self checkForNull:torpedoBombers[@"distance"]];
    
    if ([distanceString isEqual:@"NA"]) {
        [details addObject:distanceString];
        
    } else {
        float distance = [distanceString floatValue];
        [details addObject:[NSString stringWithFormat:@"%1.1f км", distance]];
    }
    
    return details;
}


- (NSMutableArray*)parseDiveBombersModule:(NSDictionary*)diveBombers {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Крейсерская скорость"];
    NSString* speed = [self checkForNull:diveBombers[@"cruise_speed"]];
    [details addObject:[NSString stringWithFormat:@"%@ уз", speed]];
    
    
    [details addObject:@"Боеспособность (здоровье)"];
    NSString* health = [self checkForNull:diveBombers[@"max_health"]];
    [details addObject:health];
    
    
    [details addObject:@"Максимальный урон бомбой"];
    NSString* maxDamage = [self checkForNull:diveBombers[@"max_damage"]];
    [details addObject:maxDamage];
    
    
    [details addObject:@"Шанс пожара при попадании"];
    NSString* burnProb = diveBombers[@"bomb_burn_probability"];
    [details addObject:[NSString stringWithFormat:@"%@%%", burnProb]];
    
    
    [details addObject:@"Точность бомбометания"];
    NSDictionary* accuracyRange = diveBombers[@"accuracy"];
    
    float accuracyMin = [accuracyRange[@"min"] floatValue];
    float accuracyMax = [accuracyRange[@"max"] floatValue];
    
    if (accuracyMin == 0.f && accuracyMax == 0.f) {
        [details addObject:@"NA"];
        
    } else {
        [details addObject:[NSString stringWithFormat:@"%1.1f - %1.1f", accuracyMin, accuracyMax]];
    }
    
    return details;
}


#pragma mark - Upgrade

- (void)upgrade:(Upgrade*)upgrade fillWithResponse:(NSDictionary*)response forShip:(Ship*)ship {
    
    [self upgrade:upgrade addShip:ship];
    
    upgrade.upgradeID = [response[@"upgrade_id"] stringValue];
    
    NSString* nameString = response[@"name"];
    NSArray* nameComponents = [nameString componentsSeparatedByString:@"Модификация"];
    
    upgrade.name = [nameComponents firstObject];
    upgrade.mode = [[nameComponents lastObject] intValue];
    
    upgrade.price = [response[@"price"] intValue];
    
    upgrade.type = response[@"type"];
    upgrade.review = response[@"description"];
    
    upgrade.imageString = response[@"image"];
    
    upgrade.refreshDate = [ServerManager sharedManager].currentDate;
    
    NSMutableArray* stats;
    NSDictionary* uprgadeInfo = response[@"profile"][upgrade.type];
    
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
- (void)upgrade:(Upgrade*)upgrade addShip:(Ship*)ship {
    
    if (![upgrade.ships containsObject:ship]) {
        [upgrade addShipsObject:ship];
    }
}


- (NSMutableArray*)parsePowderUpgrade:(NSDictionary*)powder {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Шанс взрыва погреба"];
    NSString* probString = powder[@"detonation_prob"];
    
    float prob = [probString floatValue] * 100.f ;
    [details addObject:[NSString stringWithFormat:@"-%1.0f%%", prob]];
    
    return details;
}


- (NSMutableArray*)parseSteeringUpgrade:(NSDictionary*)steering {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Скорость ремонта"];
    NSString* repairTime = steering[@"repair_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:repairTime sign:@"+"]];
    
    [details addObject:@"Шанс крит.повреждения"];
    NSString* critDamage = steering[@"critical_damage_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:critDamage sign:@"-"]];
    
    [details addObject:@"Скорость перекладки рулей"];
    NSString* rudderTime = steering[@"rudder_time_coef"];
    [details addObject:[self percentFloatOneMinusValue: rudderTime sign:@"+"]];
    
    return details;
}


- (NSMutableArray*)parseGuidanceUpgrade:(NSDictionary*)guidance {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Скорость поворота установок ГК"];
    NSString* artRotation = guidance[@"artillery_rotation_speed"];
    [details addObject:[self percentFloatValueMinusOne:artRotation sign:@"+"]];
    
    [details addObject:@"Кучность стрельбы орудий ГК"];
    NSString* artAccuracy = guidance[@"artillery_shoot_accuracy"];
    [details addObject:[self percentFloatOneMinusValue:artAccuracy sign:@"+"]];
    
    [details addObject:@"Дальность стрельбы орудий ПМК"];
    NSString* atbaDistance = guidance[@"atba_max_dist"];
    [details addObject:[self percentFloatValueMinusOne:atbaDistance sign:@"+"]];
    
    [details addObject:@"Скорость поворота орудий ПМК"];
    NSString* atbaRotation = guidance[@"atba_rotation_speed"];
    [details addObject:[self percentFloatValueMinusOne:atbaRotation sign:@"+"]];
    
    [details addObject:@"Кучность стрельбы орудий ПМК"];
    NSString* atbaAccuracy = guidance[@"atba_shoot_accuracy"];
    [details addObject:[self percentFloatOneMinusValue:atbaAccuracy sign:@"+"]];
    
    return details;
}


- (NSMutableArray*)parseDamageControlUpgrade:(NSDictionary*)damageControl {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Вероятность пожара"];
    NSString* fireChance = damageControl[@"fire_starting_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:fireChance sign:@"-"]];
    
    [details addObject:@"Скорость тушения пожара"];
    NSString* fireTime = damageControl[@"burning_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:fireTime sign:@"+"]];
    
    [details addObject:@"Вероятность затопления"];
    NSString* floodChance = damageControl[@"flood_starting_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:floodChance sign:@"-"]];
    
    [details addObject:@"Скорость устранения затопления"];
    NSString* floodTime = damageControl[@"flooding_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:floodTime sign:@"+"]];
    
    return details;
}


- (NSMutableArray*)parseMainWeaponUpgrade:(NSDictionary*)mainWeapon {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Шанс выхода из строя ГК"];
    NSString* artDamage = mainWeapon[@"artillery_damage_prob"];
    [details addObject:[self percentFloatOneMinusValue:artDamage sign:@"-"]];
    
    [details addObject:@"Живучесть ГК"];
    NSString* artHealth = mainWeapon[@"artillery_max_hp"];
    [details addObject:[self percentFloatValueMinusOne:artHealth sign:@"+"]];
    
    [details addObject:@"Время ремонта ГК"];
    NSString* artRepair = mainWeapon[@"artillery_repair_time"];
    [details addObject:[self percentFloatOneMinusValue:artRepair sign:@"-"]];
    
    [details addObject:@"Вероятность выхода из строя ТА"];
    NSString* torpDamage = mainWeapon[@"tpd_damage_prob"];
    [details addObject:[self percentFloatOneMinusValue:torpDamage sign:@"-"]];
    
    [details addObject:@"Живучесть ТА"];
    NSString* torpHealth = mainWeapon[@"tpd_max_hp"];
    [details addObject:[self percentFloatValueMinusOne:torpHealth sign:@"+"]];
    
    [details addObject:@"Время ремонта ТА"];
    NSString* torpRepair = mainWeapon[@"tpd_repair_time"];
    [details addObject:[self percentFloatOneMinusValue:torpRepair sign:@"-"]];
    
    return details;
}


- (NSMutableArray*)parseSecondWeaponUpgrade:(NSDictionary*)secondWeapon {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Живучесть установок ПМК"];
    NSString* atbaHealth = secondWeapon[@"atba_max_hp"];
    [details addObject:[self percentFloatValueMinusOne:atbaHealth sign:@"+"]];
    
    [details addObject:@"Живучесть установок ПВО"];
    NSString* aaHealth = secondWeapon[@"air_defense_max_hp"];
    [details addObject:[self percentFloatValueMinusOne:aaHealth sign:@"+"]];
    
    return details;
}


- (NSMutableArray*)parseArtilleryUpgrade:(NSDictionary*)artillery {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Шанс крит.повреждения погреба"];
    NSString* ammoCritChance = artillery[@"ammo_critical_damage_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:ammoCritChance sign:@"-"]];
    
    [details addObject:@"Шанс взрыва погреба"];
    NSString* detonChance = artillery[@"ammo_detonation_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:detonChance sign:@"-"]];
    
    [details addObject:@"Скорость ремонта погреба"];
    NSString* ammoRepairTime = artillery[@"ammo_repair_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:ammoRepairTime sign:@"+"]];
    
    [details addObject:@"Шанс крит.повреждения установки ГК"];
    NSString* artCritChance = artillery[@"critical_damage_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:artCritChance sign:@"-"]];
    
    [details addObject:@"Время перезарядки ГК"];
    NSString* reloadTime = artillery[@"reload_time_coef"];
    [details addObject:[self percentFloatValueMinusOne:reloadTime sign:@"+"]];
    
    [details addObject:@"Скорость ремонта ГК"];
    NSString* artRepairTime = artillery[@"repair_time_coef"];
    [details addObject:[self percentFloatValueMinusOne:artRepairTime sign:@"+"]];
    
    [details addObject:@"Скорость наведения башен ГК"];
    NSString* rotationTime = artillery[@"rotation_time_coef"];
    [details addObject:[self percentFloatValueMinusOne:rotationTime sign:@"+"]];
    
    return details;
}


- (NSMutableArray*)parseEngineUpgrade:(NSDictionary*)engine {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Время набора макс.скорости вперед"];
    NSString* maxForward = engine[@"max_forward_power_coef"];
    [details addObject:[self percentFloatOneMinusValue:maxForward sign:@"-"]];
    
    [details addObject:@"Время набора макс.скорости назад"];
    NSString* maxBackfard = engine[@"max_backward_power_coef"];
    [details addObject:[self percentFloatOneMinusValue:maxBackfard sign:@"-"]];
    
    [details addObject:@"Шанс крит.повреждения"];
    NSString* critChance = engine[@"critical_damage_chance_coef"];
    [details addObject:[self percentFloatOneMinusValue:critChance sign:@"-"]];
    
    [details addObject:@"Время ремонта"];
    NSString* repairTime = engine[@"repair_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:repairTime sign:@"-"]];
    
    return details;
}


- (NSMutableArray*)parseAntiAircraftUpgrade:(NSDictionary*)antiAircraft {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Дальность стрельбы ПВО"];
    NSString* distance = antiAircraft[@"distance_coef"];
    [details addObject:[self percentFloatValueMinusOne:distance sign:@"+"]];
    
    [details addObject:@"Эффективность ПВО"];
    NSString* efficiency = antiAircraft[@"efficiency_coef"];
    [details addObject:[self percentFloatValueMinusOne:efficiency sign:@"+"]];
    
    [details addObject:@"Живучесть установок ПВО"];
    NSString* heath = antiAircraft[@"health_coef"];
    [details addObject:[self percentFloatValueMinusOne:heath sign:@"+"]];
    
    return details;
}


- (NSMutableArray*)parseFlightControlUpgrade:(NSDictionary*)flightControl {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Время подготовки самолетов"];
    NSString* time = flightControl[@"prepare_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:time sign:@"-"]];
    
    [details addObject:@"Скорость самолетов"];
    NSString* speed = flightControl[@"speed_coef"];
    [details addObject:[self percentFloatValueMinusOne:speed sign:@"+"]];
    
    return details;
}


- (NSMutableArray*)parsePlanesUpgrade:(NSDictionary*)planes {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Живучесть истребителей"];
    NSString* fighterHealth = planes[@"fighter_health_coef"];
    [details addObject:[self percentFloatValueMinusOne:fighterHealth sign:@"+"]];
    
    [details addObject:@"Живучесть бомбардировщиков"];
    NSString* bomberHealth = planes[@"bomber_health_coef"];
    [details addObject:[self percentFloatValueMinusOne:bomberHealth sign:@"+"]];
    
    [details addObject:@"Эффективность стрелкового вооружения"];
    NSString* efficiency = planes[@"efficiency_coef"];
    [details addObject:[self percentFloatValueMinusOne:efficiency sign:@"+"]];
    
    return details;
}


- (NSMutableArray*)parseAtbaUpgrade:(NSDictionary*)atba {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Кучность стрельбы ПМК"];
    NSString* accuracy = atba[@"accuracy_coef"];
    [details addObject:[self percentFloatOneMinusValue:accuracy sign:@"+"]];
    
    [details addObject:@"Дальность стрельбы ПМК"];
    NSString* distance = atba[@"distance_coef"];
    [details addObject:[self percentFloatValueMinusOne:distance sign:@"+"]];
    
    [details addObject:@"Живучесть установок ПМК"];
    NSString* health = atba[@"health_coef"];
    [details addObject:[self percentFloatValueMinusOne:health sign:@"+"]];
    
    [details addObject:@"Время перезарядки ПМК"];
    NSString* reloadTime = atba[@"reload_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:reloadTime sign:@"-"]];
    
    return details;
}


- (NSMutableArray*)parseConcealmentUpgrade:(NSDictionary*)concealment {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Заметность"];
    NSString* detectDist = concealment[@"detect_distance_coef"];
    [details addObject:[self percentFloatOneMinusValue:detectDist sign:@"-"]];
    
    return details;
}


- (NSMutableArray*)parseSpottingUpgrade:(NSDictionary*)spotting {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Дальность обнаружения"];
    NSString* spotDist = spotting[@"spot_distance_coef"];
    [details addObject:[self percentFloatValueMinusOne:spotDist sign:@"+"]];
    
    return details;
}


- (NSMutableArray*)parseTorpedoesUpgrade:(NSDictionary*)torpedoes {
    
    NSMutableArray* details = [NSMutableArray new];
    
    [details addObject:@"Шанс крит.повреждения ТА"];
    NSString* critChance = torpedoes[@"critical_damage_chance_coef"];
    [details addObject:[self percentFloatValueMinusOne:critChance sign:@"+"]];
    
    [details addObject:@"Время перезарядки"];
    NSString* reloadTime = torpedoes[@"reload_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:reloadTime sign:@"-"]];
    
    [details addObject:@"Время ремонта ТА"];
    NSString* repairTime = torpedoes[@"repair_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:repairTime sign:@"-"]];
    
    [details addObject:@"Скорость поворота ТА"];
    NSString* rotationTime = torpedoes[@"rotation_time_coef"];
    [details addObject:[self percentFloatOneMinusValue:rotationTime sign:@"-"]];
    
    return details;
}


- (NSString*)percentFloatValueMinusOne:(NSString*)value sign:(NSString*)sign {
    
    NSString* checkedValue = [self checkForNull:value];
    
    if ([checkedValue isEqual:@"NA"]) {
        return checkedValue;
        
    } else {
        float percent = ([checkedValue floatValue] - 1.f) * 100.f;
        
        return (percent < 0.f) ?
         [NSString stringWithFormat:@"%1.0f%%", percent] : [NSString stringWithFormat:@"%@%1.0f%%", sign, percent];
    }
}


- (NSString*) percentFloatOneMinusValue:(NSString*)value sign:(NSString*)sign {
    
    NSString* checkedValue = [self checkForNull:value];
    
    if ([checkedValue isEqual:@"NA"]) {
        return checkedValue;
        
    } else {
        float percent = (1.f - [checkedValue floatValue]) * 100.f;
        
        return (percent < 0.f) ?
         [NSString stringWithFormat:@"%1.0f%%", percent] : [NSString stringWithFormat:@"%@%1.0f%%", sign, percent];
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
        return ([value isKindOfClass:[NSNumber class]]) ? [value stringValue] : (NSString*)value;
    }
}


//// Проверка строк названий (буквы + цифры + символы)
- (NSString*) checkHardTextForNull:(id)value {
    
    if ([value isKindOfClass:[NSNull class]] || value == nil) {
        return @"NA";
        
    } else {
        return ([value isKindOfClass:[NSNumber class]]) ? [value stringValue] : (NSString*)value;
    }
}

@end
