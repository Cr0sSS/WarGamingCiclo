//
//  ShipGroupCell.h
//  WarGamingCiclo
//
//  Created by Admin on 07.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShipGroupCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *shipName;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;

@end
