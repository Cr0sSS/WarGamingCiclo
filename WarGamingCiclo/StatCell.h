//
//  StatCell.h
//  WarGamingCiclo
//
//  Created by Admin on 08.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@end
