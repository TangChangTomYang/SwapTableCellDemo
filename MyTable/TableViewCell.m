//
//  TableViewCell.m
//  MyTable
//
//  Created by yangrui on 2019/5/19.
//  Copyright © 2019年 yangrui. All rights reserved.
//

#import "TableViewCell.h"

@implementation TableViewCell

-(void)setMd:(Mode *)md{
    _md = md;
    self.imgV.image = [UIImage imageNamed:md.name];
    self.hidden = md.hide;
}
@end
