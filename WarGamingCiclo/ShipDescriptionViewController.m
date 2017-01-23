//
//  ShipDescriptionViewController.m
//  WarGamingCiclo
//
//  Created by Admin on 10.01.17.
//  Copyright © 2017 Andrey Kuznetsov. All rights reserved.
//

#import "ShipDescriptionViewController.h"

@interface ShipDescriptionViewController ()

@end

@implementation ShipDescriptionViewController

static float vcWidth = 340.f;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.textView.text = self.text;
    
    CGRect rect = [self.text boundingRectWithSize:CGSizeMake(vcWidth, MAXFLOAT)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName:self.textView.font}
                                          context:nil];
    
    [self setPreferredContentSize:CGSizeMake(rect.size.width, rect.size.height + 28.f)];
    
    [self.popoverPresentationController setBackgroundColor:self.textView.backgroundColor];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
