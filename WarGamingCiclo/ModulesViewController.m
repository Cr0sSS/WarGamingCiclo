//
//  ModulesViewController.m
//  WarGamingCiclo
//
//  Created by Admin on 15.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import "ModulesViewController.h"
#import "ModuleDetailsViewController.h"
#import "ErrorController.h"

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
    
    [self fillMainArray];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Data

- (void)fillMainArray {
    
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
                 }
                 onFailure:^(NSError *error) {
                     [self showError:error withTitle:@"Загрузка инфо модуля: Ошибка"];
                 }];
                
            //// Модуль есть в базе, добавить текущий Корабль
            } else {
                Module* module = [resultArray firstObject];
                [[ParsingManager sharedManager] module:module addShip:self.ship];
                [self reloadData];
            }
        }
    }
    
    for (NSArray* group in self.modulesArray) {
        for (Module* module in group) {
            
            //// Данные Модуля устарели, обновление
            if (![module.refreshDate isEqual:[ServerManager sharedManager].currentDate]) {
                [[ServerManager sharedManager]
                 getModuleFromServerWithID:module.moduleID
                 onSuccess:^(NSDictionary *response) {
                     
                     [[ParsingManager sharedManager] module:module
                                           fillWithResponse:response
                                                    forShip:self.ship];
                     [self reloadData];
                 }
                 onFailure:^(NSError *error) {
                     [self showError:error withTitle:@"Загрузка инфо модуля: Ошибка"];
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


#pragma mark - Error

- (void)showError:(NSError*)error withTitle:(NSString*)title{
    ErrorController* ec = [ErrorController errorControllerWithTitle:title
                                                            message:error.localizedDescription];
    [self presentViewController:ec animated:YES completion:nil];
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
                                             [self showError:error withTitle:@"Ошибка загрузки изображения"];
    }];
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


#pragma mark - Popover

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
    }

    [self presentViewController:vc animated:YES completion:nil];
}


- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
                                                               traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

@end
