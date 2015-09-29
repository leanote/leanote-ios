
#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>
#import "Note.h"
#import "Notebook.h"
#import "BaseViewController.h"

// #import "SWTableViewCell.h"
#import "NotebookTagCell.h"
#import "CellInfo.h"

#import "CategoryProtocol.h"

@interface NotebookController : UITableViewController <NSFetchedResultsControllerDelegate, UISearchDisplayDelegate, UISearchBarDelegate, SWTableViewCellDelegate>
{
	id<CategoryProtocol> deleage;
}

@property(assign,nonatomic)id<CategoryProtocol> delegate;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
//- (IBAction)unwindToList:(UIStoryboardSegue *)segue;

- (void)initWithNote:(Note *)note fromSetting:(BOOL)fromSetting setSettingNotebook:(void (^)(Notebook *))setSettingNotebook;

@end
