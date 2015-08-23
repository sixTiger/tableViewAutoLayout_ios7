//
//  UITableView+SelfSizing.h
//  SinaBlog
//
//  Created by Robin on 8/10/15.
//  Copyright © 2015 Robin. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface UITableView (SelfSizing)
//缓存高度
- (CGFloat)heightForCellWithIdentifier:(NSString *)identifier cacheByIndexPath:(NSIndexPath *)indexPath configuration:(void (^)(id))configuration;
//动态算高度
- (CGFloat)heightForCellWithIdentifier:(NSString *)identifier configuration:(void (^)(id))configuration;
@end
