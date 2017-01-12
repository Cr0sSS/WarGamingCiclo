//
//  ShipDescriptionViewController.h
//  WarGamingCiclo
//
//  Created by Admin on 10.01.17.
//  Copyright © 2017 Andrey Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShipDescriptionViewController : UIViewController

@property (strong, nonatomic) NSString* text;

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end
