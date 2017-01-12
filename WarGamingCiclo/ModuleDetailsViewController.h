//
//  ModuleDetailsViewController.h
//  WarGamingCiclo
//
//  Created by Admin on 16.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Module;

@interface ModuleDetailsViewController : UITableViewController

@property (strong, nonatomic) Module* module;

@end
