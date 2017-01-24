//
//  UpgradesViewController.m
//  WarGamingCiclo
//
//  Created by Admin on 19.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import "UpgradesViewController.h"
#import "UpgradeDetailsViewController.h"
#import "ErrorController.h"

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
    
    [self fillMainArray];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Data

- (void)fillMainArray {
    
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
                 }
                 onFailure:^(NSError *error) {
                     [self showError:error withTitle:@"Загрузка инфо модернизации: Ошибка"];
                 }];
                
            //// Апгрейд есть в базе, добавить текущий Корабль
            } else {
                Upgrade* upgrade = [resultArray firstObject];
                [[ParsingManager sharedManager] upgrade:upgrade addShip:self.ship];
                [self reloadData];
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
                 }
                 onFailure:^(NSError *error) {
                     [self showError:error withTitle:@"Загрузка инфо модернизации: Ошибка"];
                 }];
            }
        }
    }
}


- (void)reloadData {
    
    [[DataManager sharedManager] saveContext];
    self.upgradesArray = [[DataManager sharedManager] getEntities:@"Upgrade" forShip:self.ship];
    [self.collectionView reloadData];
}


#pragma mark - Error

- (void)showError:(NSError*)error withTitle:(NSString*)title{
    ErrorController* ec = [ErrorController errorControllerWithTitle:title
                                                            message:error.localizedDescription];
    [self presentViewController:ec animated:YES completion:nil];
}


#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.upgradesArray count];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.upgradesArray[section] count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UpgradeCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:upgradeCellIdentifier forIndexPath:indexPath];
    
    Upgrade* upgrade = self.upgradesArray[indexPath.section][indexPath.row];
    
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
                                              [self showError:error withTitle:@"Ошибка загрузки изображения"];
                                          }];
    return cell;
}


#pragma mark - Collection View Delegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self callPopoverAtIndexPath:indexPath];
}


#pragma mark - Popover

- (void)callPopoverAtIndexPath:(NSIndexPath*)indexPath {
    UpgradeDetailsViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"UpgradeDetailsVC"];
    
    vc.upgrade = self.upgradesArray[indexPath.section][indexPath.row];
    vc.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popController = vc.popoverPresentationController;
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    if (popController) {
        popController.delegate = self;
        
        popController.sourceView = [self.collectionView cellForItemAtIndexPath:indexPath];
        popController.sourceRect = [[self.collectionView cellForItemAtIndexPath:indexPath] bounds];
    }
    
    [self presentViewController:vc animated:YES completion:nil];
}


- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
                                                               traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

@end
