//
//  TableViewCell.h
//  MyTable
//
//  Created by yangrui on 2019/5/19.
//  Copyright © 2019年 yangrui. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Mode.h"

@interface TableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imgV;
@property (weak, nonatomic) IBOutlet UILabel *nameLb;

@property(nonatomic, strong)Mode *md;
@end
