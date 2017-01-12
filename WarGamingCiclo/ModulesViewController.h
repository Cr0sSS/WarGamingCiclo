//
//  ModulesViewController.h
//  WarGamingCiclo
//
//  Created by Admin on 15.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Ship;

@interface ModulesViewController : UICollectionViewController

@property (strong, nonatomic) Ship* ship;

- (void) reloadData;

@end
