//
//  UpgradeDetailsViewController.h
//  WarGamingCiclo
//
//  Created by Admin on 22.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Upgrade;

@interface UpgradeDetailsViewController : UITableViewController

@property (strong, nonatomic) Upgrade* upgrade;

@end
