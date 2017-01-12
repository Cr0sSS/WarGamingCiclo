//
//  TypesAndNationsViewController.m
//  WarGamingCiclo
//
//  Created by Admin on 06.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import "TypesAndNationsViewController.h"
#import "GroupOfShipsViewController.h"

#import "NationCell.h"
#import "TypeCell.h"

#import "DataManager.h"
#import "ServerManager.h"
#import "ParsingManager.h"

#import <UIImageView+AFNetworking.h>
#import <KTCenterFlowLayout.h>

#import "Nation+CoreDataClass.h"
#import "ShipType+CoreDataClass.h"


@interface TypesAndNationsViewController () <UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSArray* nationsArray;
@property (strong, nonatomic) NSArray* typesArray;

@end

@implementation TypesAndNationsViewController

static NSString* const nationCellIdentifier = @"NationCell";
static NSString* const typeCellIdentifier = @"TypeCell";


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background"]];
    
    KTCenterFlowLayout* layout = [KTCenterFlowLayout new];
    layout.minimumLineSpacing = 10.f;
    layout.minimumInteritemSpacing = 10.f;
    layout.sectionInset = UIEdgeInsetsMake(10.f, 0.f, 0.f, 0.f);
    
    layout.itemSize = CGSizeMake(120.f, 86.f);
    
    self.collectionView.collectionViewLayout = layout;
    
    [self fillMainArrays];
    
    [[ServerManager sharedManager]
     getTypesAndNationsFromServerOnSuccess:^(NSDictionary* response) {
         
         NSDictionary* responsedNations = [response objectForKey:@"ship_nations"];
         
         NSArray* nationsKeys = [responsedNations allKeys];
         NSArray* nationsNames = [responsedNations allValues];
         
         NSDictionary* responsedTypes = [response objectForKey:@"ship_types"];
         NSDictionary* responsedImages = [response objectForKey:@"ship_type_images"];
         
         NSArray* shipsKeys = [responsedTypes allKeys];
         NSArray* shipsNames = [responsedTypes allValues];
         
         //// Если база пуста (первый запуск приложения)
         if ([self.nationsArray count] == 0) {
             
             //// Иногда всплывают События (events) как Нация
             for (NSInteger i = 0; i < [nationsKeys count]; i++) {
                 
                 if (![[nationsKeys objectAtIndex:i] isEqualToString:@"events"]) {
                     [[DataManager sharedManager] nationWithName:[nationsNames objectAtIndex:i]
                                                           andID:[nationsKeys objectAtIndex:i]];
                 }
             }
             
             for (NSInteger i = 0; i < [shipsKeys count]; i++) {
                 NSString* typeID = [shipsKeys objectAtIndex:i];
                 
                 [[DataManager sharedManager] shipTypeWithID:typeID
                                                        name:[shipsNames objectAtIndex:i]
                                                  imagesDict:[responsedImages objectForKey:typeID]];
             }

             [[DataManager sharedManager] saveContext];
             [self fillMainArrays];

             [self.collectionView reloadData];
             
             NSLog(@"Нации и Классы созданы с нуля");

         //// Если в базе старая информация
         } else {
             Nation* someNation = [self.nationsArray firstObject];
             
             if (![someNation.refreshDate isEqual:[ServerManager sharedManager].currentDate]) {
                 
                 for (Nation* nation in self.nationsArray) {
                     NSString* name = [responsedNations valueForKey:nation.nationID];
                     [[ParsingManager sharedManager] nation:nation
                                               fillWithName:name
                                                      andID:nation.nationID];
                 }
                 
                 for (ShipType* type in self.typesArray) {
                     NSString* name = [responsedTypes valueForKey:type.typeID];
                     [[ParsingManager sharedManager] shipType:type
                                                   fillWithID:type.typeID
                                                         name:name
                                                   imagesDict:[responsedImages objectForKey:type.typeID]];
                 }
                 
                 [[DataManager sharedManager] saveContext];
                 [self.collectionView reloadData];
                 
                 NSLog(@"Нации и Классы обновлены");
             }
         }
     }
     
     onFailure:^(NSError *error) {
         NSLog(@"NATIONS&TYPES ERROR\n%@", [error localizedDescription]);
     }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void) fillMainArrays {
    self.nationsArray = [[DataManager sharedManager] getAllEntities:@"Nation"];
    self.typesArray = [[DataManager sharedManager] getAllEntities:@"ShipType"];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (section == 0) {
        return [self.nationsArray count];
        
    } else {
        return [self.typesArray count];
    }
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 ) {
        NationCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:nationCellIdentifier forIndexPath:indexPath];
        
        Nation* nation = [self.nationsArray objectAtIndex:indexPath.row];
        cell.nationTextLabel.text = nation.name;
        cell.flagImageView.image = [UIImage imageNamed:nation.nationID];
        
        return cell;

    } else {
        TypeCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:typeCellIdentifier forIndexPath:indexPath];
        
        ShipType* type = [self.typesArray objectAtIndex:indexPath.row];
        cell.typeTextLabel.text = type.name;
        
        NSURL* imageURL = [NSURL URLWithString:type.eliteImageString];
        NSURLRequest* request = [NSURLRequest requestWithURL:imageURL];
        
        __weak TypeCell* weakCell = cell;
        
        [cell.imageView
         setImageWithURLRequest:request
               placeholderImage:nil
                        success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                            
                            weakCell.imageView.image = image;
                            [weakCell layoutSubviews];
        }
         
                        failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                            NSLog(@"ERROR: Image for type %@ load fail\n%@", type.name, [error localizedDescription]);
        }];
        
        return cell;
    }
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        return CGSizeMake(120.f, 86.f);
        
    } else {
        return CGSizeMake(87.f, 46.f);
    }
}


#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
        
    GroupOfShipsViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:@"GroupsOfShipsVC"];
    
    if (indexPath.section == 0) {
        vc.nation = [self.nationsArray objectAtIndex:indexPath.row];
    } else {
        vc.shipType = [self.typesArray objectAtIndex:indexPath.row];
    }
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end
