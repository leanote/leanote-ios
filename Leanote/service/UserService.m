//
//  UserService.m
//
//  Created by life on 15/6/6.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "UserService.h"
#import "ApiService.h"
#import "Common.h"

#import "NotebookService.h"
#import "NoteService.h"
#import "FileService.h"
#import "TagService.h"

static NSString* const UserT = @"User"; // 表名
static NSString* const DefaultHost = @"https://leanote.com"; // @"http://localhost:9000"; // 默认host

static User *curUser;

// 打开的状态, NO表示没有初始化, YES表示初始化了
static BOOL openInited;

@implementation UserService

+ (BOOL) getOpenInited
{
	return openInited;
}
+ (void) setOpenInited:(BOOL) inited
{
	openInited = inited;
}

// 初始化, 判断是否有用户
+ (User *) init {
	User *user = [self getActiveUser];
	if(user) {
		curUser = user;
		return user;
	}

	return nil;
}

// 获取当前用户
+ (User *) getCurUser {
	return curUser;
}

+ (NSString *) getCurUserId {
	return curUser.userId;
}

+ (NSString *) getHost {
	if([Common isBlankString:curUser.host]) {
		return DefaultHost;
	}
	
	// 如果是http://leanote.com, 则改成https
	NSString *host = curUser.host;
	if ([host isEqualToString:@"http://leanote.com"]) {
		return DefaultHost;
	}
	return curUser.host;
//	return @"http://localhost:9000";
}

+ (NSString *) getDefaultHost {
	return DefaultHost;
}

+ (NSString *) getToken {
	if(curUser) {
		return curUser.token;
	}
	return @"5572864a99c37b5865000006";
}

+ (NSString *) getMyBlogUrl {
	if(curUser) {
		return [NSString stringWithFormat:@"%@/blog/%@?from=ios", [self getHost], curUser.userId];
	}
	return @"http://leanote.leanote.com";
}

+ (NSString *) getPostUrl:(NSString *)noteId {
	if(curUser) {
		return [NSString stringWithFormat:@"%@/blog/post/%@?from=ios", [self getHost], noteId];
	}
	return [NSString stringWithFormat:@"http://blog.leanote.com/post/%@", noteId];
}

+ (NSNumber *) getLastSyncNotebookUsn {
	if(curUser.lastSyncNotebookUsn && [curUser.lastSyncNotebookUsn intValue] > 0) {
		return curUser.lastSyncNotebookUsn;
	}
	return [NSNumber numberWithInt:-1];
}
+ (NSNumber *) getLastSyncNoteUsn {
	if(curUser.lastSyncNoteUsn && [curUser.lastSyncNoteUsn intValue] > 0) {
		return curUser.lastSyncNoteUsn;
	}
	return [NSNumber numberWithInt:-1];
}
+ (NSNumber *) getLastSyncTagUsn {
	if(curUser.lastSyncTagUsn && [curUser.lastSyncTagUsn intValue] > 0) {
		return curUser.lastSyncTagUsn;
	}
	return [NSNumber numberWithInt:-1];
}
+ (NSNumber *) getLastSyncUsn {
	if(curUser.lastSyncUsn && [curUser.lastSyncUsn intValue] > 0) {
		return curUser.lastSyncUsn;
	}
	return [NSNumber numberWithInt:-1];
}

+ (void) saveLastSyncNotebookUsn:(NSNumber *) usn {
	curUser.lastSyncNotebookUsn = usn;
}
+ (void) saveLastSyncNoteUsn:(NSNumber *) usn {
	curUser.lastSyncNoteUsn = usn;
}
+ (void) saveLastSyncTagUsn:(NSNumber *) usn {
	curUser.lastSyncTagUsn = usn;
}

// 同步后, 保存上次同步状态
+ (void) saveLastSyncUsn {
	[ApiService getSyncState:^(id ret) {
		NSNumber *lastSyncUsn = ret[@"LastSyncUsn"];
		if([lastSyncUsn integerValue] > 0) {
			curUser.lastSyncUsn = lastSyncUsn;
			curUser.lastSyncNotebookUsn = lastSyncUsn;
			curUser.lastSyncNoteUsn = lastSyncUsn;
			curUser.lastSyncTagUsn = lastSyncUsn;
			[self saveContext];
		}
	} fail:^(id ret2) {
		
	}];
}

+ (User *) getUserByUserId:(NSString *)userId {
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:UserT inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"userId = %@", userId];
	[fetchRequest setPredicate:predicate];
	
	NSError * requestError = nil;
	NSArray * users = [self.context executeFetchRequest:fetchRequest error:&requestError];
	//	NSLog(@"getNoteByServerNoteId ret: %@", Notes);
	if ([users count] == 1) {
		return users[0];
	}
	NSLog(@"getUserByUserId ret nil");
	return nil;
}


// 获取
+ (User *) getActiveUser {
	// deactive其它用户
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:UserT inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"isActive = %@", M_YES];
	[fetchRequest setPredicate:predicate];
	NSError * requestError = nil;
	NSArray * users = [self.context executeFetchRequest:fetchRequest error:&requestError];
	
	if (users && [users count] > 0) {
		return users[0];
	}
	return nil;
}

// 激活用户, 需要先deactive其它用户
+ (void) activeUser:(User *)user token:(NSString *)token {
	// deactive其它用户
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:UserT inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"userId != %@", user.userId];
	[fetchRequest setPredicate:predicate];
	NSError * requestError = nil;
	NSArray * users = [self.context executeFetchRequest:fetchRequest error:&requestError];
	
	if (users && [users count] > 0) {
		for (User *each in users) {
			each.isActive = M_NO;
		}
	}
	
	// 激活该用户
	user.isActive = M_YES;
	user.updatedTime = [NSDate date];
	if(token && [token length] > 0) {
		user.token = token;
	}
	
	curUser = user;
	
	[self saveContext];
}

+ (void) activeUser:(User *)user
{
	[self activeUser:user token:user.token];
}

// 添加用户, 并激活该用户
// 先判断用户是否存在
+ (User *) addUser:(id)obj pwd:(NSString*)pwd host:(NSString *)host {
	
	NSString *userId = obj[@"UserId"];
	NSString *username = obj[@"Username"];
	NSString *email = obj[@"Email"];
	NSString *token = obj[@"Token"];

	// 用户如果存在, 直接返回之
	User *user = [self getUserByUserId:userId];
	if (user) {
		NSLog(@"用户存在");
		[self activeUser:user token:token];
		return user;
	}
	
	user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.context];

	user.username = username;
	user.email = email;
	user.pwd = pwd;
	user.token = token;
	user.userId = userId;
	user.isActive = M_YES;
	
	// 添加的时间
	user.createdTime = [NSDate date];
	// 切换到active的时间
	user.updatedTime = user.createdTime;
	
	if ([Common isBlankString:host]) {
		user.host = DefaultHost;
	}
	else {
		user.host = host;
	}
	
	if([self saveContext]) {
		[self activeUser:user token:token];
		return user;
	}
	
	return nil;
}

// 登录, 成功后写入数据库
+ (void) login:(NSString *) username
				 pwd: (NSString *) pwd
		  host: (NSString *) host
	   success:(void (^)(User *))success
		  fail:(void (^)())fail {
	
	if([Common isBlankString:host]) {
		host = [UserService getDefaultHost];
	}
	
	[ApiService login:username pwd:pwd host:host success:^(id obj) {
		/*
		 Email = "lifexx@a.com";
		 Ok = 1;
		 Token = 557a6e7199c37b15e2000001;
		 UserId = 5368c1aa99c37b029d000001;
		 Username = admin;
		*/
		if([obj[@"Ok"] boolValue]) {
			User *user = [self addUser:obj pwd: pwd host:host];
			success(user);
		}
		else {
			if(fail) {
				fail();
			}
		}
	} fail:^{
		if(fail) {
			fail();
		}
	}];
}


+ (void) register:(NSString *) email
				 pwd: (NSString *) pwd
	   success:(void (^)(User *))success
		  fail:(void (^)(id))fail {
	[ApiService register:email pwd:pwd success:^(id obj) {
		/*
		 Email = "lifexx@a.com";
		 Ok = 1;
		 Token = 557a6e7199c37b15e2000001;
		 UserId = 5368c1aa99c37b029d000001;
		 Username = admin;
		 */
		if([obj[@"Ok"] boolValue]) {
			// 成功后, 登录用户
			[self login:email pwd:pwd host:nil success:^(User *user) {
				success(user);
			} fail:^{
				if(fail) {
					fail(nil);
				}
			}];
		}
		else {
			if(fail) {
				fail(obj);
			}
		}
	} fail:^(id ret){
		if(fail) {
			fail(ret);
		}
	}];
}

# pragma 用户列表

// 获取
+ (NSArray *) getUsers {
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:UserT inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// 设置sorter, 最近active的在前面
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"isActive" ascending:NO];
	NSSortDescriptor *sortDescriptorSeq = [NSSortDescriptor sortDescriptorWithKey:@"updatedTime" ascending:NO];
	
	NSArray *sortDescriptors = @[sortDescriptor, sortDescriptorSeq];
	
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	NSError * requestError = nil;
	NSArray * users = [self.context executeFetchRequest:fetchRequest error:&requestError];
	
	return users;
}

+ (void) deleteAllData:(User *)user
{
	NSString *userId = user.userId;
	[NotebookService deleteAllNoteboks:userId];
	[NoteService deleteAllNotes:userId];
	[TagService deleteAllTags:userId];
	[FileService deleteAllFiles:userId];
	
	[self.context deleteObject:user];
	[self saveContext];
}

# pragma 本地配置


+ (BOOL) isNormalEditor
{
	NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
	NSString *editor = [accountDefaults objectForKey:@"editor"];
	if([Common isBlankString:editor]) {
		return YES;
	}
	return NO;
}

+ (void) setDefaultEditor:(BOOL)isNormalEditor
{
	NSUserDefaults *accountDefaults = [NSUserDefaults standardUserDefaults];
	NSString *isNormalEditorStr = isNormalEditor ? @"" : @"1";
	[accountDefaults setObject:isNormalEditorStr forKey:@"editor"];
}

@end
