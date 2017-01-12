//
//  NationCell.h
//  WarGamingCiclo
//
//  Created by Admin on 06.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NationCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *nationTextLabel;
@property (weak, nonatomic) IBOutlet UIImageView *flagImageView;

@end
