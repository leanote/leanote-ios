//
//  NoteSettingsTableViewController.h
//  Leanote
//
//  Created by life on 15/6/2.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Note.h"

@interface NoteSettingsTableViewController : UITableViewController

- (instancetype)initWithNote:(Note *)note shouldHideStatusBar:(BOOL)shouldHideStatusBar;
@property (nonatomic, strong) Note *note;

@end
