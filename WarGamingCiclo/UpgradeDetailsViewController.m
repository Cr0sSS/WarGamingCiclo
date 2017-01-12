//
//  UpgradeDetailsViewController.m
//  WarGamingCiclo
//
//  Created by Admin on 22.12.16.
//  Copyright © 2016 Andrey Kuznetsov. All rights reserved.
//

#import "UpgradeDetailsViewController.h"

#import "UpgradeStatCell.h"

#import "Upgrade+CoreDataClass.h"


@interface UpgradeDetailsViewController ()

@property (strong, nonatomic) NSMutableArray* statNames;
@property (strong, nonatomic) NSMutableArray* statValues;

@end

@implementation UpgradeDetailsViewController

static NSString* statCellIdentifier = @"UpgradeStatCell";

static float statCellHeight = 30.f;
static float tableWidth = 248.f;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.statNames = [NSMutableArray new];
    self.statValues = [NSMutableArray new];
    
    [self.statNames addObject:self.upgrade.name];
    [self.statValues addObject:[NSString stringWithFormat:@"Mod.%d", self.upgrade.mode]];
    
    NSArray* stats = [NSKeyedUnarchiver unarchiveObjectWithData:self.upgrade.stats];
    
    for (NSInteger i = 0; i < [stats count]; i = i + 2) {
        NSString* value = [stats objectAtIndex:i + 1];
        
        if (![value hasPrefix:@"NA"]) {
            [self.statNames addObject:[stats objectAtIndex:i]];
            [self.statValues addObject:value];
        }
    }
    
    /* 
    // На текущий момент стоимость всех модернизаций нулевая. Раскомментировать, когда будет исправлено
    [self.statNames addObject:@"Стоимость"];
    [self.statValues addObject:[NSString stringWithFormat:@"%ld", self.upgrade.price]];
    */
    
    [self setPreferredContentSize:CGSizeMake(tableWidth, statCellHeight * [self.statNames count])];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
        self.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight;
        
    } else {
        self.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.statNames count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UpgradeStatCell *cell = [tableView dequeueReusableCellWithIdentifier:statCellIdentifier forIndexPath:indexPath];
    
    cell.nameLabel.text = [self.statNames objectAtIndex:indexPath.row];
    cell.valueLabel.text = [self.statValues objectAtIndex:indexPath.row];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return statCellHeight;
}

@end