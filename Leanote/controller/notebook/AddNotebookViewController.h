//
//  AddNotebookViewController.h
//  Leanote
//
//  Created by life on 15/6/2.


#import <UIKit/UIKit.h>

#import "Note.h"
#import "Notebook.h"

#import "BaseViewController.h"

@interface AddNotebookViewController : UITableViewController

@property (nonatomic, strong) Notebook *notebook;

@end
