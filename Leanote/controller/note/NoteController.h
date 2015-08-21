//
//  MasterViewController.h
//  Leanote
//
//  Created by life on 5/9/15.
//  Copyright (c) 2015 Leanote.com. All rights reserved.

#import <UIKit/UIKit.h>

@class NoteViewController;

#import <CoreData/CoreData.h>
#import "Notebook.h"
#import "Tag.h"
#import "BaseViewController.h"


@interface NoteController : UITableViewController <NSFetchedResultsControllerDelegate, UISearchDisplayDelegate, UISearchBarDelegate>

@property (retain, nonatomic) Notebook *notebook;
@property (retain, nonatomic) Tag *tag;
@property BOOL isBlog;

@property (strong, nonatomic) NoteViewController *detailViewController;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end
