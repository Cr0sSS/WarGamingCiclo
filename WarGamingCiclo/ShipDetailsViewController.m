//
//  ShipDetailsViewController.m
//  WarGamingCiclo
//
//  Created by Admin on 08.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import "ShipDetailsViewController.h"
#import "ModulesViewController.h"
#import "UpgradesViewController.h"
#import "ShipDescriptionViewController.h"

#import "UnitHeaderCell.h"
#import "LargeImageCell.h"
#import "StatCell.h"
#import "StatHeaderCell.h"
#import "GroupInStatsCell.h"

#import "ServerManager.h"
#import "DataManager.h"

#import <UIImageView+AFNetworking.h>

#import "Ship+CoreDataClass.h"
#import "ShipType+CoreDataClass.h"


@interface ShipDetailsViewController () <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) NSMutableArray* mainStatsNames;
@property (strong, nonatomic) NSMutableArray* mainStatsValues;

@property (strong, nonatomic) NSMutableArray* mainBatteryNames;
@property (strong, nonatomic) NSMutableArray* mainBatteryValues;

@property (strong, nonatomic) NSMutableArray* additionalBatteries;

@property (strong, nonatomic) NSMutableArray* antiAircraftNames;
@property (strong, nonatomic) NSMutableArray* antiAircraftValues;

@property (strong, nonatomic) NSMutableArray* mobilityNames;
@property (strong, nonatomic) NSMutableArray* mobilityValues;

@property (strong, nonatomic) NSMutableArray* concealmentNames;
@property (strong, nonatomic) NSMutableArray* concealmentValues;

@property (strong, nonatomic) NSMutableArray* torpedoesNames;
@property (strong, nonatomic) NSMutableArray* torpedoesValues;

@property (strong, nonatomic) NSMutableArray* airGroupNames;
@property (strong, nonatomic) NSMutableArray* airGroupValues;

@end

@implementation ShipDetailsViewController

static NSString* headerCellIdentifier = @"UnitHeaderCell";
static NSString* imageCellIdentifier = @"LargeImageCell";
static NSString* statCellIdentifier = @"StatCell";
static NSString* statHeaderCellIdentifier = @"StatHeaderCell";
static NSString* groupCellIdentifier = @"GroupCell";

static NSInteger sectionShift = 8;

static NSArray* tierValues;
static NSArray* groupNames;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tierValues = @[@"I",@"II",@"II",@"IV",@"V",@"VI",@"VII",@"VIII",@"IX",@"X"];
        groupNames = @[@"Модули",@"Модернизации"];
    });
    
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background"]];
    self.tableView.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background"]];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                              target:self
                                              action:@selector(actionShowDescription:)];
    
    self.mainStatsNames = [NSMutableArray new];
    self.mainStatsValues = [NSMutableArray new];
    
    self.mainBatteryNames = [NSMutableArray new];
    self.mainBatteryValues = [NSMutableArray new];
    
    self.additionalBatteries = [NSMutableArray new];
    
    self.antiAircraftNames = [NSMutableArray new];
    self.antiAircraftValues = [NSMutableArray new];
    
    self.mobilityNames = [NSMutableArray new];
    self.mobilityValues = [NSMutableArray new];
    
    self.concealmentNames = [NSMutableArray new];
    self.concealmentValues = [NSMutableArray new];
    
    self.torpedoesNames = [NSMutableArray new];
    self.torpedoesValues = [NSMutableArray new];
    
    self.airGroupNames = [NSMutableArray new];
    self.airGroupValues = [NSMutableArray new];
    
    self.navigationItem.title = self.ship.name;
    
    [self shareStatsArrays];

    //// Обновление/загрузка детальной информации о корабле
    if (![self.ship.detailsRefreshDate isEqual:[ServerManager sharedManager].currentDate]) {
        
        [[ServerManager sharedManager]
         getShipDetailsFromServerWithShip:self.ship
         onSuccess:^() {
             
             [[DataManager sharedManager] saveContext];
             [self shareStatsArrays];
             [self.tableView reloadData];
              
             NSLog(@"%@ был обновлен в деталях", self.ship.name);
         }
         
         onFailure:^(NSError *error) {
             NSLog(@"SHIP DETAILS ERROR\n%@", [error localizedDescription]);
         }];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void) actionShowDescription:(UIBarButtonItem*)sender {
    
    ShipDescriptionViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ShipDescriptionVC"];
    vc.text = self.ship.review;
    vc.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popController = vc.popoverPresentationController;
    
    if (popController) {
        popController.delegate = self;
        
        popController.barButtonItem = sender;
        [popController setBackgroundColor:vc.textView.backgroundColor];
    }
    
    [self presentViewController:vc animated:YES completion:nil];
}


- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
                                                               traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}


- (void) shareStatsArrays {
    
    [self shareData:self.ship.mainStats toNames:self.mainStatsNames values:self.mainStatsValues];
    [self shareData:self.ship.mobility toNames:self.mobilityNames values:self.mobilityValues];
    [self shareData:self.ship.concealment toNames:self.concealmentNames values:self.concealmentValues];
    [self shareData:self.ship.antiAircraft toNames:self.antiAircraftNames values:self.antiAircraftValues];
    [self shareData:self.ship.torpedoes toNames:self.torpedoesNames values:self.torpedoesValues];
    [self shareData:self.ship.airGroup toNames:self.airGroupNames values:self.airGroupValues];
    [self shareData:self.ship.mainBattery toNames:self.mainBatteryNames values:self.mainBatteryValues];
    
    if (self.ship.additionalBattery) {
        NSArray* additionalBattery = [NSKeyedUnarchiver unarchiveObjectWithData:self.ship.additionalBattery];
        
        for (NSArray* battery in additionalBattery) {
            NSMutableArray* batteryNames = [NSMutableArray new];
            NSMutableArray* batteryValues = [NSMutableArray new];
            
            [self shareArray:battery toNames:batteryNames values:batteryValues];
            NSArray* filteredBattery = [NSArray arrayWithObjects:batteryNames, batteryValues, nil];
            
            [self.additionalBatteries addObject:filteredBattery];
        }
    }
}


- (void) shareData:(NSData*)data toNames:(NSMutableArray*)names values:(NSMutableArray*)values {
    
    if (data) {
        NSArray* array = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [self shareArray:array toNames:names values:values];
    }
}


- (void) shareArray:(NSArray*)array toNames:(NSMutableArray*)names values:(NSMutableArray*)values {
    
    for (NSInteger i = 0; i < [array count]; i = i + 2) {
        NSString* value = [array objectAtIndex:i + 1];
        
        //// Добавляет данные для отображения только в случае их наличия
        if (![value hasPrefix:@"NA"]) {
            [names addObject:[array objectAtIndex:i]];
            [values addObject:value];
        }
    }
    
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return sectionShift + [self.additionalBatteries count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    switch (section) {
        case 0:
            return 2 + [groupNames count];
            break;
            
        case 1:
            return [self.mainStatsValues count];
            break;
            
        case 2:
            return [self.mobilityNames count];
            break;
            
        case 3:
            return [self.concealmentNames count];
            break;
            
        case 4:
            return [self.antiAircraftNames count];
            break;
            
        case 5:
            return [self.torpedoesNames count];
            break;
            
        case 6:
            return [self.airGroupNames count];
            break;
            
        case 7:
            return [self.mainBatteryNames count];
            break;

        default:
            return [[[self.additionalBatteries objectAtIndex:section - sectionShift] objectAtIndex:0] count];
            break;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 ) {
        
        if (indexPath.row == 0) {
            UnitHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:headerCellIdentifier forIndexPath:indexPath];
            
            NSString* typeString = self.ship.type.name;
            
            if (!typeString) {
                typeString = @"(класс неизвестен)";
            }

            if (self.ship.isPremium) {
                cell.classLabel.text = [NSString stringWithFormat:@"Премиум %@", typeString];
                
            } else {
                cell.classLabel.text = typeString;
            }

            cell.tierLabel.text = [tierValues objectAtIndex:self.ship.tier - 1];
            
            return cell;
            
        } else if (indexPath.row == 1) {
            LargeImageCell* cell = [tableView dequeueReusableCellWithIdentifier:imageCellIdentifier forIndexPath:indexPath];
            
            NSURL* largeImageURL = [NSURL URLWithString:self.ship.largeImageString];
            NSURLRequest* request = [NSURLRequest requestWithURL:largeImageURL];
            __weak LargeImageCell* weakCell = cell;
            
            [cell.imageView setImageWithURLRequest:request
                                  placeholderImage:nil
                                           success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                                               weakCell.largeImageView.image = image;
                                               [weakCell layoutSubviews];
                                           }
                                           failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                                               NSLog(@"ERROR\nLarge image for ship %@ load fail\n%@", self.ship.name, [error localizedDescription]);
                                           }];
            
            return cell;
            
        } else {
            GroupInStatsCell* cell = [tableView dequeueReusableCellWithIdentifier:groupCellIdentifier forIndexPath:indexPath];
            
            cell.groupNameLabel.text = [groupNames objectAtIndex:indexPath.row - 2];
            
            return cell;
        }
    
    } else if (indexPath.section == 1) {
        StatCell *cell = [tableView dequeueReusableCellWithIdentifier:statCellIdentifier forIndexPath:indexPath];
        
        cell.nameLabel.text = [self.mainStatsNames objectAtIndex:indexPath.row];
        cell.valueLabel.text = [self. mainStatsValues objectAtIndex:indexPath.row];
        
        return cell;
        
    } else if (indexPath.section == 2) {
        StatCell *cell = [tableView dequeueReusableCellWithIdentifier:statCellIdentifier forIndexPath:indexPath];
        
        cell.nameLabel.text = [self.mobilityNames objectAtIndex:indexPath.row];
        cell.valueLabel.text = [self. mobilityValues objectAtIndex:indexPath.row];
        
        return cell;
        
    } else if (indexPath.section == 3) {
        StatCell *cell = [tableView dequeueReusableCellWithIdentifier:statCellIdentifier forIndexPath:indexPath];
        
        cell.nameLabel.text = [self.concealmentNames objectAtIndex:indexPath.row];
        cell.valueLabel.text = [self. concealmentValues objectAtIndex:indexPath.row];
        
        return cell;
        
    } else if (indexPath.section == 4) {
        StatCell *cell = [tableView dequeueReusableCellWithIdentifier:statCellIdentifier forIndexPath:indexPath];
        
        cell.nameLabel.text = [self.antiAircraftNames objectAtIndex:indexPath.row];
        cell.valueLabel.text = [self. antiAircraftValues objectAtIndex:indexPath.row];
        
        return cell;
        
    } else if (indexPath.section == 5) {
        StatCell *cell = [tableView dequeueReusableCellWithIdentifier:statCellIdentifier forIndexPath:indexPath];
        
        cell.nameLabel.text = [self.torpedoesNames objectAtIndex:indexPath.row];
        cell.valueLabel.text = [self. torpedoesValues objectAtIndex:indexPath.row];
        
        return cell;
        
    } else if (indexPath.section == 6) {
        StatCell *cell = [tableView dequeueReusableCellWithIdentifier:statCellIdentifier forIndexPath:indexPath];
        
        cell.nameLabel.text = [self.airGroupNames objectAtIndex:indexPath.row];
        cell.valueLabel.text = [self. airGroupValues objectAtIndex:indexPath.row];
        
        return cell;
        
    } else if (indexPath.section == 7) {
        StatCell *cell = [tableView dequeueReusableCellWithIdentifier:statCellIdentifier forIndexPath:indexPath];
        
        cell.nameLabel.text = [self.mainBatteryNames objectAtIndex:indexPath.row];
        cell.valueLabel.text = [self. mainBatteryValues objectAtIndex:indexPath.row];
        
        return cell;

    } else {
        StatCell *cell = [tableView dequeueReusableCellWithIdentifier:statCellIdentifier forIndexPath:indexPath];
        
        NSArray* battery = [self.additionalBatteries objectAtIndex:indexPath.section - sectionShift];
        NSArray* batteryNames = [battery objectAtIndex:0];
        NSArray* batteryValues = [battery objectAtIndex:1];
        
        cell.nameLabel.text = [batteryNames objectAtIndex:indexPath.row];
        cell.valueLabel.text = [batteryValues objectAtIndex:indexPath.row];
        
        return cell;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 0) {
            return 27.f;
            
        } else if (indexPath.row == 1) {
            return 205.f;
            
        } else {
            return 32.f;
        }
    
    } else {
        return 33.f;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if (section == 0) {
        return nil;
        
    } else {
        StatHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:statHeaderCellIdentifier];
        
        switch (section) {
            case 1:
                cell.headerTextLabel.text = @"Основные характеристики";
                break;
                
            case 2:
                cell.headerTextLabel.text = @"Маневренность";
                break;
                
            case 3:
                cell.headerTextLabel.text = @"Маскировка";
                break;
                
            case 4:
                if ([self.antiAircraftNames count]) {
                    cell.headerTextLabel.text = @"ПВО";
                } else {
                    cell.headerTextLabel.text = @"Не имеет зенитных орудий";

                }
                break;
                
            case 5:
                if ([self.torpedoesNames count]) {
                    cell.headerTextLabel.text = @"Торпедное вооружение";
                } else {
                    cell.headerTextLabel.text = @"Не имеет торпедных аппаратов";

                }
                break;
                
            case 6:
                if ([self.airGroupNames count]) {
                    cell.headerTextLabel.text = @"Авиагруппа";
                } else {
                    cell.headerTextLabel.text = @"Не имеет авиагруппы";

                }
                break;
                
            case 7:
                if ([self.mainBatteryNames count]) {
                    cell.headerTextLabel.text = @"Главный калибр";
                } else {
                    cell.headerTextLabel.text = @"Не имеет дальнобойного вооружения";
                }
                break;
                
            default:
                if ([self.additionalBatteries count] > 1) {
                    cell.headerTextLabel.text = [NSString stringWithFormat:@"Вспомогательный калибр №%ld", section - sectionShift + 1];
                    
                } else {
                    cell.headerTextLabel.text = @"Вспомогательный калибр";
                }
                break;
        }
        return cell;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if (section) {
        return 16.f;
        
    } else {
        return 0.f;
    }
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        
        if (indexPath.row == 2) {
            ModulesViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ModulesVC"];
            vc.ship = self.ship;
            [self.navigationController pushViewController:vc animated:YES];
            
        } else if (indexPath.row == 3) {
            UpgradesViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"UpgradesVC"];
            vc.ship = self.ship;
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}


- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row > 1) {
        return YES;
        
    } else {
        return NO;
    }
}

@end
