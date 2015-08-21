//
//  Tag
//  Leanote
//
//  Created by life on 03/06/15.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "AppDelegate.h"

#import "TagController.h"

#import "Note.h"
#import "Notebook.h"
#import "TagService.h"
#import "UserService.h"
#import "Leas.h"
#import "NoteController.h"

@interface TagController ()

// 从setting过来要用
@property (nonatomic, strong) Note *note;
@property (nonatomic) BOOL fromSetting;
@property (nonatomic, strong) Notebook *curNotebook;
@property (nonatomic, strong) SWTableViewCell *curCell;
@property (nonatomic, strong) void (^setSettingNotebook)(Notebook *);
@property BOOL noResult;

@property (nonatomic, strong) Tag *curTag;

@property BOOL isSelectOnSearch;

@property (nonatomic, strong) UIView *nomatchesView;

@property (strong, nonatomic) NSFetchedResultsController *searchedResultsController;

- (void)handleOrientationChangeNotification:(NSNotification *)notification;
- (NSUInteger)titleLength;
- (void)configureCell:(UITableViewCell *)cell forNote:(Note *)note;
- (NSFetchedResultsController *)fetchedResultsControllerWithPredicate:(NSString *)predicate;

@end


@implementation TagController

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
}

#pragma mark - Device Orientation Change Notification

- (void)handleOrientationChangeNotification:(NSNotification *)notification
{
    [self.tableView reloadData];
}

// 这个函数是系统自动来调用
// ios系统接收到ChangeTheme广播就会来自动调用
// notify就是广播的所有内容
- (void) recvBcast:(NSNotification *)notify
{
	static int index;
	NSLog(@"recv tag %d", index++);
	
	// 必须要设空, 再reload
	_fetchedResultsController = nil;
	_searchedResultsController = nil;
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
	
	// cate
	if(self.delegate) {
		if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
			self.edgesForExtendedLayout = UIRectEdgeNone;
		}
	}
	
	self.searchDisplayController.searchBar.placeholder = NSLocalizedString(@"Search Tag", nil);
	self.title = NSLocalizedString(@"Tag", nil);
	
	self.nomatchesView = [self iniNoResultView:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self beautifySearchBar];
	[self setBarStyle];
	
	if(self.isSelectOnSearch) {
		NSLog(@"self.isSelectOnSearch viewWillAppear");
		[self.navigationController setNavigationBarHidden:YES animated:animated];
	}
	
	// ios7
	if(self.noResult) {
		self.nomatchesView.hidden = NO;
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	if(self.fromSetting) {
		if(self.curNotebook) {
			self.setSettingNotebook(self.curNotebook);
		}
	}
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
	// get the right fetch controller
	NSFetchedResultsController *fetched = nil;
	if(tableView == self.tableView)
		fetched = self.fetchedResultsController;
	else
		fetched = self.searchedResultsController;
	
	Tag *tag = [fetched objectAtIndexPath:indexPath];
	
    static NSString *cellIdentifier = @"NotebookCell";
	
	/*
	// 自带的cell
	
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
	
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
	                                      reuseIdentifier:cellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	
	cell.textLabel.text = tag.title;
	return cell;
	*/
	
	// 自定义cell
	
	NotebookTagCell *cell = (NotebookTagCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[NotebookTagCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
		cell.rightUtilityButtons = [self rightButtons];
		cell.delegate = self;
	}
	 
    [self configureCell:cell forTag:tag];
    
    return cell;
}

- (NSArray *)rightButtons
{
	NSMutableArray *rightUtilityButtons = [NSMutableArray new];
	
	[rightUtilityButtons sw_addUtilityButtonWithColor:
	 [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
												title:NSLocalizedString(@"Delete", nil)];
	
	return rightUtilityButtons;
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

	Tag *tag = [fetched objectAtIndexPath:indexPath];
	self.curCell = cell;
	switch (index) {
		case 0:
		{
			self.curTag = tag;
			
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil)
															message:NSLocalizedString(@"Are you sure?", nil)
														   delegate:self
												  cancelButtonTitle:NSLocalizedString(@"NO", nil)
												  otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
			[alert show];
			break;
		}
		default:
			break;
	}
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
	Tag *tag = [fetched objectAtIndexPath:indexPath];
	
	return [NotebookTagCell rowHeightForContentProvider:[CellInfo getCellInfoByTag:tag] andWidth:CGRectGetWidth(tableView.frame)];
}

// 每行显示的信息
// configure the note table view cell
- (void)configureCell:(NotebookTagCell *)cell forTag:(Tag *)tag
{
	[cell setCellInfo: [CellInfo getCellInfoByTag:tag]];
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
		// 删除之
		Tag *tag = [fetched objectAtIndexPath:indexPath];
		self.curTag = tag;
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil)
														message:NSLocalizedString(@"Are you sure?", nil)
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"NO", nil)
											  otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
		[alert show];
		return;
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	if([title isEqualToString:NSLocalizedString(@"NO", nil)])
	{
		NSLog(@"Nothing to do here");
	}
	else if([title isEqualToString:NSLocalizedString(@"YES", nil)])
	{
		NSLog(@"Delete the cell");
		
		[Leas.tag deleteTag:self.curTag success:^{
			// tips 提示同步成功
			[self showSuccessMsg:NSLocalizedString(@"Synchronize deleted tag successful", nil)];
		} fail:^(id ret) {
			[self showErrorMsg:NSLocalizedString(@"Synchronize deleted tag failed", nil) ret:ret];
		}];
//		[self showSuccessMsg:NSLocalizedString(@"Delete tag successful", nil)];
	}
	
	// 关闭之
	[self.curCell hideUtilityButtonsAnimated:YES];
	[self setEditing:NO animated:YES];
}


// 不可移动
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

// 点击事件
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
	Tag *tag = [fetched objectAtIndexPath:indexPath];
	
	// 从xib中生成
//	MasterViewController *viewController = [[MasterViewController alloc] initWithNibName:@"ipadNIB" bundle:nil];

	// 从storyboard生成controller
	// http://stackoverflow.com/questions/16134361/how-to-call-a-view-controller-programmatically
	NSString *storyboardName = @"MainStoryboard_iPhone";
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
	NoteController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Note"];
	vc.tag = tag;
	// 设置当前选择的笔记本

	// [vc setNotebook:notebook];
	
	vc.hidesBottomBarWhenPushed = YES;
	
	// 设置返回按钮
	// 在NoteController设置没用
	// This should be placed in the method that calls the ViewController titled "NewTitle". Right before the push or popViewController statement.
	// http://stackoverflow.com/questions/1449339/how-do-i-change-the-title-of-the-back-button-on-a-navigation-bar
	UIBarButtonItem *newBackButton =
	[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Tag", nil)
									 style:UIBarButtonItemStyleBordered
									target:nil
									action:nil];
	[[self navigationItem] setBackBarButtonItem:newBackButton];
	
	
	[self.navigationController pushViewController:vc animated:YES];
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


#pragma mark - Fetched results controller

- (NSFetchedResultsController *) fetchedResultsControllerWithPredicate:(NSString *)q
{
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tag"
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
	
	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];
	
	NSString *userId = [UserService getCurUserId];
	NSString *defaultQ = [NSString stringWithFormat:@"localIsDelete == NO AND userId='%@'", userId];
	if([Common isBlankString:q]) {
		q = defaultQ;
	}
	else {
		q = [NSString stringWithFormat:@"%@ and %@", q, defaultQ];
	}
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:q];
	[fetchRequest setPredicate:predicate];
	
	// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"updatedTime" ascending:NO];
	NSSortDescriptor *sortDescriptorTitle = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];

	NSArray *sortDescriptors = @[sortDescriptor, sortDescriptorTitle];

	[fetchRequest setSortDescriptors:sortDescriptors];
	
	// cache
	NSString *cacheName = @"Tag";
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
            Tag *tag = [controller objectAtIndexPath:indexPath];
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] forTag:tag];

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

#pragma mark - UISearchDisplayDelegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{

    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    NSString *searchPredicate = [NSString stringWithFormat:@"title contains[cd] '%@'", searchString];
    self.searchedResultsController = [self fetchedResultsControllerWithPredicate:searchPredicate];

    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
	[self setBarStyleBlack];
	// cate
	if(self.delegate) {
		// 1. 这里控制动画
		
		[UIView animateWithDuration:0.25f animations:^{
			CGRect frame = self.view.frame;
			frame.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height;
			self.view.frame = frame;
		}];
		
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		
		CGRect frame = self.view.frame;
		frame.size.height = [self.delegate getSearchedViewHeight];
		self.view.frame = frame;
	}
	self.isSelectOnSearch = YES;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    self.searchedResultsController.delegate = nil;
    self.searchedResultsController = nil;
	
    [controller.searchResultsTableView reloadData];
    [self.tableView reloadData];
	
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

#pragma mark - UISearchBarDelegate Methods

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    //self.searchedResultsController = nil;
}

// 开始要输入了
-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
	return YES;
}

@end
