//
//  TableViewCell.m
//  tableViewAutoLayout_ios7
//
//  Created by xiaobing on 15/11/12.
//  Copyright © 2015年 杨小兵. All rights reserved.
//

#import "TableViewCell.h"
#import <XXBLibs.h>
#define ButtonWidth     80
#define Bounds          30

@interface TableViewCell ()<UIGestureRecognizerDelegate>
{
    CGFloat startLocation;
    BOOL    hideMenuView;
}
@property(nonatomic , strong) NSMutableArray    *buttonArray;
@property(nonatomic , weak ) UIView             *myContentView;

@end

@implementation TableViewCell
- (instancetype)init
{
    if (self = [super init]) {
        [self p_setupTableViewCell];
    }
    return self;
}
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])
    {
        [self p_setupTableViewCell];
    }
    return self;
}
- (void)updateConstraints
{
    [super updateConstraints];
}
- (void)layoutSubviews
{
    [super layoutSubviews];
    self.contentView.backgroundColor = [UIColor myRandomColor];
    self.myContentView.frame = self.contentView.frame;
    NSInteger buttonCount = self.buttonArray.count;
    UIButton *button;
    CGFloat selfWidth = CGRectGetWidth(self.contentView.frame);
    CGFloat selfHeight = CGRectGetHeight(self.contentView.frame);
    for (NSInteger i = 0; i < buttonCount; i++)
    {
        button = self.buttonArray[i];
        button.frame = CGRectMake(selfWidth - (i + 1) * ButtonWidth, 0, ButtonWidth,selfHeight);
        NSLog(@"%@",NSStringFromCGRect(button.frame));
    }
}
- (void)p_setupTableViewCell
{
    [self p_creatButtons];
    [self p_addGesture];
}
- (void)p_creatButtons
{
    [self.buttonArray makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.buttonArray removeAllObjects];
    for (NSObject *obj in self.buttonMessageArray)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        if ([obj isKindOfClass:[NSString class]]) {
            [button setTitle:(NSString *)obj forState:UIControlStateNormal];
        }
        else
        {
            if ([obj isKindOfClass:[UIImage class]])
            {
                [button setImage:(UIImage *)obj forState:UIControlStateNormal];
            }
        }
        button.backgroundColor = [UIColor myRandomColor];
        [self.contentView insertSubview:button belowSubview:self.myContentView];
        [self.buttonArray addObject:button];
    }
}
- (void)prepareForReuse
{
    [super prepareForReuse];
    self.contentView.clipsToBounds = YES;
}
#pragma mark 手势处理
- (void)p_addGesture
{
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    [self.contentView addGestureRecognizer:panGesture];
}
-(void)handlePan:(UIPanGestureRecognizer *)sender{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            startLocation = [sender locationInView:self.contentView].x;
            CGFloat direction = [sender velocityInView:self.contentView].x;
            //        if (direction < 0) {
            //            if ([_delegate respondsToSelector:@selector(didCellWillShow:)]) {
            //                [_delegate didCellWillShow:self];
            //            }
            //        }else{
            //            if ([_delegate respondsToSelector:@selector(didCellWillHide:)]) {
            //                [_delegate didCellWillHide:self];
            //            }
            //        }
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGFloat vCurrentLocation = [sender locationInView:self.contentView].x;
            CGFloat vDistance = vCurrentLocation - startLocation;
            startLocation = vCurrentLocation;
            CGRect vCurrentRect = self.myContentView.frame;
            CGFloat vOriginX = MAX(-[self getMenusWidth] - ButtonWidth, vCurrentRect.origin.x + vDistance);
            vOriginX = MIN(0 + ButtonWidth, vOriginX);
            self.myContentView.frame = CGRectMake(vOriginX, vCurrentRect.origin.y, vCurrentRect.size.width, vCurrentRect.size.height);
            NSLog(@"%@",NSStringFromCGRect(self.myContentView.frame));
            CGFloat direction = [sender velocityInView:self.contentView].x;
            if (direction < -40.0 || vOriginX <  - (0.5 * (ButtonWidth * self.buttonArray.count))) {
                hideMenuView = NO;
            }
            else
            {
                
                if(direction > 20.0 || vOriginX >  - (0.5 * (ButtonWidth * self.buttonArray.count))){
                    hideMenuView = YES;
                }
            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        {
            [self hideMenuView:hideMenuView Animated:YES];
            break;
        }
            
        default:
            break;
    }
}
-(void)hideMenuView:(BOOL)aHide Animated:(BOOL)aAnimate{
    if (self.selected) {
        [self setSelected:NO animated:NO];
    }
    CGRect vDestinaRect = CGRectZero;
    if (aHide)
    {
        vDestinaRect = self.contentView.frame;
    }else{
        vDestinaRect = CGRectMake(-[self getMenusWidth], self.contentView.frame.origin.x, self.contentView.frame.size.width, self.contentView.frame.size.height);
    }
    
    CGFloat vDuration = aAnimate? 0.4 : 0.0;
    [UIView animateWithDuration:vDuration animations:^{
        self.myContentView.frame = vDestinaRect;
    } completion:^(BOOL finished) {
        //        if (aHide) {
        //            if ([_delegate respondsToSelector:@selector(didCellHided:)]) {
        //                [_delegate didCellHided:self];
        //            }
        //        }else{
        //            if ([_delegate respondsToSelector:@selector(didCellShowed:)]) {
        //                [_delegate didCellShowed:self];
        //            }
        //        }
        //        UIView *vMenuView = [self.contentView viewWithTag:100];
        //        vMenuView.hidden = aHide;
    }];
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint vTranslationPoint = [gestureRecognizer translationInView:self.contentView];
        return fabs(vTranslationPoint.x) > fabs(vTranslationPoint.y);
    }
    return YES;
}
- (CGFloat)getMenusWidth
{
    return ButtonWidth * self.buttonArray.count;
}
#pragma mark - 一些系统方法的重写

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    //    // Configure the view for the selected state
    //    UIView *vMenuView = [self.contentView viewWithTag:100];
    //    if (vMenuView.hidden == YES) {
    //        [super setSelected:selected animated:animated];
    //        self.backgroundColor = [UIColor whiteColor];
    //    }
}
//此方法和上面的方法很重要，对ios 5SDK 设置不被Helighted
-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    //    UIView *vMenuView = [self.contentView viewWithTag:100];
    //    if (vMenuView.hidden == YES) {
    //        [super setHighlighted:highlighted animated:animated];
    //    }
}
- (NSMutableArray *)buttonArray
{
    if (_buttonArray == nil) {
        _buttonArray = [NSMutableArray array];
    }
    return _buttonArray;
}
- (NSArray *)buttonMessageArray
{
    if(_buttonMessageArray == nil)
    {
        _buttonMessageArray = @[@"更多",@"删除"];
    }
    return _buttonMessageArray;
}
- (UIView *)myContentView
{
    if (_myContentView == nil) {
        UIView *myContentView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        myContentView.backgroundColor = [UIColor grayColor];
        _myContentView = myContentView;
        [self.contentView addSubview:myContentView];
        @weakify(self);
        [myContentView mas_makeConstraints:^(MASConstraintMaker *make) {
            @strongify(self);
            make.top.equalTo(self.contentView.mas_top);
            make.left.equalTo(self.contentView.mas_left);
            make.right.equalTo(self.contentView.mas_right);
            make.bottom.equalTo(self.contentView.mas_bottom);
        }];
    }
    return _myContentView;
}
@end
