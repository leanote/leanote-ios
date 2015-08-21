//
//  NotebookService.m
//  Leanote
//
//  Created by life on 15/4/30.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NotebookService.h"
#import "UserService.h"

#import "Notebook.h"
#import "Common.h"
#import "ApiService.h"

@implementation NotebookService

//@synthesize managedObjectContext = _managedObjectContext;

// coreData用法
// http://www.cnblogs.com/ZeroHour/p/3671346.html?utm_source=tuicool
// http://www.cnblogs.com/tx8899/p/4085294.html

static NotebookService * sharedSingleton = nil;
//static NSManagedObjectContext * context = nil;

static Notebook * curNotebook = nil;

+ (void) init: (NSManagedObjectContext *) managedObjectContext {
	sharedSingleton = [[NotebookService alloc] init];
//	context = managedObjectContext;
//	sharedSingleton.managedObjectContext = managedObjectContext;
}

+ (NotebookService *) getInstance {
	//	if (!sharedSingleton) {
	//		sharedSingleton = [[NoteService alloc] init];
	//	}
	return sharedSingleton;
}

// 全局, 当前笔记本
//+ (Notebook *) getCurNotebook {
//	return curNotebook;
//}
//+ (void) setCurNotebook:(Notebook *)notebook {
//	curNotebook = notebook;
//}
//+ (void) clearCurNotebook {
//	curNotebook = nil;
//}

// ============
// 同步需要
// ============


- (NSString *)getNotebookTitleByNotebookId:(NSString *)notebookId
{
	Notebook *notebook =[self getNotebookByNotebookId:notebookId];
	if(notebook) {
		return notebook.title;
	}
	return nil;
}

+ (NSString *) getFirstNotebookId:(NSManagedObjectContext *)inContext
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Notebook" inManagedObjectContext:inContext];
	[fetchRequest setEntity:entity];
	
	// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"updatedTime" ascending:NO];
	NSSortDescriptor *sortDescriptorSeq = [NSSortDescriptor sortDescriptorWithKey:@"seq" ascending:YES];
	
	NSArray *sortDescriptors = @[sortDescriptor, sortDescriptorSeq];
	[fetchRequest setSortDescriptors:sortDescriptors];
	[fetchRequest setFetchLimit:1];
	NSError * requestError = nil;
	NSArray * notebooks = [inContext executeFetchRequest:fetchRequest error:&requestError];
	if ([notebooks count] == 1) {
		Notebook *notebook = (Notebook *)notebooks[0];
		return notebook.notebookId;
	}
	return nil;
}

- (Notebook *)getNotebookByNotebookId: (NSString *)notebookId
{
	return [self.class getNotebookByNotebookId:notebookId inContext:self.tmpContext];
}

+ (Notebook *)getNotebookByNotebookId: (NSString *)notebookId
							inContext:(NSManagedObjectContext *)inContext

{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Notebook" inManagedObjectContext:inContext];
	[fetchRequest setEntity:entity];
	
	
	// 设置查询条件
	NSPredicate * agePre = [NSPredicate predicateWithFormat:@"notebookId = %@", notebookId];
	[fetchRequest setPredicate:agePre];
	
	NSError * requestError = nil;
	NSArray * notebooks = [inContext executeFetchRequest:fetchRequest error:&requestError];
	if ([notebooks count] == 1) {
		return notebooks[0];
	}
	return nil;
}

- (Notebook *)getNotebookByServerNotebookId:(NSString *)serverNotebookId {
	return [self.class getNotebookByServerNotebookId:serverNotebookId inContext:self.tmpContext];
}

// 通过ServerNotebookId得到笔记本
+ (Notebook *)getNotebookByServerNotebookId:(NSString *)serverNotebookId
								  inContext:(NSManagedObjectContext *)inContext
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Notebook" inManagedObjectContext:inContext];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"serverNotebookId = %@", serverNotebookId];
	[fetchRequest setPredicate:predicate];
	
	NSError * requestError = nil;
	NSArray * notebooks = [inContext executeFetchRequest:fetchRequest error:&requestError];
	NSLog(@"getNotebookByServerNotebookId ret: %@", notebooks);
	if ([notebooks count] == 1) {
		return notebooks[0];
	}
	NSLog(@"getNotebookByServerNotebookId ret nil");
	return nil;
}


// 删除
- (BOOL)deleteNotebookForceByServerNotebookId:(NSString *)serverNotebookId {
	Notebook *notebook = [self getNotebookByServerNotebookId:serverNotebookId];
	if (!notebook) {
		NSLog(@"删除 失败找不到 %@", serverNotebookId);
		return YES;
	}
	
	NSLog(@"删除 %@", notebook.title);
	[self.tmpContext deleteObject:notebook];
	
	if ([notebook isDeleted]) {
		return YES;
		/*
		 if([self saveContext]) {
			return YES;
		 }
		 */
		return NO;
	}
	
	return NO;
}

// 更新笔记本
- (Notebook *)updateNotebookForce:(id)obj {
	NSString *title = obj[@"Title"];
	NSNumber *seq = obj[@"Seq"];
	NSString *serverNotebookId = obj[@"NotebookId"];
	NSString *parentServerNotebookId = obj[@"ParentNotebookId"];
	NSNumber *usn = obj[@"Usn"];

	Notebook *notebook = [self getNotebookByServerNotebookId:serverNotebookId];
	
	if (!notebook) {
		return nil;
	}
	
	notebook.title = title;
	notebook.seq = seq;
	notebook.usn = usn;
	notebook.updatedTime = [Common goDate:obj[@"UpdatedTime"]];
	
	NSString *parentNotebookId = @"";
	if (![parentServerNotebookId isEqualToString:@""]) {
		Notebook *parentNotebook = [self getNotebookByServerNotebookId:parentServerNotebookId];
		if(parentNotebook != nil) {
			parentNotebookId = parentNotebook.notebookId;
		}
	}
	
	notebook.parentNotebookId = parentNotebookId;
	
	if([self saveContext]) {
		return notebook;
	}
	return nil;
}

- (Notebook *)addNotebookForce:(id)obj {
	// 创建实体
	Notebook *notebook = [NSEntityDescription insertNewObjectForEntityForName:@"Notebook" inManagedObjectContext:self.tmpContext];
	
	NSString *title = obj[@"Title"];
	NSNumber *seq = obj[@"Seq"];
	NSString *serverNotebookId = obj[@"NotebookId"];
	NSString *parentServerNotebookId = obj[@"ParentNotebookId"];
	NSNumber *usn = obj[@"Usn"];

	NSString *parentNotebookId = @"";
	if (![parentServerNotebookId isEqualToString:@""]) {
		Notebook *parentNotebook = [self getNotebookByServerNotebookId:parentServerNotebookId];
		if(parentNotebook != nil) {
			parentNotebookId = parentNotebook.notebookId;
		}
	}
	
	// 赋值
	if (notebook != nil) {
		notebook.notebookId = [[NSUUID UUID] UUIDString];
		notebook.serverNotebookId = serverNotebookId;
		notebook.parentNotebookId = parentNotebookId;
		notebook.title = title;
		notebook.userId = [UserService getCurUserId];
		
		notebook.createdTime = [Common goDate:obj[@"CreatedTime"]];
		notebook.updatedTime = [Common goDate:obj[@"UpdatedTime"]];
		
		notebook.seq = seq;
		notebook.usn = usn;
		
		notebook.isDirty = M_NO;
		notebook.localIsNew = M_NO;
		notebook.createdTime = [NSDate date];
		notebook.updatedTime =  notebook.createdTime;
		notebook.localIsDelete = M_NO;
	
		NSLog(@"add notebook force");
//		NSLog(@"%@", notebook);
		// 这里, 需要save push到main下么?
		// 还是批量要好
		// TODO
		/*
		if([self saveContext]) {
			return notebook;
		}*/
		return notebook;
		return nil;
	}
	else {
		NSLog(@"failed to create the new person");
		return nil;
	}
	
	return nil;
}

#pragma 本地笔记本操作

- (Notebook *)addNotebook: (NSString *) name
{
	// 创建实体
	Notebook *notebook = [NSEntityDescription insertNewObjectForEntityForName:@"Notebook" inManagedObjectContext:self.tmpContext];
	// 赋值
	if (notebook != nil) {
		notebook.notebookId = [[NSUUID UUID] UUIDString];
		
		notebook.title = name;
		notebook.createdTime = [NSDate date];
		notebook.updatedTime =  notebook.createdTime;
		notebook.seq = [NSNumber numberWithInt:-1];
		notebook.parentNotebookId = @"";
		notebook.userId = [UserService getCurUserId];
		notebook.localIsDelete = M_NO;
		notebook.isDirty = M_YES;
		
		if([self saveContextAndWrite]) {
			return notebook;
		}
		return nil;
	}
	return nil;
}

// 重新统计笔记下的数量
// 不save, 调用者save
+ (void)recountNotebookNoteCount:(Notebook *)notebook
					   inContext:(NSManagedObjectContext *)inContext
{
	// 更新笔记本
	if (!notebook) {
		return;
	}

	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:inContext];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSString *userId = [UserService getCurUserId];
	NSString *q = [NSString stringWithFormat:@"isTrash == NO AND localIsDelete == NO AND userId='%@' AND notebookId='%@'", userId, notebook.notebookId];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:q];
	[fetchRequest setPredicate:predicate];
	
	NSError *err;
	NSUInteger count = [inContext countForFetchRequest:fetchRequest error:&err];
	
	if(count == NSNotFound) {
		count = 0;
	}
//	NSLog(notebook.notebookId);
	NSLog(@"note count %lu", (unsigned long)count);
	
	notebook.noteCount = [NSNumber numberWithInteger:count];
	
	// 不要save, 调用者save
//	[self saveContextInOnly:inContext];
}

// noteService调用
+ (void)recountNotebookNoteCountByNotebookId:(NSString *)notebookId
								   inContext:(NSManagedObjectContext *)inContext
{
	if([notebookId isEqual: @""]) {
		return;
	}
	Notebook *notebook = [self getNotebookByNotebookId:notebookId inContext:inContext];
	if(notebook) {
		[self recountNotebookNoteCount:notebook inContext:inContext];
	}
}

- (void)deleteNotebook
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Notebook" inManagedObjectContext:self.tmpContext];
	[fetchRequest setEntity:entity];
	
	NSError * requestError = nil;
	NSArray * persons = [self.tmpContext executeFetchRequest:fetchRequest error:&requestError];
	
	if ([persons count] > 0) {
		
		Notebook * lastNotebook = [persons lastObject];
		
		// 删除数据
		[self.tmpContext deleteObject:lastNotebook];
		
		if ([lastNotebook isDeleted]) {
			NSLog(@"successfully deleted the last person");
			NSError * savingError = nil;
			
			// 通知_context保存数据
			if([self.tmpContext save:&savingError]) {
				NSLog(@"successfully saved the context");
				
			}
			else {
				NSLog(@"failed to save the context error = %@", savingError);
			}
		}
		else {
			NSLog(@"failed to delete the last person");
		}
	}
	else {
		NSLog(@"could not find any person entity in the context");
	}
}


- (void)updateNotebook
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Notebook" inManagedObjectContext:self.tmpContext];
	[fetchRequest setEntity:entity];
	
	NSError * requestError = nil;
	NSArray * notebooks = [self.tmpContext executeFetchRequest:fetchRequest error:&requestError];
	
	if ([notebooks count] > 0) {
		
		Notebook * lastNotebook = [notebooks lastObject];
		// 更新数据
		lastNotebook.title = @"Hour";
//		lastPerson.lastName = @"Zero";
//		lastPerson.age = @21;
		
		NSError * savingError = nil;
		if ([self.tmpContext save:&savingError]) {
			NSLog(@"successfully saved the context");
			
		} else {
			NSLog(@"failed to save the context error = %@", savingError);
		}
		
		
	} else {
		NSLog(@"could not find any person entity in the context");
	}
}

- (BOOL)deleteNotebok:(Notebook *)notebook
		  success:(void (^)())success
			 fail:(void (^)(id))fail
{
	notebook.localIsDelete = M_YES;
	notebook.isDirty = M_YES;

	// 用main context
	[self.class saveContext];
	return YES;
}

// 删除所有
+(void)deleteAllNoteboks:(NSString *)userId
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notebook" inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSString *q = [NSString stringWithFormat:@"userId='%@'", userId];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:q];
	[fetchRequest setPredicate:predicate];
	
	NSError *requestError = nil;
	NSArray *notebooks = [self.context executeFetchRequest:fetchRequest error:&requestError];
	
	for(Notebook *notebook in notebooks) {
		[self.context deleteObject:notebook];
	}
	
	[self saveContext];
}

- (NSArray *)getDirtyNotebooks
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notebook" inManagedObjectContext:self.tmpContext];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSString *userId = [UserService getCurUserId];
	NSString *q = [NSString stringWithFormat:@"isDirty == YES AND userId='%@'", userId];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:q];
	[fetchRequest setPredicate:predicate];
	
	NSError *requestError = nil;
	NSArray *notebooks = [self.tmpContext executeFetchRequest:fetchRequest error:&requestError];
	return notebooks;
}

#pragma 同步

- (void) pushAll:(void (^)())successCb
		 fail:(void (^)(id))failCb
{
	void (^success)(void) = ^(void) {
		[self saveContextAndWrite];
		successCb();
	};
	void (^fail)(id) = ^(id ret) {
		[self saveContextAndWrite];
		failCb(ret);
	};
	
	NSArray *notebooks = [self getDirtyNotebooks];
	if(!notebooks || [notebooks count] == 0) {
		success();
		return;
	}
	unsigned long total = [notebooks count];
	__block unsigned long  i = 0;
	for(Notebook *notebook in notebooks) {
		if(self.canceled) return;
		[self push:notebook success:^{
			i++;
			if(i == total) {
				success();
			}
			
		} fail:^(id ret) {
			i++;
			if(i == total) {
				success();
			}
		} noOp:^{
			i++;
			if(i == total) {
				success();
			}
		}];
	}
	
}

- (void) pushAndWrite:(Notebook *)notebook
	  success:(void (^)())successCb
		 fail:(void (^)(id))failCb
{
	void (^success)(void) = ^(void) {
		[self saveContextAndWrite];
		successCb();
	};
	void (^fail)(id) = ^(id ret) {
		[self saveContextAndWrite];
		failCb(ret);
	};
	
	[self push:notebook success:success fail:fail noOp:nil];
}

- (void) push:(Notebook *)notebook
	  success:(void (^)())success
		 fail:(void (^)(id))fail
{
	[self push:notebook success:success fail:fail noOp:nil];
}

// 通过notebookId push
- (void) pushByNotebookId:(NSString *)notebookId
	  success:(void (^)())success
		 fail:(void (^)(id))fail
{
	Notebook *notebook = [self getNotebookByNotebookId:notebookId];
	if(!notebook) {
		if(fail) fail(nil);
	}
	else {
		[self push:notebook success:success fail:fail];
	}
}

- (void) push:(Notebook *)notebook
	  success:(void (^)())success
		 fail:(void (^)(id))fail
		 noOp:(void (^)())noOp
{
	// 非dirty, 不要push
	if(![notebook.isDirty boolValue]) {
		if(noOp) noOp();
		return;
	}
	
	if([notebook.localIsDelete boolValue]) {
		if(![Common isBlankString:notebook.serverNotebookId]) {
			[self pushDeleteNotebook:notebook success:success fail:fail];
		} else {
			if(noOp) noOp();
		}
		return;
	}
	
	if([Common isBlankString:notebook.serverNotebookId] || [notebook.localIsNew boolValue]) {
		[self pushAddNotebook:notebook success:success fail:fail];
	}
	else {
		[self pushUpdateNotebook:notebook success:success fail:fail];
	}
}

- (void) pushAddNotebook:(Notebook *)notebook
				success:(void (^)())success
				fail:(void (^)(id))fail
{
	notebook.status = [NSNumber numberWithInt:-1];
	
	[ApiService addNotebook:notebook success:^(id ret) {
		notebook.status = [NSNumber numberWithInt:1];
		
		NSNumber *usn = ret[@"Usn"];
		notebook.serverNotebookId = ret[@"NotebookId"];
		notebook.usn = usn;
		notebook.isDirty = M_NO;
		
		[self saveContext];
		NSLog(@"pushAddNotebook %@", ret);
		
		if(success) {
			success();
		}
	} fail:^(id ret){
		notebook.status = [NSNumber numberWithInt:-2];
		
		if(fail) {
			// 是否冲突
			fail(ret);
		}
	}];
}

- (void) pushUpdateNotebook:(Notebook *)notebook
				 success:(void (^)())success
					fail:(void (^)(id))fail
{
	notebook.status = [NSNumber numberWithInt:-1];
	
	[ApiService updateNotebook:notebook success:^(id ret) {
		notebook.status = [NSNumber numberWithInt:1];
		
		NSNumber *usn = ret[@"Usn"];
		notebook.usn = usn;
		notebook.isDirty = M_NO;
		
		[self saveContext];
		NSLog(@"pushUpdateNotebook %@", ret);
		
		if(success) {
			success();
		}
	} fail:^(id ret){
		notebook.status = [NSNumber numberWithInt:-2];
		
		if(fail) {
			// 是否冲突
			fail(ret);
		}
	}];
}

- (void) pushDeleteNotebook:(Notebook *)notebook
				success:(void (^)())success
				   fail:(void (^)(id))fail
{
	[ApiService deleteNotebook:notebook success:^(id ret) {
		if(success) {
			[self.tmpContext deleteObject:notebook];
			[self saveContext];
			success();
		}
	} fail:^(id ret){
		if(fail) {
			// 是否冲突
			fail(ret);
		}
	}];
}

@end
