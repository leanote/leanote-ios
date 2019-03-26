/**
 笔记本
 */
#import "AppDelegate.h"

#import "NotebookController.h"

#import "Note.h"
#import "Notebook.h"
#import "NotebookService.h"
#import "UserService.h"

#import "NoteController.h"
#import "AddNotebookViewController.h"

#import "Leas.h"
#import "LeaAlert.h"


//#import "SWTableViewCell.h"


@interface NotebookController ()

// 从setting过来要用
@property (nonatomic, strong) Note *note;
@property (nonatomic) BOOL fromSetting;
@property (nonatomic, strong) Notebook *curNotebook;
@property (nonatomic, strong) NSString *curNotebookId;

@property (nonatomic, strong) UITableViewCell *curCell; // 选择的是当前笔记本
@property (nonatomic, strong) UITableViewCell *curCellForSearch; // 选择的是当前笔记本

@property (nonatomic, strong) void (^setSettingNotebook)(Notebook *);

@property BOOL isSelectOnSearch;
@property (nonatomic, strong) UIView *nomatchesView;;

@property (strong, nonatomic) NSFetchedResultsController *searchedResultsController;
@property BOOL noResult;

- (void)handleOrientationChangeNotification:(NSNotification *)notification;
- (void)notepadTitle;
- (NSUInteger)titleLength;
- (void)configureCell:(UITableViewCell *)cell forNote:(Note *)note;
- (NSFetchedResultsController *)fetchedResultsControllerWithPredicate:(NSString *)predicate;

@end

@implementation NotebookController


//@synthesize detailViewController = _detailViewController;
@synthesize managedObjectContext = _managedObjectContext;

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize searchedResultsController = _searchedResultsController;

// 如果是从笔记的配置选择进来的就是这个界面
- (void)initWithNote:(Note *)note fromSetting:(BOOL)fromSetting setSettingNotebook:(void (^)(Notebook *))setSettingNotebook
{
	self.note = note;
	self.fromSetting = fromSetting;
	self.setSettingNotebook = setSettingNotebook;
	
	self.curNotebookId = note.notebookId;
}

// 这个函数是系统自动来调用
// ios系统接收到ChangeTheme广播就会来自动调用
// notify就是广播的所有内容
- (void) recvBcast:(NSNotification *)notify
{
	// 必须要设空, 再reload
	_fetchedResultsController = nil;
	_searchedResultsController = nil;
	[self.tableView reloadData];
}

#pragma mark - Device Orientation Change Notification

- (void)handleOrientationChangeNotification:(NSNotification *)notification
{
    [self.tableView reloadData];
}

#pragma mark - ViewController Lifecycle

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

// 入口
- (void)viewDidLoad
{
    [super viewDidLoad];
	
	if (self.managedObjectContext == nil) {
		AppDelegate *appDelegate = (AppDelegate*)([UIApplication sharedApplication].delegate);
		self.managedObjectContext = appDelegate.managedObjectContext;
	}

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	// 成为听众一旦有广播就来调用self recvBcast:函数
	[nc addObserver:self selector:@selector(recvBcast:) name:@"changeUser" object:nil];
	
	// table的样式
	[self setTableStyle:self.tableView];
//	[self setTableStyle:self.searchDisplayController.searchResultsTableView];
	
	// cate
	if(self.delegate) {
		if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
			self.edgesForExtendedLayout = UIRectEdgeNone;
		}
	}
	
	self.searchDisplayController.searchBar.placeholder = NSLocalizedString(@"Search Notebook", nil);
	self.title = NSLocalizedString(@"Notebook", nil);
	
	
	// 我靠, 我不是故意的, 如果不加这两句, search bar动画会有突现, 突下的动画
	// http://stackoverflow.com/a/20975075/4269908
	[self setAutomaticallyAdjustsScrollViewInsets:YES];
	[self setExtendedLayoutIncludesOpaqueBars:YES];
	// 用这个也行, 但要隐藏的时候设为NO才行,不然会影响其它view的controller
//	self.navigationController.navigationBar.translucent = YES;
	
	//
	self.nomatchesView = [self iniNoResultView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// 非IPAD下, 如果当前是isSelectOnSearch才要隐藏
	if(self.isSelectOnSearch && !IS_IPAD) {
		NSLog(@"self.isSelectOnSearch viewWillAppear");
		[self.navigationController setNavigationBarHidden:YES animated:animated];
	}

	// 如果是setting, 不要+
	if(self.fromSetting) {
		self.navigationItem.rightBarButtonItem = nil;
	}
	else {
		[self.navigationItem.rightBarButtonItem setTarget:self];
		[self.navigationItem.rightBarButtonItem setAction:@selector(goAddNotebook:)];
	}
	
	[self beautifySearchBar];
	[self setBarStyle];
	
	// ios7
	if(self.noResult) {
		self.nomatchesView.hidden = NO;
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	if(self.fromSetting) {
		if(self.curNotebook) {
			self.setSettingNotebook(self.curNotebook);
		}
	}
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 取消
- (IBAction)goAddNotebook:(id)sender
{
	[self gotoAddNotebook:nil];
}

#pragma mark - Table View

// 多少组, 当前只有一个, 后期可以按日期来分组
// get the number of sections in the table view
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSFetchedResultsController *fetched = nil;
    
    if(tableView == self.tableView)
        fetched = self.fetchedResultsController;
    else
        fetched = self.searchedResultsController;
    
    return [[fetched sections] count];
}

// 每组有多少行
// get the number of rows in the table view section
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSFetchedResultsController *fetched = nil;
	BOOL isSearch;
	if(tableView == self.tableView) {
		fetched = self.fetchedResultsController;
		isSearch = NO;
	}
	else {
		fetched = self.searchedResultsController;
		isSearch = YES;
	}
	
	id <NSFetchedResultsSectionInfo> sectionInfo = [[fetched sections] objectAtIndex:section];
	NSInteger count = [sectionInfo numberOfObjects];
	
	if(!isSearch) {
		if (count == 0) {
			self.nomatchesView.hidden = NO;
			self.noResult = YES;
			self.searchDisplayController.searchBar.hidden = YES;
		}
		else {
			self.nomatchesView.hidden = YES;
			self.noResult = NO;
			self.searchDisplayController.searchBar.hidden = NO;
		}
	}
	return count;
}

// 每行显示什么
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	/*
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
	
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellIdentifier];
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
	*/
	
	static NSString *cellIdentifier2 = @"NotebookCell2";
	
	NotebookTagCell *cell = (NotebookTagCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier2];
	
	if (cell == nil) {
		cell = [[NotebookTagCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier2];
//		cell.leftUtilityButtons = [self leftButtons];
		cell.rightUtilityButtons = [self rightButtons];
		cell.delegate = self;
	}
	
    // get the right fetch controller
    NSFetchedResultsController *fetched = nil;
    if(tableView == self.tableView)
        fetched = self.fetchedResultsController;
    else
        fetched = self.searchedResultsController;

	Notebook *notebook = [fetched objectAtIndexPath:indexPath];
	[self configureCell:cell forNotebook:notebook];
	
    return cell;
}

// 行高
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	// get the right fetch controller
	NSFetchedResultsController *fetched = nil;
	if(tableView == self.tableView)
		fetched = self.fetchedResultsController;
	else
		fetched = self.searchedResultsController;
	
	// configure the cell
	Notebook *notebook = [fetched objectAtIndexPath:indexPath];
	
	return [NotebookTagCell rowHeightForContentProvider:[CellInfo getCellInfo:notebook] andWidth:CGRectGetWidth(tableView.frame)];
}

- (NSArray *)rightButtons
{
	NSMutableArray *rightUtilityButtons = [NSMutableArray new];
	[rightUtilityButtons sw_addUtilityButtonWithColor:
	 [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
												title:NSLocalizedString(@"Edit", nil)];
	[rightUtilityButtons sw_addUtilityButtonWithColor:
	 [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
												title:NSLocalizedString(@"Delete", nil)];
	
	return rightUtilityButtons;
}

- (NSArray *)leftButtons
{
	NSMutableArray *leftUtilityButtons = [NSMutableArray new];
	
	[leftUtilityButtons sw_addUtilityButtonWithColor:
	 [UIColor colorWithRed:0.07 green:0.75f blue:0.16f alpha:1.0]
												icon:[UIImage imageNamed:@"check.png"]];
	[leftUtilityButtons sw_addUtilityButtonWithColor:
	 [UIColor colorWithRed:1.0f green:1.0f blue:0.35f alpha:1.0]
												icon:[UIImage imageNamed:@"clock.png"]];
	[leftUtilityButtons sw_addUtilityButtonWithColor:
	 [UIColor colorWithRed:1.0f green:0.231f blue:0.188f alpha:1.0]
												icon:[UIImage imageNamed:@"cross.png"]];
	[leftUtilityButtons sw_addUtilityButtonWithColor:
	 [UIColor colorWithRed:0.55f green:0.27f blue:0.07f alpha:1.0]
												icon:[UIImage imageNamed:@"list.png"]];
	
	return leftUtilityButtons;
}


// 每行显示的信息
// configure the note table view cell
- (void)configureCell:(NotebookTagCell *)cell forNotebook:(Notebook *)notebook
{
	BOOL isSearch = self.searchDisplayController.active;
	[cell setCellInfo: [CellInfo getCellInfo:notebook]];
	if(self.fromSetting
	   && self.curNotebookId
	   && [notebook.notebookId isEqualToString:self.curNotebookId]) {
		NSLog(@"%@-%@", notebook.notebookId, notebook.title);
		
		if(isSearch) {
			self.curCellForSearch = cell;
		}
		else {
			self.curCell = cell;
		}
		
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	return;
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MM-dd-yyyy HH:mm"];
	NSRange cr = [notebook.title rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]];
	
	// 为了添加省略号
	if(cr.length != NSNotFound)
	{
		if(cr.location > [self titleLength])
		{
			NSUInteger len = MIN([notebook.title length], [self titleLength]);
			NSRange range = NSMakeRange(0, len);
			cell.textLabel.text = notebook.title; // [NSString stringWithFormat:@"%@...",[notebook.title substringWithRange:range]];
		}
		else
		{
			NSRange range = NSMakeRange(0, cr.location);
			cell.textLabel.text = notebook.title; // [notebook.title substringWithRange:range];
		}
	}
	else
	{
		NSUInteger len = MIN([notebook.title length], [self titleLength]);
		NSRange range = NSMakeRange(0, len);
		cell.textLabel.text = notebook.title; // [NSString stringWithFormat:@"%@...",[notebook.title substringWithRange:range]];
	}
	
	// 每行显示两种信息, 标题和数量
	// TODO
	cell.textLabel.font = [UIFont systemFontOfSize:18.0];
	cell.textLabel.textColor = [UIColor blackColor];
	
	// 来自setting, check it
	if(self.fromSetting) {
		NSString *curNotebookId = self.note.notebookId;
		if(self.curNotebook) {
			curNotebookId = self.curNotebook.notebookId;
		}
		if([curNotebookId isEqualToString:notebook.notebookId]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			self.curCell = cell;
			self.curNotebook = notebook;
			// [cell setHighlighted:YES]; 没用
		}
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", notebook.noteCount];
	}
}

// 可编辑, 因为可删除
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

// 单元格操作, 删除
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// 删除的操作
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSFetchedResultsController *fetched = nil;
        if(tableView == self.tableView)
            fetched = self.fetchedResultsController;
        else
            fetched = self.searchedResultsController;
		
		// 删除之, 这里应该设为Trash, 而不是删除 TODO
        NSManagedObjectContext *context = [fetched managedObjectContext];
		Notebook *notebook = [fetched objectAtIndexPath:indexPath];
        [context deleteObject:notebook];
        
        NSError *error = nil;
        if (![context save:&error])
        {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application,
            // although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

// 不可移动
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

// 点击事件, 这里为什么还需要? 不是有prepareForSegue吗?
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// get the right fetch controller
	NSFetchedResultsController *fetched = nil;
	if(tableView == self.tableView) {
		fetched = self.fetchedResultsController;
		self.isSelectOnSearch = NO;
	}
	else {
		fetched = self.searchedResultsController;
		// 证明是在搜索的时候, 那么是natigation hidden的状态
		self.isSelectOnSearch = YES;
	}
	
	// configure the cell
	Notebook *notebook = [fetched objectAtIndexPath:indexPath];
	
	// 选择笔记本
	if (self.fromSetting) {
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		
		// 当前cell取消之
		if(self.curCell) {
			self.curCell.accessoryType = UITableViewCellAccessoryNone;
		}
		if(self.curCellForSearch) {
			self.curCellForSearch.accessoryType = UITableViewCellAccessoryNone;
		}
		
		if(self.isSelectOnSearch) {
			self.curCellForSearch = cell;
		}
		else {
			// 重新设置当前cell
			self.curCell = cell;
		}
		
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		
		self.curNotebook = notebook;
		self.curNotebookId = notebook.notebookId;
		return;
	}
	
	if(self.delegate) {
//		NSLog(@"setNavigationBarHidden NO 1");
//		[self.navigationController setNavigationBarHidden:NO animated:NO];
	}
	
	// 从xib中生成
//	MasterViewController *viewController = [[MasterViewController alloc] initWithNibName:@"ipadNIB" bundle:nil];

	// 从storyboard生成controller
	// http://stackoverflow.com/questions/16134361/how-to-call-a-view-controller-programmatically
	NSString *storyboardName = @"MainStoryboard_iPhone";
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
	NoteController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Note"];
	
	vc.notebook = notebook;
	// 设置当前选择的笔记本, 没用了
	// [NotebookService setCurNotebook:notebook];
	// [vc setNotebook:notebook];
	
	vc.hidesBottomBarWhenPushed = YES;
	
	// 设置返回按钮
	// 在NoteController设置没用
	// This should be placed in the method that calls the ViewController titled "NewTitle". Right before the push or popViewController statement.
	// http://stackoverflow.com/questions/1449339/how-do-i-change-the-title-of-the-back-button-on-a-navigation-bar
	UIBarButtonItem *newBackButton =
	[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Notebook", nil)
									 style:UIBarButtonItemStyleBordered
									target:nil
									action:nil];
	[[self navigationItem] setBackBarButtonItem:newBackButton];
	
	
	[self.navigationController pushViewController:vc animated:YES];

	// [self presentViewController:vc2 animated:YES completion:nil];
	return;
	
	// 单纯实例化controller是没有storyboard的组件的(添加, 搜索), 只有一个table view
	NoteController *vc2 = [[NoteController alloc] init];
	vc2.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:vc2 animated:YES];
}

// 跳转到show note或 add note页面
// 得到点击的note
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    if([[segue identifier] isEqualToString:@"showNote"])
    {
        NSLog(@"[%@ %@] showNote", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        
        NSFetchedResultsController *fetched = nil;
        NSIndexPath *indexPath = nil;
        if([self.searchDisplayController isActive])
        {
            fetched = self.searchedResultsController;
            indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
        }
        else
        {
            fetched = self.fetchedResultsController;
            indexPath = [self.tableView indexPathForSelectedRow];
        }
        
        Note *note = [fetched objectAtIndexPath:indexPath];
        [[segue destinationViewController] setNote:note];
    }
    else if([[segue identifier] isEqualToString:@"addNote"])
    {
        NSLog(@"[%@ %@] addNote", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        [[segue destinationViewController] setManagedObjectContext:self.managedObjectContext];
    }
    
    [self.tableView reloadData];
}

// 实现这个控制器，最关键的还要实现Fetched Results Controller Delegate Methods。控制器与数据源连接后，控制器监视器会时刻监视着数据源，当数据源发生
// http://blog.csdn.net/jinkelei/article/details/6871403
/*
 - (void)controllerWillChangeContent:(NSFetchedResultsController *)controller；
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller；
 - (void)controller:(NSFetchedResultsController *)controller
 didChangeObject:(id)anObject
 atIndexPath:(NSIndexPath *)indexPath
 forChangeType:(NSFetchedResultsChangeType)type
 newIndexPath:(NSIndexPath *)newIndexPath；
 - (void)controller:(NSFetchedResultsController *)controller
 didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
 atIndex:(NSUInteger)sectionIndex
 forChangeType:(NSFetchedResultsChangeType)type；
*/
#pragma mark - Fetched results controller


- (NSFetchedResultsController *) fetchedResultsControllerWithPredicate:(NSString *)q
{
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notebook"
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];
	
	NSString *userId = [UserService getCurUserId];
	NSString *defaultQ = [NSString stringWithFormat:@"localIsDelete == NO AND userId='%@'", userId];
	if(!q) {
		q = defaultQ;
	}
	else {
		q = [NSString stringWithFormat:@"%@ and %@", q, defaultQ];
	}
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:q];
	
	// set the search predicate
	[fetchRequest setPredicate:predicate];
	
	// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"updatedTime" ascending:NO];
	NSSortDescriptor *sortDescriptorSeq = [NSSortDescriptor sortDescriptorWithKey:@"seq" ascending:YES];

	NSArray *sortDescriptors = @[sortDescriptor, sortDescriptorSeq];

	[fetchRequest setSortDescriptors:sortDescriptors];
	
	// cache
	NSString *cacheName = @"Notebook";
	if( predicate ) cacheName = nil;
	
	// Edit the section name key path and cache name if appropriate.
	// nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil
		cacheName:cacheName];
	
	// 很有用, 当删除时, 将controller的表格当行也删除掉
	aFetchedResultsController.delegate = self;
	
	NSFetchedResultsController *fetchedResultsController = aFetchedResultsController;
	
	NSError *error = nil;
	if (![fetchedResultsController performFetch:&error])
	{
		// Replace this implementation with code to handle the error appropriately.
		// abort() causes the application to generate a crash log and terminate.
		// You should not use this function in a shipping application, although
		// it may be useful during development.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
	
	return fetchedResultsController;
	
}

// 终于理解了
- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController)
    {
        return _fetchedResultsController;
    }
    
	self.fetchedResultsController = [self fetchedResultsControllerWithPredicate:nil];
	return _fetchedResultsController;
}

- (NSFetchedResultsController *)searchedResultsController
{
    if( _searchedResultsController )
    {
        return _searchedResultsController;
    }
    
	self.searchedResultsController = [self fetchedResultsControllerWithPredicate:nil];
    return _searchedResultsController;
}

// 当改变控制器管理的对象后引起了列表section的变化，此时监视器就会调用这个协议函数。
- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{

    UITableView *tableView = nil;
    
    if(controller == self.fetchedResultsController)
        tableView = self.tableView;
    else
        tableView = self.searchDisplayController.searchResultsTableView;
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
    
}

// 当fetchedResultsController发现指定的对象有改变时，监视器会调用这个协议方法。这里改变的类型从列表中体现有 更新、插入、删除或者行的移动。因此这个方法要实现所有的这些方法，以应对任何一种改变。下面是这个方法的标准实现
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type // 改变的类型
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = nil;
    
    if(controller == self.fetchedResultsController)
        tableView = self.tableView;
    else
        tableView = self.searchDisplayController.searchResultsTableView;
    
    switch(type)
    {
        case NSFetchedResultsChangeInsert: // 插入
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete: // 删除
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate: // 改变
        {
            Notebook *notebook = [controller objectAtIndexPath:indexPath];
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] forNotebook:notebook];

        }
            break;
		
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

// 数据将要改变
// 当控制器监控的数据发生改变时，如对象被删除，有插入，更新等，监视器会在数据发生改变前意识到这个情况，此时就会调用这个函数。往往我们用列表的形式表现数据，此时意味着屏幕上的数据即将过时，因为数据马上要改变了，这是这个协议方法的工作就是通知列表数据马上要更新的消息，往往代码是这样实现的。
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    UITableView *tableView = nil;
    if(controller == self.fetchedResultsController)
        tableView = self.tableView;
    else
        tableView = self.searchDisplayController.searchResultsTableView;
    
    [tableView beginUpdates];
}

// 已经改变
// 当fetchedResultsController完成对数据的改变时，监视器会调用这个协议方法。在上面提到的情况，这个方法要通知列表数据已经完成，可以更新显示的数据这个消息，因此通常的实现是这样的
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    UITableView *tableView = nil;
    if(controller == self.fetchedResultsController)
        tableView = self.tableView;
    else
        tableView = self.searchDisplayController.searchResultsTableView;
	
    [tableView endUpdates];
}

#pragma mark - Title Length Method

- (NSUInteger)titleLength
{
    // default table view title length
    NSUInteger titleLen = 24;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        titleLen = 24;
    }
    else
    {
        // if we are a phone and turned landscape we want to give the user a bit more
        // title info
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if(UIInterfaceOrientationIsLandscape(orientation))
            titleLen = 36;
    }

    return titleLen;
}

// ipad下search bar上移, 但navigation却不隐藏
// ipad下模拟没有navigationController, 但是SWTableViewCell selectCell 要用到
// http://stackoverflow.com/a/5860412/4269908
/*
- (UINavigationController *)navigationController {
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		NSString *sourceString = [[NSThread callStackSymbols] objectAtIndex:1];
		// Example: 1   UIKit                               0x00540c89 -[UIApplication _callInitializationDelegatesForURL:payload:suspended:] + 1163
		NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
		NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
		[array removeObject:@""];
		
		// Array[3] == class caller
		if([array[3] isEqualToString:@"UISearchDisplayController"]) {
			return nil;
		}
	}
	return [super navigationController];
}
*/

#pragma mark - UISearchDisplayDelegate Methods

 - (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
	[self beautifySearchBar:controller];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	NSString *q = [NSString stringWithFormat:@"title contains[cd] '%@'", searchString];
    self.searchedResultsController = [self fetchedResultsControllerWithPredicate:q];

    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

// 开始搜索, 从点击uisearchbar开始
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
	if (!IS_IPAD) {
		
		[self setBarStyleBlack];
	
		// cate
		if(self.delegate) {
			// 1. 这里控制动画
			
			[UIView animateWithDuration:0.25f animations:^{
				CGRect frame = self.view.frame;
				frame.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height;
				self.view.frame = frame;
			}];
			NSLog(@"setNavigationBarHidden YES!!!!!!!!!");
			[self.navigationController setNavigationBarHidden:YES animated:YES];
			
			CGRect frame = self.view.frame;
			frame.size.height = [self.delegate getSearchedViewHeight];
			self.view.frame = frame;
		}
		
		self.isSelectOnSearch = YES;
	
	}
}
// 结束搜索, 点击取消
- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    self.searchedResultsController.delegate = nil;
    self.searchedResultsController = nil;
	
	// 重新载入数据
	// [controller.searchResultsTableView reloadData]; // 不能有这个, 这个没用!! 有这个会导致选择笔记有问题
    [self.tableView reloadData];
	
	if (!IS_IPAD) {
	
		[self restoreBarStyle];
		
		// cate
		if(self.delegate) {
			// 2. 还原
			
			[UIView animateWithDuration:0.25f animations:^{
				CGRect frame = self.view.frame;
				frame.origin.y = 64;
				self.view.frame = frame;
			} completion:^(BOOL finished) {
				if(finished) {
					CGRect frame = self.view.frame;
					frame.size.height = [self.delegate getCancelSearchViewHeight];
					self.view.frame = frame;
				}
			}];
			
			[self.navigationController setNavigationBarHidden:NO animated:YES];
		}
		self.isSelectOnSearch = NO;
		
	}
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
//    self.searchedResultsController = nil;
}

// 开始要输入了
-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
	// 之前是放在这里的, 现在不放在这里, 因为搜索后, 点击选项也会执行这个
	return YES;
}
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:YES animated:YES];
}






#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
	switch (index) {
		case 0:
			NSLog(@"check button was pressed");
			break;
		case 1:
			NSLog(@"clock button was pressed");
			break;
		case 2:
			NSLog(@"cross button was pressed");
			break;
		case 3:
			NSLog(@"list button was pressed");
		default:
			break;
	}
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
	NSFetchedResultsController *fetched = nil;
	NSIndexPath *indexPath;
	if(!self.searchDisplayController.isActive) {
		fetched = self.fetchedResultsController;
		indexPath = [self.tableView indexPathForCell:cell];
	}
	else {
		fetched = self.searchedResultsController;
		indexPath = [self.searchDisplayController.searchResultsTableView indexPathForCell:cell];
	}
	
	// 删除之, 这里应该设为Trash, 而不是删除 TODO
	Notebook *notebook = [fetched objectAtIndexPath:indexPath];
	
	switch (index) {
		// 编辑, 跳转到AddNotebookController.h
		case 0:
		{
			[self gotoAddNotebook:notebook];
			// 关闭之
			[cell hideUtilityButtonsAnimated:YES];
			break;
		}
		// 删除
		case 1:
		{
			if([notebook.noteCount integerValue] > 0) {
				[LeaAlert showAlertWithTitle:NSLocalizedString(@"Tip", nil)
									message:NSLocalizedString(@"The notebook has notes, please delete all notebooks' notes before", nil)
						  withSupportButton:NO
							 okPressedBlock:^(UIAlertView *alertView) {
					 // 关闭之
					 [cell hideUtilityButtonsAnimated:YES];
				 }];
			}
			else {
				[Leas.notebook deleteNotebok:notebook success:nil fail:nil];
				// [context deleteObject: notebook];

				[Leas.notebook pushAndWrite:notebook success:^{
					// tips 提示同步成功
					[self showSuccessMsg:NSLocalizedString(@"Synchronize deleted notebook successful", nil)];
				} fail:^(id ret) {
					[self showErrorMsg:NSLocalizedString(@"Synchronize deleted notebook failed", nil) ret:ret];
				}];
				
				// 关闭之
				[cell hideUtilityButtonsAnimated:YES];
			}
			
			break;
		}
		default:
			break;
	}
	
	
}

 // #pragma arguments
-(void) gotoAddNotebook:(Notebook *) notebook
{
	AddNotebookViewController *vc = [[AddNotebookViewController alloc] init];
	vc.notebook = notebook;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
	[self.navigationController presentViewController:navController animated:YES completion:nil];
}

@end
