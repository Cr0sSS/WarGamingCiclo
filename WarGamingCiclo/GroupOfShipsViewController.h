//
//  GroupOfShipsViewController.h
//  WarGamingCiclo
//
//  Created by Admin on 07.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Nation;
@class ShipType;

@interface GroupOfShipsViewController : UICollectionViewController

@property (strong, nonatomic) Nation* nation;
@property (strong, nonatomic) ShipType* shipType;

@end
