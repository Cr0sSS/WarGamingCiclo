//
//  ModulesViewController.m
//  WarGamingCiclo
//
//  Created by Admin on 15.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import "ModulesViewController.h"
#import "ModuleDetailsViewController.h"

#import "ModuleCell.h"

#import "ServerManager.h"
#import "DataManager.h"
#import "ParsingManager.h"

#import <UIImageView+AFNetworking.h>

#import "Module+CoreDataClass.h"
#import "Ship+CoreDataClass.h"


@interface ModulesViewController () <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) NSArray* modulesArray;

@end

@implementation ModulesViewController

static NSString * const moduleCellIdentifier = @"ModuleCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Модули";
    self.collectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background"]];
    
    self.modulesArray = [[DataManager sharedManager] getEntities:@"Module" forShip:self.ship];
    
    NSArray* moduleIDsArray = [NSKeyedUnarchiver unarchiveObjectWithData:self.ship.moduleIDs];
    
    NSInteger currentModuleCounter = 0;
    
    for (NSArray* group in self.modulesArray) {
        currentModuleCounter = currentModuleCounter + [group count];
    }
    
    if (currentModuleCounter != [moduleIDsArray count]) {
        for (NSString* moduleID in moduleIDsArray) {
            
            NSArray* resultArray = [[DataManager sharedManager] getModuleWithID:moduleID];
            
            if ([resultArray count] == 0) {
                //// Модуля нет в базе, создание нового
                [[ServerManager sharedManager]
                 getModuleFromServerWithID:moduleID
                 onSuccess:^(NSDictionary *response) {
                     
                     [[DataManager sharedManager] moduleWithResponse:response forShip:self.ship];
                     [self reloadData];
                     
                     NSLog(@"Модуль загружен");
                 }
                 
                 onFailure:^(NSError *error) {
                     NSLog(@"MODULE CREATE REQUEST ERROR\n%@", [error localizedDescription]);
                 }];
                
            //// Модуль есть в базе, добавить текущий Корабль
            } else {
                Module* module = [resultArray firstObject];
                [[ParsingManager sharedManager] module:module addShip:self.ship];
                [self reloadData];
                
                NSLog(@"Модулю добавлен Корабль ");
            }
        }
    }
    
    for (NSArray* group in self.modulesArray) {
        for (Module* module in group) {
            
            if (![module.refreshDate isEqual:[ServerManager sharedManager].currentDate]) {
                //// Данные Модуля устарели, обновление
                [[ServerManager sharedManager]
                 getModuleFromServerWithID:module.moduleID
                 onSuccess:^(NSDictionary *response) {
                     
                     [[ParsingManager sharedManager] module:module
                                           fillWithResponse:response
                                                    forShip:self.ship];
                     [self reloadData];
                     
                     NSLog(@"Модуль обновлен");
                 }
                 
                 onFailure:^(NSError *error) {
                     NSLog(@"MODULE UPDATE REQUEST ERROR\n%@", [error localizedDescription]);
                 }];
            }
        }
    }
}


- (void)reloadData {
    [[DataManager sharedManager] saveContext];
    self.modulesArray = [[DataManager sharedManager] getEntities:@"Module" forShip:self.ship];
    [self.collectionView reloadData];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.modulesArray count];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.modulesArray[section] count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ModuleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:moduleCellIdentifier forIndexPath:indexPath];
    
    Module* module = self.modulesArray[indexPath.section][indexPath.row];
    cell.moduleTextLabel.text = module.name;
    
    NSURL* imageURL = [NSURL URLWithString:module.imageString];
    NSURLRequest* request = [NSURLRequest requestWithURL:imageURL];
    
    __weak ModuleCell* weakCell = cell;
    
    cell.moduleImageView.image = nil;
    [cell.moduleImageView setImageWithURLRequest:request
                                placeholderImage:nil
                                         success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                                             
                                             weakCell.moduleImageView.image = image;
                                             [weakCell layoutSubviews];
                                         }
                                         failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                                             NSLog(@"ERROR: Image for module %@ load fail\n%@", module.name, [error localizedDescription]);
    }];
    
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ModuleDetailsViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"ModuleDetailsVC"];
    
    vc.module = self.modulesArray[indexPath.section][indexPath.row];
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


- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
                                                               traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

@end
