//
//  Tag
//  Leanote
//
//  Created by life on 03/06/15.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>
#import "Note.h"
#import "Notebook.h"
#import "Tag.h"
#import "BaseViewController.h"

#import "NotebookTagCell.h"
#import "WPEditorViewController.h"
#import "CategoryProtocol.h"

@interface TagController : UITableViewController <NSFetchedResultsControllerDelegate, UISearchDisplayDelegate, UISearchBarDelegate>

@property(assign,nonatomic)id<CategoryProtocol> delegate;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
//- (IBAction)unwindToList:(UIStoryboardSegue *)segue;

- (void)initWithNote:(Note *)note fromSetting:(BOOL)fromSetting setSettingNotebook:(void (^)(Notebook *))setSettingNotebook;

@end
