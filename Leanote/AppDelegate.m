#import "AppDelegate.h"

#import "NoteController.h"
#import "Common.h"

#import <WordPress-iOS-Shared/UIImage+Util.h>
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import <WordPress-iOS-Shared/WPFontManager.h>
#import <WordPress-iOS-Shared/UIColor+Helpers.h>

#import "SVProgressHUD.h"
#import "WXApi.h"

#import "NoteService.h"
#import "NotebookService.h"
#import "BaseService.h"
#import "Leas.h"
#import "SyncService.h"
#import "UserService.h"
#import "User.h"

#import "LoginViewController.h"
#import "RootTabBarController.h"
#import "AFNetworkTool.h"

@implementation AppDelegate

/*
 NSManagedObjectContext：可以理解成一个数据库，里面存着很多表。
 
 NSManagedObjectModel：可以理解成对数据的描述，里面保存了实体类对象。
 
 NSPersistentStoreCoordinator：可以理解成连接数据库时的一些操作，协调者。
 */
@synthesize managedObjectContext = _managedObjectContext;
@synthesize writerManagedObjectContext = _writerManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initService];
	[AFNetworkTool netWorkStatus];
	
	// 创建图片目录
	[Common createDir:@"/images"];
	
	User *user = [UserService init];
	if(user && [user.userId length] > 0) {
		[self showTabbarVC];
	}
	else {
		[self showWidgetsLoginVC];
	}

	// 注册微信
	[WXApi registerApp:@"wx808fa9a431306386"]; // wxcefa411f34485347
	
	return YES;
	
	/*
	// ipad ?
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
        
        UINavigationController *masterNavigationController = splitViewController.viewControllers[0];
        MasterViewController *controller = (MasterViewController *)masterNavigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
    }
	// iphone
    else
    {
		// 设置controller.managedObjectContext, 因为tabView变了, 所以 TODO
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
		
		UITableViewController *controller = (UITableViewController*)self.window.rootViewController;
    }
	[[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:65/255.0 green:159/255.0 blue:252/255.0 alpha:0.5]];
	*/
}


#pragma mark 三个showVC方法
-(void)showWidgetsLoginVC {
	/*
	WidgetsVC * widgetVC=[[WidgetsVC alloc] init]; // ]initWithNibName:@"Widgets" bundle:[NSBundle mainBundle]];
	widgetVC.delegate = self;
	widgetVC.whichViewToPresent= @"loginView";
	self.window.rootViewController = widgetVC;
	*/
	
	LoginViewController *loginViewController = [[LoginViewController alloc] init];
	[loginViewController fromAddAccount:NO loginOkCb:^{
		[self showTabbarVC];
	}];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
	navigationController.navigationBar.translucent = NO;
	
	self.window.rootViewController = navigationController;
	
//	[self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
}

-(void)showTabbarVC {
	/* progress不显示
	User *user = [UserService getCurUser];
	BOOL isFirstSync = [user.lastSyncUsn integerValue] < 1;
	if(isFirstSync) {
		[Common showProgressWithStatus:NSLocalizedString(@"Synchronizing...", nil)];
	}
	// 同步
	[SyncService incrSync:^(BOOL ok) {
		if(isFirstSync) {
			[Common hideProgress];
		}
	} progress:nil];
	*/
	[UserService setOpenInited:NO];
	
	NSLog(@"%@ getDocPath:", [Common getDocPath]);
	
	UIStoryboard * mainsb = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:[NSBundle mainBundle]];
	RootTabBarController *tabVC = [mainsb instantiateInitialViewController];
	self.window.rootViewController = tabVC;
}

// init 服务
// 单例
// http://www.cnblogs.com/ios8/archive/2013/10/30/ios-Singleton.html
- (void) initService {
	// 设置两个context
	BaseService.context = self.managedObjectContext;
	BaseService.writerContext = self.writerManagedObjectContext;
	
	[Leas initService];
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[self customizeAppearance];
    return YES;
}

// 全局样式设置
- (void)customizeAppearance
{
	UIColor *defaultTintColor = self.window.tintColor;
	self.window.backgroundColor = [WPStyleGuide itsEverywhereGrey];
	self.window.tintColor = [WPStyleGuide wordPressBlue];
	
	[[UINavigationBar appearance] setBarTintColor:[WPStyleGuide wordPressBlue]];
	[[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
	
//	[[UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil] setBarTintColor:[UIColor whiteColor]];
//	[[UINavigationBar appearanceWhenContainedIn:[MFMailComposeViewController class], nil] setTintColor:defaultTintColor];
	
	[[UITabBar appearance] setShadowImage:[UIImage imageWithColor:[UIColor colorWithRed:210.0/255.0 green:222.0/255.0 blue:230.0/255.0 alpha:1.0]]];
	[[UITabBar appearance] setTintColor:[WPStyleGuide newKidOnTheBlockBlue]];
	
	[[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [WPFontManager openSansBoldFontOfSize:16.0]} ];
	
	[[UINavigationBar appearance] setBackgroundImage:[UIImage imageWithColor:[WPStyleGuide wordPressBlue]] forBarMetrics:UIBarMetricsDefault];
	[[UINavigationBar appearance] setShadowImage:[UIImage imageWithColor:[UIColor UIColorFromHex:0x007eb1]]];
	
	[[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
	[[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
	[[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont], NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.25]} forState:UIControlStateDisabled];
	
	[[UISegmentedControl appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPStyleGuide regularTextFont]} forState:UIControlStateNormal];
	[[UIToolbar appearance] setBarTintColor:[WPStyleGuide wordPressBlue]];
	[[UISwitch appearance] setOnTintColor:[WPStyleGuide wordPressBlue]];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	[[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [WPFontManager openSansRegularFontOfSize:10.0], NSForegroundColorAttributeName: [WPStyleGuide allTAllShadeGrey]} forState:UIControlStateNormal];
	[[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [WPStyleGuide wordPressBlue]} forState:UIControlStateSelected];
	
	[[UINavigationBar appearanceWhenContainedIn:[UIReferenceLibraryViewController class], nil] setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
	[[UINavigationBar appearanceWhenContainedIn:[UIReferenceLibraryViewController class], nil] setBarTintColor:[WPStyleGuide wordPressBlue]];
	[[UIToolbar appearanceWhenContainedIn:[UIReferenceLibraryViewController class], nil] setBarTintColor:[UIColor darkGrayColor]];
	
//	[[UIToolbar appearanceWhenContainedIn:[WPEditorViewController class], nil] setBarTintColor:[UIColor whiteColor]];
	
//	[[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] ssetDefaultTextAttributes:[WPStyleGuide defaultSearchBarTextAttributes:[WPStyleGuide littleEddieGrey]]];
	
	// SVProgressHUD styles
	[SVProgressHUD setBackgroundColor:[[WPStyleGuide littleEddieGrey] colorWithAlphaComponent:0.95]];
	[SVProgressHUD setForegroundColor:[UIColor whiteColor]];
	[SVProgressHUD setBackgroundColor2:[UIColor whiteColor]];
	[SVProgressHUD setForegroundColor2:[UIColor blackColor]];
	
	[SVProgressHUD setFont:[WPFontManager openSansRegularFontOfSize:18.0]];
	[SVProgressHUD setErrorImage:[UIImage imageNamed:@"hud_error"]];
	[SVProgressHUD setSuccessImage:[UIImage imageNamed:@"hud_success"]];
	
	
	// uisearchbar的cancel文字
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor clearColor];
    shadow.shadowOffset = CGSizeMake(0, -1);
    NSDictionary *titleAttributes = @{NSForegroundColorAttributeName: [WPStyleGuide wordPressBlue],
                                               NSShadowAttributeName: shadow,
                                      };
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:titleAttributes forState:UIControlStateNormal];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
		if ([managedObjectContext hasChanges]) {
			if(![managedObjectContext save:&error]) {
				// Replace this implementation with code to handle the error appropriately.
				// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
				abort();
			}
			else {
				// write之
				[self.writerManagedObjectContext save:&error];
			}
        }
    }
}

#pragma mark - Core Data stack

/*
// Single context
 
// start

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}
 
// end
*/


// 三层模式

// start

- (NSManagedObjectContext *)managedObjectContext{
	if (_managedObjectContext != nil) {
		return _managedObjectContext;
	}
	
	//concurrency type is set to NSMainQueueConcurrencyType
	_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	
	/**** parent context is set to the wrtierManagedObjectContext ***/
	_managedObjectContext.parentContext = [self writerManagedObjectContext];
	
	return _managedObjectContext;
}

- (NSManagedObjectContext *)writerManagedObjectContext{
	if (_writerManagedObjectContext != nil) {
		return _writerManagedObjectContext;
	}
	
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		
		/*** writer MOC is allocated with NSPrivateQueueConcurrency type and it's persistent store coordinator is set. ***/
		_writerManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
		[_writerManagedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	
	return self.writerManagedObjectContext;
}

// 三层end



// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Leanote" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Leanote.sqlite"];
	
	// NSLog(@"storeURL: %@", storeURL);
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }   
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
