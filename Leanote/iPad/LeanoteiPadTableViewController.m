//
//  MasterViewController.m
//  Leanote
//
//  Created by Wong Zigii on 15/9/19.
//  Copyright © 2015年 Leanote. All rights reserved.
//

#import "LeanoteiPadTableViewController.h"
#import "LeanoteiPadMasterCell.h"

@interface LeanoteiPadTableViewController ()

@end

@implementation LeanoteiPadTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"目录";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addNewNote)];
    [self.tableView registerClass:[LeanoteiPadMasterCell class] forCellReuseIdentifier:@"iPad_Cell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Action
- (void)addNewNote
{
    NSLog(@"%@",NSStringFromClass([self class]));
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title;
    switch (section) {
        case 0:
            title = @"笔记";
            break;
        case 1:
            title = @"笔记本";
            break;
        case 2:
            title = @"标签";
            break;
    }
    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"iPad_Cell"
                                                            forIndexPath:indexPath];
    cell.textLabel.text = @"12345";
    return  cell;
}

@end
