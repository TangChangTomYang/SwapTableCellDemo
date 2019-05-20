//
//  ViewController.m
//  MyTable
//
//  Created by yangrui on 2019/5/19.
//  Copyright © 2019年 yangrui. All rights reserved.
//

#import "ViewController.h"
#import "Mode.h"
#import "TableViewCell.h"

typedef enum {
    LongPressDirection_none,
    LongPressDirection_up,
    LongPressDirection_down
}LongPressDirection;


@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property(nonatomic, strong)TableViewCell *movingSnapCell;
@property(nonatomic, assign)CGRect movingSnapCellOffset;
@property(nonatomic, strong)NSIndexPath *movingIndexPath;
@property(nonatomic, strong)CADisplayLink *displayLink;
@property(nonatomic, assign)LongPressDirection scrollDirection;
@property(nonatomic, assign)CGFloat  velocity;

@property(nonatomic, strong)UILongPressGestureRecognizer *longPress;
@property(nonatomic, assign)CGPoint longPressPrePointInView;

@property(nonatomic, strong)UIPanGestureRecognizer *panGesture;


@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSMutableArray<Mode *> *modeArrM;



@end

@implementation ViewController

-(NSMutableArray<Mode *> *)modeArrM{
    if (!_modeArrM) {
        _modeArrM = [NSMutableArray array];
        for(int i = 1; i <= 30; i ++){
            Mode *md = [Mode new];
            md.name = @(i%10+1).stringValue;
            md.height = i % 2 ?  80 : 180;
            [_modeArrM addObject:md];
        }
    }
    return _modeArrM;
}

-(CADisplayLink *)displayLink{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction:)];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _displayLink.paused = YES;
    }
    return _displayLink;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect tbvFrame = CGRectMake(0, 50, self.view.frame.size.width, self.view.frame.size.height - 100);
    UITableView *tableView = [[UITableView alloc] initWithFrame:tbvFrame  style:0];
    tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.layer.borderColor = [UIColor orangeColor].CGColor;
    tableView.layer.borderWidth = 2.0;
    [tableView registerNib:[UINib nibWithNibName:@"TableViewCell" bundle:nil] forCellReuseIdentifier:@"TableViewCell"];
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    self.velocity = 8;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureAction:)];
    longPress.delegate = self;
    self.longPress = longPress;
    [self.view addGestureRecognizer:longPress];
 
}




#pragma mark-
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}

-(void)longPressGestureAction:(UILongPressGestureRecognizer *)longGesture{
    
    if (longGesture.state == UIGestureRecognizerStateBegan) {
        [self longPressGestureActionBegin:longGesture];
    }
    else if(longGesture.state == UIGestureRecognizerStateChanged){
        [self longPressGestureActionChange:longGesture];
    }
    else if(longGesture.state == UIGestureRecognizerStateEnded ||
            longGesture.state == UIGestureRecognizerStateCancelled ){
        
        [self longPressGestureActionEnd:longGesture];
        
    }
}



-(void)longPressGestureActionBegin:(UILongPressGestureRecognizer *)longGesture{
   
    CGPoint pointInTbv = [longGesture locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:pointInTbv];
    
    if (indexPath == nil) {
        return;
    }
    CGPoint pointInView = [longGesture locationInView:self.view];
    self.longPressPrePointInView = pointInView;
    self.movingIndexPath = indexPath;
    
    self.tableView.scrollEnabled = NO;
    TableViewCell *movingCell = [self creatSnapCellWithIndexPath:indexPath];
    [self.view addSubview:movingCell];
    self.movingSnapCell = movingCell;
    
}

-(void)longPressGestureActionChange:(UILongPressGestureRecognizer *)longGesture{
    
    if (self.tableView.scrollEnabled == YES || self.movingSnapCell == nil) {
        return;
    }
    CGPoint pointInView = [longGesture locationInView:self.view];
    CGPoint translate = CGPointMake(pointInView.x - self.longPressPrePointInView.x, pointInView.y - self.longPressPrePointInView.y);
    if (translate.y > 0)  {
        self.scrollDirection = LongPressDirection_down;
    }
    else if(translate.y < 0){
        self.scrollDirection = LongPressDirection_up;
    }
    else{
        self.scrollDirection = LongPressDirection_none;
    }
    
    self.longPressPrePointInView = pointInView;
    CGRect frame = self.movingSnapCell.frame;
    frame.origin.x += translate.x;
    frame.origin.y += translate.y;
    self.movingSnapCell.frame = frame;
    
    NSIndexPath *swapIndexPath = nil;
    if (CGRectGetMinY(self.movingSnapCell.frame) < CGRectGetMinY(self.tableView.frame) ) { // top
        swapIndexPath = [self getOuterTopSwapTargetIndexPath];
        self.displayLink.paused = NO;
    }
    else if(CGRectGetMaxY(self.movingSnapCell.frame) > CGRectGetMaxY(self.tableView.frame) ){ //bottom
        self.displayLink.paused = NO;
        swapIndexPath = [self getOuterBottomSwapTargetIndexPath];

    }  else{
        swapIndexPath = [self getInnerSwapTargetIndexPath];
        self.displayLink.paused = YES;
    }
    if (swapIndexPath != nil) {
        [self swapMovingIndexPathToPath:swapIndexPath];
    }
}

-(void)swapMovingIndexPathToPath:(NSIndexPath *)toIndexPath{
    [self.modeArrM exchangeObjectAtIndex:self.movingIndexPath.row withObjectAtIndex:toIndexPath.row];
    [self.tableView moveRowAtIndexPath:self.movingIndexPath toIndexPath:toIndexPath];
    self.movingIndexPath = toIndexPath;
}


#pragma mark-
-(void)displayLinkAction:(CADisplayLink *)displayLink{
    NSIndexPath *swapIndexPath = nil;
    if (CGRectGetMinY(self.movingSnapCell.frame) < CGRectGetMinY(self.tableView.frame) ) { // top
       
        if (self.tableView.contentOffset.y > -(self.tableView.contentInset.top)) {
            self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, self.tableView.contentOffset.y - self.velocity);
            swapIndexPath = [self getOuterTopSwapTargetIndexPath];
        }
    }
    else if(CGRectGetMaxY(self.movingSnapCell.frame) > CGRectGetMaxY(self.tableView.frame) ){ //bottom
        
        if (self.tableView.contentOffset.y < self.tableView.contentSize.height -self.tableView.frame.size.height) {
            self.tableView.contentOffset = CGPointMake(self.tableView.contentOffset.x, self.tableView.contentOffset.y + self.velocity);
         
            swapIndexPath = [self getOuterBottomSwapTargetIndexPath];
        }
    }
    
    if (swapIndexPath != nil) {
        [self swapMovingIndexPathToPath:swapIndexPath];
    }
    
}

-(void)longPressGestureActionEnd:(UILongPressGestureRecognizer *)longGesture{
    CGRect frameInTbv = [self.tableView cellForRowAtIndexPath:self.movingIndexPath].frame;
    CGRect frameInView = CGRectMake(frameInTbv.origin.x, frameInTbv.origin.y - self.tableView.contentOffset.y + self.tableView.frame.origin.y, frameInTbv.size.width, frameInTbv.size.height);
    
    self.displayLink.paused = YES;
    self.scrollDirection = LongPressDirection_none;
    self.movingIndexPath = nil;
    
    [UIView animateWithDuration:0.25 animations:^{
        self.movingSnapCell.frame = frameInView;
    } completion:^(BOOL finished) {
        [self.movingSnapCell removeFromSuperview];
        self.movingSnapCell = nil;
        self.tableView.scrollEnabled = YES;
        for (Mode *md in self.modeArrM) {
            md.hide = NO ;
        }
        [self.tableView reloadData];
    }];
}


#pragma mark- 获取边界外向上的 swapTargetIndexPath
-(CGRect)convertViewRectToTbv:(CGRect)viewRect{
    return   CGRectMake(viewRect.origin.x, viewRect.origin.y - self.tableView.frame.origin.y + self.tableView.contentOffset.y, viewRect.size.width, viewRect.size.height);
}

-(CGRect)convertTbvRectToView:(CGRect)tbvRect{
    return  CGRectMake(tbvRect.origin.x, tbvRect.origin.y - self.tableView.contentOffset.y + self.tableView.frame.origin.y, tbvRect.size.width, tbvRect.size.height);
}

-(CGPoint)convertViewPointToTbv:(CGPoint)viewPoint{
    return CGPointMake(viewPoint.x, viewPoint.y - self.tableView.frame.origin.y + self.tableView.contentOffset.y);
}

-(CGPoint)convertTbvPointToView:(CGPoint)tbvPoint{
    return  CGPointMake(tbvPoint.x, tbvPoint.y - self.tableView.contentOffset.y + self.tableView.frame.origin.y);
}

-(NSIndexPath *)getOuterTopSwapTargetIndexPath{
    
    CGPoint topPointInView = CGPointMake(self.tableView.frame.size.width * 0.5, self.tableView.frame.origin.y);
    CGPoint topPointInTbv = [self convertViewPointToTbv:topPointInView];
    NSIndexPath *topSwapIndexpath = [self.tableView indexPathForRowAtPoint:topPointInTbv];
    
    if (topSwapIndexpath != nil && self.movingIndexPath.row > topSwapIndexpath.row ) {
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:topSwapIndexpath];
        CGRect topSwapRectInView = [self convertTbvRectToView:cell.frame];
        CGFloat topSwapRectInView_centerY = CGRectGetMinY(topSwapRectInView) +  topSwapRectInView.size.height * 0.5;
        if (topPointInView.y < (topSwapRectInView_centerY + self.tableView.contentInset.top)) {
            //NSLog(@"------找到 outer top Index: %ld", topSwapIndexpath.row);
            return topSwapIndexpath;
        }
        return nil;
    }
    return nil;
}

-(NSIndexPath *)getOuterBottomSwapTargetIndexPath{
    
    CGPoint bottomPointInView = CGPointMake(self.tableView.frame.size.width * 0.5, CGRectGetMaxY(self.tableView.frame));
    CGPoint bottomPointInTbv = [self convertViewPointToTbv:bottomPointInView];
    NSIndexPath *bottomSwapIndexpath = [self.tableView indexPathForRowAtPoint:bottomPointInTbv];
    if (bottomSwapIndexpath != nil && self.movingIndexPath.row < bottomSwapIndexpath.row) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:bottomSwapIndexpath];
        CGRect bottomSwapRectInView = [self convertTbvRectToView:cell.frame];
        CGFloat bottomSwapRectInView_centerY = CGRectGetMinY(bottomSwapRectInView) +  bottomSwapRectInView.size.height * 0.5;
        if (bottomPointInView.y > (bottomSwapRectInView_centerY + self.tableView.contentInset.top)) {
            
            //NSLog(@"------找到 outer bottom Index: %ld", bottomSwapIndexpath.row);
            return bottomSwapIndexpath;
        }
        return nil;
    }
    return nil;
}


-(NSIndexPath *)getInnerSwapTargetIndexPath{
    
    if (self.scrollDirection == LongPressDirection_none) {
//        NSLog(@"---swap Direction_none------nil--------  ");
        return nil;
    }
    
    
    CGRect frameInTbv = [self convertViewRectToTbv:self.movingSnapCell.frame];
    if (self.scrollDirection == LongPressDirection_up) {
        
        CGPoint topPointInTbv = CGPointMake(frameInTbv.size.width * 0.5, CGRectGetMinY(frameInTbv));
        NSIndexPath *topSwapIndexpath = [self.tableView indexPathForRowAtPoint:topPointInTbv];
        
        
        if (topSwapIndexpath != nil && self.movingIndexPath.row > topSwapIndexpath.row ) {
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:topSwapIndexpath];
            CGRect topSwapRectInView = [self convertTbvRectToView:cell.frame];
            CGFloat topSwapRectInView_centerY = CGRectGetMinY(topSwapRectInView) +  topSwapRectInView.size.height * 0.5;
            if (CGRectGetMinY(self.movingSnapCell.frame) < topSwapRectInView_centerY  ) {
                //NSLog(@"--top inner swap 找到了 indexP: %ld", topSwapIndexpath.row);
                return topSwapIndexpath;
            }
            //NSLog(@"---top inner swap  大于 centerY--没找到-nil------:%ld",topSwapIndexpath.row);
            return nil;
        }
        //NSLog(@"---top inner swap  序号不对, 没找到");
        return nil;
    }
    else if(self.scrollDirection == LongPressDirection_down){
        
        CGPoint bottomPointInTbv =  CGPointMake(frameInTbv.size.width * 0.5, CGRectGetMaxY(frameInTbv));;
        NSIndexPath *bottomSwapIndexPath = [self.tableView indexPathForRowAtPoint:bottomPointInTbv];
        
        if (bottomSwapIndexPath != nil && self.movingIndexPath.row < bottomSwapIndexPath.row) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:bottomSwapIndexPath];
            
            CGRect bottomSwapRectInView = [self convertTbvRectToView:cell.frame];
            
            CGFloat bottomSwapRectInView_centerY = CGRectGetMinY(bottomSwapRectInView) +  bottomSwapRectInView.size.height * 0.5;
            if (CGRectGetMaxY(self.movingSnapCell.frame) > bottomSwapRectInView_centerY  ) {
                //NSLog(@"--bottom inner swap 找到了 indexP: %ld", bottomSwapIndexPath.row);
                return bottomSwapIndexPath;
                
            }
            //NSLog(@"---bottom inner swap  小于 centerY--没找到-nil------:%ld",bottomSwapIndexPath.row);
            return nil;
        }
        //NSLog(@"---bottom inner swap  序号不对, 没找到");
        return nil;
    }
    return nil;
}

-(TableViewCell *)creatSnapCellWithIndexPath:(NSIndexPath *)indexPath{
   
    TableViewCell *movingCell= [[[NSBundle mainBundle] loadNibNamed:@"TableViewCell" owner:nil options:nil]lastObject];
    movingCell.layer.borderColor = [UIColor cyanColor].CGColor;
    movingCell.layer.borderWidth = 5.0;
    
    TableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    Mode *md = self.modeArrM[indexPath.row];
    movingCell.md = md;
    movingCell.nameLb.text = @(indexPath.row).stringValue;
    
    CGRect frameInView = [self convertTbvRectToView:cell.frame];
    movingCell.frame = frameInView;
    
    cell.hidden = YES;
    md.hide = YES;
    return movingCell;
}

#pragma mark-
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.modeArrM.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    Mode *md = self.modeArrM[indexPath.row];
    return md.height;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
 
    TableViewCell *cell = (TableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"TableViewCell" forIndexPath:indexPath];
    Mode *md = self.modeArrM[indexPath.row];
    cell.md = md;
    cell.nameLb.text = @(indexPath.row).stringValue;
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
 
}


@end
