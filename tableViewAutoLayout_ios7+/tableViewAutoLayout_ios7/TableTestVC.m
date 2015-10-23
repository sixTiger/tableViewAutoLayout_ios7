//
//  TableTestVC.m
//  tableViewAutoLayout_ios7
//
//  Created by xiaobing on 15/10/23.
//  Copyright © 2015年 杨小兵. All rights reserved.
//

#import "TableTestVC.h"
#import <Masonry.h>
#import "XXBTableViewCell.h"
#import "XXBModel.h"
#import "UITableView+SelfSizing.h"
#define cellCount 100

@interface TableTestVC ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong)UITableView *tableView;
@property(nonatomic,strong)NSMutableArray *dataSourceArray;

@property (strong, nonatomic) NSMutableDictionary *offscreenCells;

@end

@implementation TableTestVC


- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_loadTableView];
}
-(void)p_loadTableView
{
    _tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain];
    [self.view addSubview:_tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_bottom);
    }];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView registerClass:[XXBTableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSourceArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return[tableView heightForCellWithIdentifier:@"cell"
                                cacheByIndexPath:indexPath
                                   configuration:^(XXBTableViewCell *cell) {
                                       return [self configureCell:cell atIndexPath:indexPath];
                                   }];
}
- (void)configureCell:(XXBTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.model = [self.dataSourceArray objectAtIndex:indexPath.row];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XXBTableViewCell *cell = [[XXBTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    cell.model = self.dataSourceArray[indexPath.row];
    return cell;
}

- (NSMutableArray *)dataSourceArray
{
    if (_dataSourceArray == nil)
    {
        NSString *string = @"１９７５年二、三月间，一个平平常常的日子，细蒙蒙的雨丝夹着一星半点的雪花，正纷纷淋淋地向大地飘洒着。时令已快到惊蛰，雪当然再不会存留，往往还没等落地，就已经消失得无踪无影了。黄土高原严寒而漫长的冬天看来就要过去，但那真正温暖的春天还远远地没有到来。在这样雨雪交加的日子里，如果没有什么紧要事，人们宁愿一整天足不出户。因此，县城的大街小巷倒也比平时少了许多嘈杂。街巷背阴的地方。冬天残留的积雪和冰溜子正在雨点的敲击下蚀化，石板街上到处都漫流着肮脏的污水。风依然是寒冷的。空荡荡的街道上，有时会偶尔走过来一个乡下人，破毡帽护着脑门，胳膊上挽一筐子土豆或萝卜，有气无力地呼唤着买主";
        int stringLength = (int)string.length;
        _dataSourceArray = [NSMutableArray array];
        for (int i =0 ; i< cellCount; i++)
        {
            XXBModel  * model = [XXBModel new];
            model.text1 = [string substringToIndex:arc4random_uniform(stringLength-50)+50];
            model.text2 = [string substringToIndex:arc4random_uniform(stringLength-50)+50];
            [_dataSourceArray addObject:model];
        }
    }
    return _dataSourceArray;
}
@end
