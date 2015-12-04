//
//  TableViewCell.h
//  tableViewAutoLayout_ios7
//
//  Created by xiaobing on 15/11/12.
//  Copyright © 2015年 杨小兵. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCell : UITableViewCell

/**
 *  cell上边的按钮的一些信息，可以是标题，或者图片
 */
@property(nonatomic , strong) NSArray           *buttonMessageArray;
/**
 *  主要用于添加控件
 */
@property(nonatomic , weak , readonly) UIView   *myContentView;
@end
