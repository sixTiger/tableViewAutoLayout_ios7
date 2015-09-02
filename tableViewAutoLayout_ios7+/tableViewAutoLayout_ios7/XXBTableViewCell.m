//
//  XXBTableViewCell.m
//  tableViewAutoLayout_ios7
//
//  Created by 杨小兵 on 15/8/23.
//  Copyright (c) 2015年 杨小兵. All rights reserved.
//

#import "XXBTableViewCell.h"
#import <Masonry.h>
#import <ReactiveCocoa.h>
#import "XXBModel.h"

@interface XXBTableViewCell ()

@property(nonatomic,weak)UILabel *label1;
@property(nonatomic,weak)UILabel *label2;
@property(nonatomic,weak)UILabel *label3;
@property(nonatomic,weak)UIImageView *iconImage;
@end
@implementation XXBTableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self p_creatTableView];
    }
    return  self;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self p_creatTableView];
    }
    return self;
}

- (void)p_creatTableView
{
    self.contentView.clipsToBounds = YES;
    UILabel *label1 = [UILabel new];
    [self.contentView addSubview:label1];
    label1.backgroundColor = [UIColor blueColor];
    label1.backgroundColor = [UIColor yellowColor];
    label1.numberOfLines = 0;
    
    UILabel *label2 = [UILabel new];
    label2.backgroundColor = [UIColor purpleColor];
    label2.numberOfLines = 0;
    [self.contentView addSubview:label2];
    
    UILabel *label3 = [UILabel new];
    label3.backgroundColor = [UIColor greenColor];
    label3.numberOfLines = 0;
    [self.contentView addSubview:label3];
    
    UIImageView *imageView = [UIImageView new];
    imageView.backgroundColor = [UIColor redColor];
    [self.contentView addSubview:imageView];
    
    _label1 = label1;
    _label2 = label2;
    _label3 = label3;
    _iconImage = imageView;
    CGFloat panding = 5;
    @weakify(self);
    [_iconImage mas_makeConstraints:^(MASConstraintMaker *make) {
        @strongify(self);
        make.top.equalTo(self.contentView.mas_top).with.offset(panding);
        make.left.equalTo(self.contentView.mas_left).offset(panding);
        make.right.equalTo(self.contentView.mas_right).offset(-panding);
        make.height.mas_equalTo(30);
    }];
    [_label1 mas_makeConstraints:^(MASConstraintMaker *make) {
        @strongify(self);
        make.top.equalTo(self.iconImage.mas_bottom).with.offset(panding);
        make.left.equalTo(self.contentView.mas_left).offset(panding);
        make.right.equalTo(self.contentView.mas_right).offset(-panding);
    }];
    [_label2 mas_makeConstraints:^(MASConstraintMaker *make) {
        @strongify(self);
        make.top.equalTo(self.label1.mas_bottom).with.offset(panding);
        make.left.equalTo(self.contentView.mas_left).offset(panding);
        make.right.equalTo(self.contentView.mas_right).offset(-panding);
    }];
    
    [_label3 mas_makeConstraints:^(MASConstraintMaker *make) {
        @strongify(self);
        make.top.equalTo(self.label2.mas_bottom).with.offset(panding);
        make.left.equalTo(self.contentView.mas_left).offset(panding);
        make.right.equalTo(self.contentView.mas_right).offset(-panding);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-panding).priorityLow();
    }];
}
- (void)setModel:(XXBModel *)model
{
    _model = model;
    self.label1.text = model.text1;
    self.label2.text = model.text2;
    
    self.label3.text = model.text2;
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}
- (void)layoutSubviews
{
    
    
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];
    
    self.label1.preferredMaxLayoutWidth = CGRectGetWidth(self.label1.frame);
    self.label2.preferredMaxLayoutWidth = CGRectGetWidth(self.label2.frame);
}
- (void)updateConstraints
{
    [super updateConstraints];
}
@end
