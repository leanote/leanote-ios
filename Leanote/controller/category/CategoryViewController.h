//
//  CategoryViewController.h
//  Leanote
//
//  Created by life on 15/7/19.
//  Copyright © 2015年 Leanote. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CategoryProtocol.h"
//#import "NotebookController.h"

@interface CategoryViewController : UIViewController<CategoryProtocol>

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIView *contentView;

- (IBAction)segmentChanged:(id)sender;

@end
