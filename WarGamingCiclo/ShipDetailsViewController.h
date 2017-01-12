//
//  ShipDetailsViewController.h
//  WarGamingCiclo
//
//  Created by Admin on 08.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Ship;

@interface ShipDetailsViewController : UITableViewController

@property (strong, nonatomic) Ship* ship;

@end
