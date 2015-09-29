// 笔记列表

#import "AppDelegate.h"

#import "NoteCell.h"

#import "NoteController.h"
#import "NoteViewController.h"
#import "Note.h"
// #import "NoteService.h"
#import "Notebook.h"
// #import "NotebookService.h"
#import "Leas.h"

#import "LeaAlert.h"
#import "ApiMsg.h"
#import "SVProgressHUD.h"

#import "SyncService.h"
#import "UserService.h"

#import "LeaWebViewController.h"

#import <SGNavigationProgress/UINavigationController+SGProgress.h>

@interface NoteController ()<SWTableViewCellDelegate>

@property (strong, nonatomic) NSIndexPath *indexPathToBeDeleted;
@property (strong, nonatomic) NSFetchedResultsController *searchedResultsController;
@property (strong, nonatomic) UITableView *curTableView;
@property (strong, nonatomic) Note *curNote;
@property (strong, nonatomic) NSFetchedResultsController *curFetched;
@property (strong, nonatomic) UIView *nomatchesView;
@property BOOL noResult;

- (void)handleOrientationChangeNotification:(NSNotification *)notification;
- (void)noteTitle;
- (NSUInteger)titleLength;
- (void)configureCell:(UITableViewCell *)cell forNote:(Note *)note;
//- (NSFetchedResultsController *)fetchedResultsControllerWithPredicate:(NSPredicate *)predicate;
@property (nonatomic, strong) SWTableViewCell *curCell;
@end

@implementation NoteController

@synthesize detailViewController = _detailViewController;

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize searchedResultsController = _searchedResultsController;

#pragma mark - Device Orientation Change Notification
- (void)handleOrientationChangeNotification:(NSNotification *)notification
{
	[self.tableView reloadData];
}

#pragma mark - Leanote Title

// 显示标题 note(数量)
- (void)noteTitle
{
	NSFetchedResultsController *fetched = nil;
	
	// 判断是否是搜索显示的数量
	if([self.searchDisplayController isActive])
		fetched = self.fetchedResultsController;
	else
		fetched = self.searchedResultsController;
	
	id <NSFetchedResultsSectionInfo> sectionInfo = [fetched sections][0];
	
	NSString *titlePrefix = NSLocalizedString(@"Note", @"");
	
	if(self.isBlog) {
		//		self.title = NSLocalizedString(@"Post", nil);
//		self.navigationItem.title = NSLocalizedString(@"Post", nil);
		titlePrefix = NSLocalizedString(@"Post", nil);
	}
	else if (self.notebook) {
		titlePrefix = self.notebook.title;
	}
	else if(self.tag) {
		titlePrefix = self.tag.title;
	}
	
	// 以后, 这里的Note换成Notebook名称
	if([sectionInfo numberOfObjects] > 0) {
//		self.title = ;
		self.navigationItem.title = [NSString stringWithFormat:@"%@ (%lu)", titlePrefix, (unsigned long)[sectionInfo numberOfObjects]];
	}
	else {
		self.navigationItem.title = titlePrefix;
	}
}

// 这个函数是系统自动来调用
// ios系统接收到ChangeTheme广播就会来自动调用
// notify就是广播的所有内容
- (void) recvBcast:(NSNotification *)notify
{
	/*
	// 取得广播内容
	NSDictionary *dict = [notify userInfo];
	NSString *name = [dict objectForKey:@"ThemeName"];
	UIColor *c = [dict objectForKey:@"ThemeColor"];
	
	self.title = name;
	self.view.backgroundColor = c;
	*/
	
	// 必须要设空, 再reload
	_fetchedResultsController = nil;
	_searchedResultsController = nil;
	[self.tableView reloadData];
	
	[self noteTitle];
	
	NSLog(@"关闭进度条, 取消下拉刷新");
	
	// 关闭进度
	[self.navigationController hideProgress];
	[self.navigationController setSGProgressPercentage:0 andTintColor:[UIColor whiteColor]];
	
	// 取消下拉刷新
	if(self.refreshControl) {
		[self.refreshControl endRefreshing];
	}
}

#pragma mark - ViewController Lifecycle

// 入口
- (void)viewDidLoad
{
	[super viewDidLoad];

	// Do any additional setup after loading the view, typically from a nib.
	
	[self noteTitle];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	// 成为听众一旦有广播就来调用self recvBcast:函数
	[nc addObserver:self selector:@selector(recvBcast:) name:@"changeUser" object:nil];
	
	// refresh control
	// 初始化UIRefreshControl
	UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
	
	if(!self.notebook && !self.tag) {
		[refreshControl addTarget:self action:@selector(sync:) forControlEvents:UIControlEventValueChanged];
		[self restorePullTitle:refreshControl];
		[self setRefreshControl:refreshControl];
	}
	
	// 放这里
	[self.tableView reloadData];
	
	// table的样式
	[self setTableStyle:self.tableView];
	
	// isBlog ?
	if(self.isBlog) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Visit Blog", nil) style:UIBarButtonItemStylePlain target:self action:@selector(visitMyBlog)];
		self.searchDisplayController.searchBar.placeholder = NSLocalizedString(@"Search Post", nil);
	}
	else {
		self.searchDisplayController.searchBar.placeholder = NSLocalizedString(@"Search Note", nil);
	}
	
	self.nomatchesView = [self iniNoResultView:self.tableView];
	// self.nomatchesView.hidden = NO;
//	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 200)];
//	UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 200, 20)];
//	labelView.text = @"TEST";
//	[headerView addSubview:labelView];
//	
//	[self.tableView addSubview:headerView];
}

-(void) visitMyBlog
{
	[self visitUrl:nil];
}
-(void) visitUrl:(Note *)note
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    LeaWebViewController *webViewController = [sb instantiateViewControllerWithIdentifier:@"LeaWebViewController"];
	webViewController.needsLogin = YES;
	User *user = [UserService getCurUser];
	webViewController.host = user.host;
	webViewController.email = user.email;
	webViewController.pwd = user.pwd;
	webViewController.url = note ? [NSURL URLWithString:[UserService getPostUrl:note.serverNoteId]]: [NSURL URLWithString:[UserService getMyBlogUrl]];
	
	UIBarButtonItem *newBackButton =
	[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(self.isBlog ? @"Post" : @"Note", nil)
									 style:UIBarButtonItemStyleBordered
									target:nil
									action:nil];
	[self.navigationItem setBackBarButtonItem:newBackButton];
	
	[self.navigationController pushViewController:webViewController animated:YES];
}

- (void) restorePullTitle:(UIRefreshControl *)refreshControl
{
	NSAttributedString *title = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Pull to synchronize", "")
																attributes: @{
																			  NSForegroundColorAttributeName:[UIColor blackColor]
																			  }];
	refreshControl.attributedTitle = [[NSAttributedString alloc]initWithAttributedString:title];
}

- (void)setPullTitleSyncing
{
	NSAttributedString *title = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Synchronizing", "")
																attributes: @{
																			  NSForegroundColorAttributeName:[UIColor blackColor]
																			  }];
	self.refreshControl.attributedTitle = [[NSAttributedString alloc]initWithAttributedString:title];
}

// 判断是否是第一次打开该界面
- (void) loginAndSync
{
	BOOL inited = [UserService getOpenInited];
	if (!inited) {
		BOOL isFirtSync = [[UserService getLastSyncUsn] integerValue] < 1;
		[UserService setOpenInited:YES];
		[self incSync:nil completeNeedAlert:isFirtSync beforeNeedLoading:isFirtSync];
	}
}

// completeNeedAlert结束后是否要alertr提示
- (void) incSync:(id)sender completeNeedAlert:(BOOL)completeNeedAlert beforeNeedLoading:(BOOL)beforeNeedLoading
{
	if(sender) {
		[self setPullTitleSyncing];
	}
	
	// 第一次登录进来, 要提示正在同步
	if(beforeNeedLoading) {
		[Common showProgressWithStatus:NSLocalizedString(@"Synchronizing...", nil)];
	}
	
	[SyncService incrSync:^(BOOL ok) {
		if(sender) {
			[self restorePullTitle:self.refreshControl];
		}
		
		if(completeNeedAlert) {
			[Common hideProgress];
			
			if(ok) {
				[self showSuccessMsg:NSLocalizedString(@"Synchronize successful", nil)];
			}
			else {
				[self showErrorMsg:NSLocalizedString(@"Synchronize failed", @"") ret:nil];
			}
		}
		
		if(sender) {
			[(UIRefreshControl *)sender endRefreshing];
		}
		
	} progress:^(int p) {
		// 表示正在有同步, 不要再同步
		if(p == -1) {
			[self showSuccessMsg:NSLocalizedString(@"Synchronizing...", @"")];
			[self.navigationController hideProgress];
			return;
		// 表示同步失败
		} else if(p == -2) {
			// 必须要延迟啊, 不然showErrorMsg会很快消失
			[Common setTimeout:500 callback:^{
				[self.navigationController hideProgress];
				[self.navigationController setSGProgressPercentage:0 andTintColor:[UIColor whiteColor]];
			}];
			return;
		}
		[self.navigationController setSGProgressPercentage:p andTintColor:[UIColor whiteColor]];
		if(p >= 100) {
			[self.navigationController hideProgress];
		}
		
	}];
	
	// https://github.com/sgryschuk/SGNavigationProgress
	//	[self.navigationController showSGProgressWithDuration:1 andTintColor:[UIColor whiteColor]];
	//	[self.navigationController setSGProgressPercentage:50 andTintColor:[UIColor whiteColor]];
}

// 同步
- (void)sync:(id)sender
{
	[self incSync:sender completeNeedAlert:YES beforeNeedLoading:NO];
}

- (void)awakeFromNib
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		self.clearsSelectionOnViewWillAppear = NO;
		self.preferredContentSize = CGSizeMake(320.0, 600.0);
	}
	[super awakeFromNib];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self beautifySearchBar];
	
	// 从cate过来的
	if((self.notebook || self.tag)/* && !self.isSelectOnSearch*/) {
		[self.navigationController setNavigationBarHidden:NO animated:animated];
		[self restoreBarStyle];
	}
	else {
		[self setBarStyle];
	}

	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	// 通知, TODO 应该不要的
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleOrientationChangeNotification:)
												 name:UIDeviceOrientationDidChangeNotification
											   object:nil];
	
	// ios7
	if(self.noResult) {
		self.nomatchesView.hidden = NO;
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	// 显示status bar
	// 防止编辑时直接回到该页
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

	[self loginAndSync];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
//	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
//	self.nomatchesView.hidden = NO;
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
	
	// configure the cell
	Note *note = [fetched objectAtIndexPath:indexPath];
	
	static NSString *cellIdentifier2 = @"NoteCell2";
	NoteCell *cell2 = [tableView dequeueReusableCellWithIdentifier:cellIdentifier2];
	if (cell2 == nil) {
		cell2 = [[NoteCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier2];
		cell2.rightUtilityButtons = [self rightButtons:[note.isBlog boolValue]];
		cell2.delegate = self;
//		cell2.accessibilityLabel = [note.isBlog boolValue] ? @"blog" : @"no";
	}
	[cell2 setNote:note];
	
	return cell2;
}

- (NSArray *)rightButtons:(BOOL)isBlog
{
	NSMutableArray *rightUtilityButtons = [NSMutableArray new];
	
	if(isBlog) {
		[rightUtilityButtons sw_addUtilityButtonWithColor:
		 [UIColor colorWithRed:0.78f green:0.78f blue:0.8f alpha:1.0]
												title:NSLocalizedString(@"Visit Post", nil)];
	}
	
	[rightUtilityButtons sw_addUtilityButtonWithColor:
	 [UIColor colorWithRed:1.0f green:0.231f blue:0.188 alpha:1.0f]
												title:NSLocalizedString(@"Delete", nil)];
	
	return rightUtilityButtons;
}

#pragma mark - SWTableViewDelegate

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
	
	Note *note = [fetched objectAtIndexPath:indexPath];
	self.curNote = note;
	self.curFetched = fetched;
	self.curCell = cell;
	
	if(![note.isBlog boolValue]) {
		[self deleteNote];
	}
	// 这里有问题, 之前是博客, 那么是有visit blog的, 后来取消blog, 还是会有visit blog
	else {
		if(index == 0) {
			if([note.isBlog boolValue]) {
				[self visitUrl:note];
			}
			// 关闭之
			[self.curCell hideUtilityButtonsAnimated:YES];
		}
		else {
			[self deleteNote];
		}
	}
}

- (void) deleteNote
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"")
													message:NSLocalizedString(@"Are you sure?", @"")
												   delegate:self
										  cancelButtonTitle:NSLocalizedString(@"NO", @"")
										  otherButtonTitles:NSLocalizedString(@"YES", @""), nil];
	alert.delegate = self;
	[alert show];
}

// 删除之后走这里
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
		[Leas.note deleteNote:self.curNote success:^{
			[self showSuccessMsg:NSLocalizedString(@"Synchronize deleted note successful", @"")];
		} fail:^(id ret) {
			[self showErrorMsg:NSLocalizedString(@"Synchronize deleted note failed", nil) ret:ret];
		}];
	}
	
	[self setEditing:NO animated:YES];
	
	// 关闭之
	[self.curCell hideUtilityButtonsAnimated:YES];
}



// 每行显示的信息
// configure the note table view cell
- (void)configureCell:(UITableViewCell *)cell
			  forNote:(Note *)note
{
	NoteCell *cell2 = (NoteCell *) cell;
	cell2.note = note;
	
	// 因为可能blog有改动, 这里需要重新设置下
	cell2.rightUtilityButtons = [self rightButtons:[note.isBlog boolValue]];
	cell2.delegate = self;
	
	return;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	// get the right fetch controller
	NSFetchedResultsController *fetched = nil;
	if(tableView == self.tableView)
		fetched = self.fetchedResultsController;
	else
		fetched = self.searchedResultsController;
	
	// configure the cell
	Note *note = [fetched objectAtIndexPath:indexPath];
	
	return [NoteCell rowHeightForContentProvider:note andWidth:CGRectGetWidth(tableView.frame)];
}

// 可编辑, 因为可删除
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

// 单元格操作, 删除
// 这里已经没用了, 不会走这里
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.indexPathToBeDeleted = indexPath;
	self.curTableView = tableView;
	
	// 删除的操作
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		NSFetchedResultsController *fetched = nil;
		if(tableView == self.tableView)
			fetched = self.fetchedResultsController;
		else
			fetched = self.searchedResultsController;
		
		self.curFetched = fetched;
		self.curNote =[fetched objectAtIndexPath:indexPath];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"")
														message:NSLocalizedString(@"Are you sure?", @"")
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"NO", @"")
											  otherButtonTitles:NSLocalizedString(@"YES", @""), nil];
		[alert show];
	}
}

// 不可移动
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	// The table view should not be re-orderable.
	return YES;
}

// 点击事件, 这里为什么还需要? 不是有prepareForSegue吗?
// 因为搜索的关系, 没有绑定, 这里要手工跳转
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// we only want to do this if the user is doing a search
//	if(tableView == self.searchDisplayController.searchResultsTableView)
	[self performSegueWithIdentifier:@"showNote" sender:self];
}

// 跳转到show note或 add note页面
// 得到点击的note
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	// 修改笔记
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
	
	// 添加笔记
	else if([[segue identifier] isEqualToString:@"addNote"])
	{
		NSLog(@"[%@ %@] addNote", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		NoteViewController *vc = [segue destinationViewController];
		vc.tag = self.tag;
		vc.notebook = self.notebook;
	}
	
	// 返回按钮
	UIBarButtonItem *newBackButton =
	[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(self.isBlog ? @"Post" : @"Note", nil)
									 style:UIBarButtonItemStyleBordered
									target:nil
									action:nil];
	[[self navigationItem] setBackBarButtonItem:newBackButton];
	
	// 隐藏tab bar
	// life
	((NoteViewController *)[segue destinationViewController]).hidesBottomBarWhenPushed = YES;
	
	// [self.tableView reloadData];
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

// 终于理解了
- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController)
	{
		return _fetchedResultsController;
	}
	
	self.fetchedResultsController = [Leas.note fetchedResultsControllerWithPredicate:nil
																		withController:self
																			  notebook:self.notebook tag:self.tag
									 isBlog:self.isBlog
									 ]; // [self fetchedResultsControllerWithPredicate:nil];
	return _fetchedResultsController;
}

- (NSFetchedResultsController *)searchedResultsController
{
	if( _searchedResultsController )
	{
		return _searchedResultsController;
	}
	
	self.searchedResultsController = [Leas.note fetchedResultsControllerWithPredicate:nil withController:self
																			   notebook:self.notebook
																					tag:self.tag
									  isBlog:self.isBlog]; // [self fetchedResultsControllerWithPredicate:nil];
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
        case NSFetchedResultsChangeUpdate:
        case NSFetchedResultsChangeMove:
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
			NSLog(@"note has changed NSFetchedResultsChangeUpdate");
			NSLog(@"indexPath: %ld", (long)indexPath.row);
			/*
			id <NSFetchedResultsSectionInfo> sectionInfo = [[controller sections] objectAtIndex:0];
			[sectionInfo numberOfObjects];
			*/

			// 这里有问题?
			Note *note = [controller objectAtIndexPath:indexPath];
			[self configureCell:[tableView cellForRowAtIndexPath:indexPath] forNote:note];
			
			break;
		}
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
	
	[self noteTitle];
	[tableView endUpdates];
}

#pragma mark - Add Note

- (IBAction)addNoteButtonPressed:(UIBarButtonItem *)sender
{
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	if(self.splitViewController)
	{
	}
	else
	{
		[self performSegueWithIdentifier:@"addNote" sender:self];
	}
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

// 搜索

#pragma mark - UISearchDisplayDelegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	NSString *searchPredicate = [NSString stringWithFormat:@"title contains[cd] '%@' or content contains[cd] '%@'", searchString, searchString];
	
	self.searchedResultsController = [Leas.note fetchedResultsControllerWithPredicate:searchPredicate
																		 withController:self
																			   notebook:self.notebook
																					tag:self.tag
									  isBlog:self.isBlog];
	
	// Return YES to cause the search result table view to be reloaded.
	return YES;
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
	[self setBarStyleBlack];
	self.isSelectOnSearch = YES;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	self.searchedResultsController.delegate = nil;
	self.searchedResultsController = nil;
	[controller.searchResultsTableView reloadData];
	
	// 为什么要reload ?
//	[self.tableView reloadData];
	
	[self restoreBarStyle];
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

// http://blog.csdn.net/swj6125/article/details/21741733
// 亲测UISearchBar Delegate的11个方法和UISearchDisplay Delegate的12个方法的调用顺序

@end
