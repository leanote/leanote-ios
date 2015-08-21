//
//  NoteViewController.h
//  Leanote
//
//  Created by life on 15/5/31.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "Note.h"

#import "WPEditorViewController.h"
#import "CTAssetsPickerController.h"
#import "BaseViewController.h"

#import "Notebook.h"
#import "Tag.h"

@interface NoteViewController : WPEditorViewController <WPEditorViewControllerDelegate> // UIViewController <UISplitViewControllerDelegate, UITextViewDelegate>

// @interface TagController : WPViewController

@property (nonatomic, strong) Note *note;

@property (retain, nonatomic) Notebook *notebook;
@property (retain, nonatomic) Tag *tag;

@end