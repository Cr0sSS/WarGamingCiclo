//
//  UpgradesViewController.m
//  WarGamingCiclo
//
//  Created by Admin on 19.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import "UpgradesViewController.h"
#import "UpgradeDetailsViewController.h"

#import "UpgradeCell.h"

#import "ServerManager.h"
#import "DataManager.h"
#import "ParsingManager.h"

#import <UIImageView+AFNetworking.h>

#import "Upgrade+CoreDataClass.h"
#import "Ship+CoreDataClass.h"


@interface UpgradesViewController () <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) NSArray* upgradesArray;

@end

@implementation UpgradesViewController

static NSString * const upgradeCellIdentifier = @"UpgradeCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Модернизации";
    self.collectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background"]];
    
    self.upgradesArray = [[DataManager sharedManager] getEntities:@"Upgrade" forShip:self.ship];
    
    NSArray* upgradeIDsArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.ship.upgradeIDs];
    
    NSInteger currentUpgradeCounter = 0;
    
    for (NSArray* group in self.upgradesArray) {
        currentUpgradeCounter = currentUpgradeCounter + [group count];
    }
    
    if (currentUpgradeCounter != [upgradeIDsArray count]) {
        for (NSString* upgradeID in upgradeIDsArray) {
            
            NSArray* resultArray = [[DataManager sharedManager] getUpgradeWithID:upgradeID];
            
            //// Апгрейда нет в базе, создание нового
            if ([resultArray count] == 0) {
                [[ServerManager sharedManager]
                 getUpgradeFromServerWithID:upgradeID
                  onSuccess:^(NSDictionary *response) {
                    
                      [[DataManager sharedManager] upgradeWithResponse:response forShip:self.ship];
                      [self reloadData];
          
                      NSLog(@"Апгрейд загружен");
                  }
                 
                  onFailure:^(NSError *error) {
                      NSLog(@"UPGRADE CREATE REQUEST ERROR\n%@", [error localizedDescription]);
                }];
                
            //// Апгрейд есть в базе, добавить текущий Корабль
            } else {
                Upgrade* upgrade = [resultArray firstObject];
                [[ParsingManager sharedManager] upgrade:upgrade addShip:self.ship];
                [self reloadData];
                
                NSLog(@"Апгрейду добавлен корабль");
            }
        }
    }
    
    for (NSArray* group in self.upgradesArray) {
        for (Upgrade* upgrade in group) {
            
            if (![upgrade.refreshDate isEqual:[ServerManager sharedManager].currentDate]) {
                //// Данные Апгрейда устарели, обновление
                [[ServerManager sharedManager]
                 getUpgradeFromServerWithID:upgrade.upgradeID
                 onSuccess:^(NSDictionary *response) {
                     
                     [[ParsingManager sharedManager] upgrade:upgrade
                                            fillWithResponse:response
                                                     forShip:self.ship];
                     [self reloadData];
                     
                     NSLog(@"Апгрейд обновлен");
                 }
                 
                 onFailure:^(NSError *error) {
                     NSLog(@"UPGRADE UPDATE REQUEST ERROR\n%@", [error localizedDescription]);
                 }];
            }
        }
    }
}


- (void) reloadData {
    
    [[DataManager sharedManager] saveContext];
    self.upgradesArray = [[DataManager sharedManager] getEntities:@"Upgrade" forShip:self.ship];
    [self.collectionView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.upgradesArray count];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self.upgradesArray objectAtIndex:section] count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UpgradeCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:upgradeCellIdentifier forIndexPath:indexPath];
    
    Upgrade* upgrade = [[self.upgradesArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    cell.upgradeTextLabel.text = [NSString stringWithFormat:@"%@ %d", upgrade.name, upgrade.mode];
    
    NSURL* imageURL = [NSURL URLWithString:upgrade.imageString];
    NSURLRequest* request = [NSURLRequest requestWithURL:imageURL];
    
    __weak UpgradeCell* weakCell = cell;
    
    cell.upgradeImageView.image = nil;
    [cell.upgradeImageView setImageWithURLRequest:request
                                 placeholderImage:nil
                                          success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                                              
                                              weakCell.upgradeImageView.image = image;
                                              [weakCell layoutSubviews];
                                          }
     
                                          failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                                              NSLog(@"ERROR: Image for upgrade %@ load fail\n%@", upgrade.name, [error localizedDescription]);
    }];
    
    
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UpgradeDetailsViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"UpgradeDetailsVC"];
    
    vc.upgrade = [[self.upgradesArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    vc.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popController = vc.popoverPresentationController;
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    if (popController) {
        popController.delegate = self;
        
        popController.sourceView = [collectionView cellForItemAtIndexPath:indexPath];
        popController.sourceRect = [[collectionView cellForItemAtIndexPath:indexPath] bounds];
        [popController setBackgroundColor:vc.tableView.backgroundColor];
    }
    
    [self presentViewController:vc animated:YES completion:nil];
}


- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

@end
