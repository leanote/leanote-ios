//
//  NotebookService.m
//  Leanote
//
//  Created by life on 15/4/30.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NoteService.h"

#import "Notebook.h"
#import "NotebookService.h"
#import "ApiService.h"
#import "UserService.h"
#import "FileService.h"
#import "TagService.h"

#import "Note.h"

@implementation NoteService

// 把关于数据库操作的抽出来放到这里

- (NSFetchedResultsController *) fetchedResultsControllerWithPredicate:(NSString *)predicateStr
														withController:(UIViewController *)controller
															  notebook:(Notebook *)notebook
																   tag:(Tag *)tag
																isBlog:(BOOL)isBlog
{
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note"
											  inManagedObjectContext:self.class.context]; // 必须要是main context
	[fetchRequest setEntity:entity];
	// cache
	NSString *cacheName = nil; // @"Note";
	
	// 条件设置
	// 必须要用 == NO啊!!
	// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/Predicates/Articles/pCreating.html#//apple_ref/doc/uid/TP40001793-SW2
	// http://stackoverflow.com/questions/12370521/changing-a-managed-object-property-doesnt-trigger-nsfetchedresultscontroller-to/12379824#12379824
	NSString *userId = [UserService getCurUserId];
	NSLog(@"cur userId: %@", userId);
	
	NSString *defaultQ = [NSString stringWithFormat:@"isTrash == NO && localIsDelete == NO AND userId='%@'", userId];
	if(!predicateStr) {
		predicateStr = defaultQ;
	}
	else {
		predicateStr = [NSString stringWithFormat:@"%@ and %@", predicateStr,
						defaultQ
						];
	}
	
	if(isBlog) {
		predicateStr = [NSString stringWithFormat:@"%@ and isBlog == YES", predicateStr];
	}
	
	// 笔记本条件
	if (notebook && ![notebook.title isEqual: @""]) {
		NSString *notebookQ = [NSString stringWithFormat:@"notebookId = '%@'",notebook.notebookId];
		if(!predicateStr) {
			predicateStr = notebookQ;
		}
		else {
			predicateStr = [NSString stringWithFormat:@"%@ and %@", predicateStr, notebookQ];
		}
		cacheName = nil;
	}
	
	if (tag && ![tag.title isEqual: @""]) {
		NSString *tagQ = [NSString stringWithFormat:@"tags contains[cd] '%@'", tag.title];
		if(!predicateStr) {
			predicateStr = tagQ;
		}
		else {
			predicateStr = [NSString stringWithFormat:@"%@ and %@", predicateStr, tagQ];
		}
		cacheName = nil;
	}
	
	NSPredicate *predicate;
	if (![predicateStr isEqual: @""]) {
		predicate = [NSPredicate predicateWithFormat:predicateStr];
		[fetchRequest setPredicate:predicate];
	}
	
	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];
	
	// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"updatedTime" ascending:NO];
	NSArray *sortDescriptors = @[sortDescriptor];
	
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	
	// Edit the section name key path and cache name if appropriate.
	// nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
															 
																managedObjectContext:self.class.context
																								  sectionNameKeyPath:nil
																										   cacheName:cacheName];
	// 很有用, 当删除时, 将controller的表格当行也删除掉
	aFetchedResultsController.delegate = controller;
	
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

//static NoteService * sharedSingleton = nil;
//static NSManagedObjectContext * context = nil;

+ (void) init: (NSManagedObjectContext *) managedObjectContext {
//	sharedSingleton = [[NoteService alloc] init];
//	context = managedObjectContext;
//	sharedSingleton.managedObjectContext = managedObjectContext;
}

+ (NoteService *) getInstance {
//	return sharedSingleton;
}

#pragma 同步

// 删除
- (BOOL)deleteNoteForceByServerNoteId:(NSString *)serverNoteId {
	Note *note = [self getNoteByServerNoteId:serverNoteId];
	if (!note) {
		NSLog(@"删除 失败找不到 %@", serverNoteId);
		return YES;
	}
	
	NSLog(@"删除 %@", note.title);
	[self.tmpContext deleteObject:note];
	
	if ([note isDeleted]) {
		// 不要save, 调用者save
//		if([self saveContext]) {
			[NotebookService recountNotebookNoteCountByNotebookId:note.notebookId inContext:self.tmpContext];
			[TagService recountTagNoteCountByTitlesStr:note.tags inContext:self.tmpContext];

			return YES;
//		}
		return NO;
	}
	
	return NO;
}

- (NSArray *)getDirtyNotes
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:self.tmpContext];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSString *userId = [UserService getCurUserId];
	NSString *q = [NSString stringWithFormat:@"isDirty == YES AND userId='%@'", userId];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:q];
	[fetchRequest setPredicate:predicate];
	
	NSError *requestError = nil;
	NSArray *notes = [self.tmpContext executeFetchRequest:fetchRequest error:&requestError];
	return notes;
}

- (Note *)getNoteByNoteId: (NSString *)noteId
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:self.tmpContext];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSPredicate * agePre = [NSPredicate predicateWithFormat:@"noteId = %@", noteId];
	[fetchRequest setPredicate:agePre];
	
	NSError * requestError = nil;
	NSArray * notes = [self.tmpContext executeFetchRequest:fetchRequest error:&requestError];
	if ([notes count] >= 1) {
		return notes[0];
	}
	return nil;
}

// 通过ServerNoteId得到笔记
- (Note *)getNoteByServerNoteId:(NSString *)serverNoteId {
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:self.tmpContext];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"serverNoteId = %@", serverNoteId];
	[fetchRequest setPredicate:predicate];
	
	NSError * requestError = nil;
	NSArray * notes = [self.tmpContext executeFetchRequest:fetchRequest error:&requestError];
	//	NSLog(@"getNoteByServerNoteId ret: %@", Notes);
	if ([notes count] >= 1) {
		return notes[0];
	}
	NSLog(@"getNoteByServerNoteId ret nil %@ notes=%@", serverNoteId, notes);
	return nil;
}

// 更新笔记本
// 调用者save
- (Note *)updateNoteForce:(id)obj {
	NSString *serverNoteId = obj[@"NoteId"];
	Note *note = [self getNoteByServerNoteId:serverNoteId];
	
	if (!note) {
		return nil;
	}
	
	NSString *title = obj[@"Title"];
	NSString *serverNotebookId = obj[@"NotebookId"];
	NSNumber *usn = obj[@"Usn"];
	NSNumber *isBlog = obj[@"IsBlog"];
	NSArray *tags = obj[@"Tags"];
	NSNumber *isTrash = obj[@"IsTrash"];
	
	// notebook
	Notebook *notebook = [NotebookService getNotebookByServerNotebookId:serverNotebookId inContext:self.tmpContext];
	NSString *everNotebookId = nil;
	if(notebook) {
		if(notebook.notebookId && ![notebook.notebookId isEqualToString:notebook.notebookId]) {
			everNotebookId = notebook.notebookId;
			note.notebookId = notebook.notebookId;
		}
	}
	
	note.title = title;
	note.isBlog = isBlog;
	note.usn = usn;
	note.isTrash = isTrash;
	
	note.isInitSync = M_YES; // 需要重新同步笔记
	note.isDirty = M_NO;
	note.localIsNew = M_NO;
	note.updatedTime = [Common goDate:obj[@"UpdatedTime"]];
	
	NSString *tagsStr;
	if(![Common isNull:tags]) {
		tagsStr = [tags componentsJoinedByString:@","];
	}
	else {
		tagsStr = @"";
	}
	NSString *everTags = note.tags;
	note.tags = tagsStr;
	
//	if([self saveContext]) {
		// desktop 客户端可能有这个问题!!
		if(everNotebookId) {
			[NotebookService recountNotebookNoteCountByNotebookId:everNotebookId inContext:self.tmpContext];
		}
		if(notebook) {
			[NotebookService recountNotebookNoteCount:notebook inContext:self.tmpContext];
		}
		
		// recountTag, 之前的tag, 现在的tag, 得到不一样的tag, 只分析不同的tag count
		[TagService recountTagNoteCountByTitles:tags inContext:self.tmpContext];
		if(![Common isNull:everTags]) {
			[TagService recountTagNoteCountByTitles:[everTags componentsSeparatedByString:@","] inContext:self.tmpContext];
		}
		return note;
//	}
	return nil;
}

// add
// 调用者save
- (Note *)addNoteForce:(id)obj {
	
	NSString *title = obj[@"Title"];
	NSString *serverNotebookId = obj[@"NotebookId"];
	NSString *serverNoteId = obj[@"NoteId"];
	NSNumber *isMarkdown = obj[@"IsMarkdown"];
	NSNumber *usn = obj[@"Usn"];
	NSArray *tags = obj[@"Tags"];
	NSNumber *isBlog = obj[@"IsBlog"];
	NSNumber *isTrash = obj[@"IsTrash"];
	
	NSString *createdTime = obj[@"CreatedTime"];
	NSString *updatedTime = obj[@"UpdatedTime"];
	
	Note *note = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:self.tmpContext];
	
	note.title = title;
	note.content = @"";
	note.serverNoteId = serverNoteId;
	
	note.isMarkdown = isMarkdown;
	note.isBlog = isBlog;
	note.usn = usn;
	note.isTrash = isTrash;
	note.createdTime = [Common goDate:createdTime];
	note.updatedTime = [Common goDate:updatedTime];
	
	note.isDirty = M_NO;
	note.localIsNew = M_NO;
	note.isInitSync = M_YES; // 笔记内容需要重新获取
	
	note.userId = [UserService getCurUserId];
	
	NSString *tagsStr;
	if(![Common isNull:tags]) {
		tagsStr = [tags componentsJoinedByString:@","];
	}
	else {
		tagsStr = @"";
	}
	note.tags = tagsStr;
	
	// notebook
	Notebook *notebook = [NotebookService getNotebookByServerNotebookId:serverNotebookId inContext:self.tmpContext];
	if(notebook) {
		note.notebookId = notebook.notebookId;
	}
	
//	if([self saveContext]) {
		if(notebook) {
			[NotebookService recountNotebookNoteCount:notebook inContext:self.tmpContext];
		}
		
		// 如果是第一次同步的话, 是没有tag的
		[TagService recountTagNoteCountByTitlesStr:note.tags inContext:self.tmpContext];
		
		return note;
//	}
	return nil;
}

// 本地localNote与obj有冲突, 此时需要复制一个笔记
// 1. 新obj作为旧笔记
// 2. 将localNote的serverNoteId置空, 变为新的笔记
- (void)copyNoteForConflict:(id)obj localNote:(Note *)localNote {
	// 1. 新笔记
	Note *newNote = [self addNoteForce:obj];
	
	// 2. 将localNote的serverNoteId置空, 变为新的笔记
	localNote.localIsNew = M_YES;
	localNote.isDirty = M_YES;
	localNote.serverNoteId = @""; // 无serverNoteId
	localNote.title = [[localNote.title stringByAppendingString:@"-"] stringByAppendingString: NSLocalizedString(@"Conflict", nil)];
	localNote.conflictedNoteId = newNote.noteId;
	
	// 不save, 调用者save
//	[self saveContext];
	[NotebookService recountNotebookNoteCountByNotebookId:localNote.notebookId inContext:self.tmpContext];
}

#pragma 本地笔记操作

// 添加笔记
// 添加笔记点击配置之前会添加笔记
- (Note *)addNote:(NSString *)title
		  content:(NSString *)content
		 notebook:(Notebook *)notebook
			  tag:(Tag *) tag
{
	// 创建实体
	Note *note = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:self.tmpContext];
	
	note.title = [Common trimNewLine:title];
	note.content = content;
	note.createdTime = [NSDate date];
	note.updatedTime = note.createdTime;
	note.userId = [UserService getCurUserId];
	
	if (notebook != nil) {
		note.notebookId = notebook.notebookId;
	}
	// 如果没有笔记本, 则默认为第一个笔记本
	else {
		note.notebookId = [NotebookService getFirstNotebookId:self.tmpContext];
	}
	
	// tag
	if(tag) {
		note.tags = tag.title;
	}
	
	note.isTrash = M_NO;
	note.isDirty = M_YES;
	note.isInitSync = M_NO;
	note.localIsDelete = M_NO;
	note.isMarkdown = [UserService isNormalEditor] ? M_NO : M_YES;
	
//	if([self saveContext]) {
		if(notebook) {
			[NotebookService recountNotebookNoteCount:notebook inContext:self.tmpContext];
		}
		if(tag) {
			[TagService recountTagNoteCountByTitlesStr:tag.title inContext:self.tmpContext];
		}
	
		// 一起save
		[self saveContextAndWrite];
		return note;
//	}
	return nil;
}

// 修改笔记的笔记本
- (void) updateNoteNotebook:(Note *)note notebook:(Notebook*)notebook
{
	[self.tmpContext performBlock:^{
		if([note.notebookId isEqualToString:notebook.notebookId]) {
			return;
		}
		NSString *everNotebookId = note.notebookId;
		note.notebookId = notebook.notebookId;
		note.isDirty = M_YES;
//		[self saveContext];
		
		// 重新统计
		[NotebookService recountNotebookNoteCountByNotebookId:everNotebookId inContext:self.tmpContext];
		[NotebookService recountNotebookNoteCountByNotebookId:notebook.notebookId inContext:self.tmpContext];
		// 一起save
		[self saveContextAndWrite];
	}];
}

// 更新笔记的其它属性
- (void)updateNote:(Note *)note
	   forNotebook:(BOOL)forNotebook
		   forBlog:(BOOL)forBlog
		   forTags:(BOOL)forTags
			  tags:(NSString *)tags {
	
	[self.tmpContext performBlock:^{
		
		if(note.updated) {
			note.updatedTime = [NSDate date];
		}
		note.isDirty = M_YES;
		
		if(forNotebook) {
			// 没用了
//			[self saveContext];
			[NotebookService recountNotebookNoteCountByNotebookId:note.notebookId inContext:self.tmpContext];
			[self saveContextAndWrite];
		}
		else if(forTags) {
			NSString *everTags = note.tags;
			
			// tags是用,来分隔的, 可能是中文. 将中文,替换成英文, 将空格去掉
			NSArray *tagsArr;
			if(![Common isBlankString:tags]) {
				NSString *tags2 = [tags stringByReplacingOccurrencesOfString:@"，" withString:@","];
				tags2 = [tags2 stringByReplacingOccurrencesOfString:@" " withString:@""];
				// 两个,,替换成一个,
				tags2 = [tags2 stringByReplacingOccurrencesOfString:@",," withString:@","];
				tags2 = [tags2 stringByReplacingOccurrencesOfString:@",," withString:@","];
				
				tagsArr = [tags2 componentsSeparatedByString:@","];
				note.tags = tags2;
			}
			else {
				note.tags = @"";
			}
			
//			[self saveContext];
			
			// add tags
			[TagService addTags:tagsArr inContext:self.tmpContext];
			
			// 得到需要重新recount的tags
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
			for(NSString *tag in tagsArr) {
				dict[tag] = @"OK";
			}
			NSArray *everTagsArr = [everTags componentsSeparatedByString:@","];
			NSMutableArray *needRecountTags = [[NSMutableArray alloc] init];
			for(NSString *tag in everTagsArr) {
				if(!dict[tag] && ![Common isBlankString:tag]) {
					[needRecountTags addObject:tag];
				}
			}
			
			//		[Common async:^{
			// recount everTags
			[TagService recountTagNoteCountByTitles:needRecountTags inContext:self.tmpContext];
			//		}];
			
//			[self saveContextAndWrite];
		}
		else if(forBlog) {
//			[self saveContextAndWrite];
		}
		
		[self saveContextAndWrite];
	}];
}

// 更新笔记
// 这里非常慢
- (BOOL)updateNote:(Note *)note title:(NSString *)title content:(NSString *)content
{
//	[self.tmpContext performBlock:^{
		if (note.title == title && note.content == content) {
			return YES;
		}
		
		note.isDirty = M_YES;
		note.localIsDelete = M_NO;
		note.title = title;
		if(![note.content isEqualToString:content]) {
			note.isContentDirty = M_YES;
		}
		note.content = content;
		note.updatedTime = [NSDate date];
		
		// 这里, write了
		[self saveContextAndWrite];
//	}];
	
	return YES;
}

// TODO, 全改成tmp的 **
// note是main的note
-(BOOL)deleteNote:(Note *)note success:(void (^)())success fail:(void (^)(id))fail {
	NSError *err;
	Note *localeNote = (Note *)[self.tmpContext existingObjectWithID:note.objectID error:&err];
	if(err) {
		return NO;
	}
	localeNote.localIsDelete = M_YES;
	localeNote.isDirty = M_YES;
	
	// push到main
//	if([self saveContextAndPush]) {
		// recount是tmpContext的recount
		[NotebookService recountNotebookNoteCountByNotebookId:localeNote.notebookId inContext:self.tmpContext];
		[TagService recountTagNoteCountByTitlesStr:localeNote.tags inContext:self.tmpContext];
		 // 发送改变之
		 [self push:localeNote success:^{
			 [self saveContextAndWrite];
			 if(success) {
				 success();
			 }
			 
		 } fail:^(id ret) {
			 [self saveContextAndWrite];
			 if(fail) {
				 fail(ret);
			 }
		 }];
//	}
	return YES;
}

+(void)deleteAllNotes:(NSString *)userId
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSString *q = [NSString stringWithFormat:@"userId='%@'", userId];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:q];
	[fetchRequest setPredicate:predicate];
	
	NSError *requestError = nil;
	NSArray *notes = [self.context executeFetchRequest:fetchRequest error:&requestError];
	
	for(Note *note in notes) {
		[self.context deleteObject:note];
	}
	
	[self saveContext];
}

// 删除笔记的标签
+ (void) deleteTag:(NSString *)tagTitle
		 inContext:(NSManagedObjectContext *)inContext
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:inContext];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSPredicate * pred = [NSPredicate predicateWithFormat:@"tags contains[cd] %@", tagTitle];
	[fetchRequest setPredicate:pred];
	
	NSError * requestError = nil;
	NSArray * notes = [inContext executeFetchRequest:fetchRequest error:&requestError];
	if ([notes count] == 0) {
		return;
	}
	
	for (Note *note in notes) {
		NSString *tags = note.tags;
		// tags是用,来分隔的, 可能是中文. 将中文,替换成英文, 将空格去掉
		NSArray *tagsArr = [tags componentsSeparatedByString:@","];
		// 新的arr数组
		NSMutableArray *newArray = [[NSMutableArray alloc] init];
		for(NSString *eachTag in tagsArr) {
			if(![eachTag isEqualToString:tagTitle]) {
				[newArray addObject:eachTag];
			}
		}
		NSString *newTags;
		if([newArray count] > 0) {
			newTags = [newArray componentsJoinedByString:@","];
		}
		else {
			newTags = @"";
		}
		note.isDirty = M_YES;
		note.tags = newTags;
	}
	
	[self saveContext];
}

// 将image url替换成leanote://getImage?fileId=32232
- (NSString *) fixContent:(NSString *)content isMarkdown:(BOOL)isMarkdown
{
	if([Common isBlankString:content]) {
		return content;
	}
	// 非markdown
	if(!isMarkdown) {
		NSString *pattern = [NSString stringWithFormat:@"src=('|\")%@/(api/)*file/(outputImage|getImage)\\?fileId=([a-z0-9A-Z]{24})('|\")", [UserService getHost]];
		NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
		
		content = [regularExpression stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:@"src=\"leanote://getImage?fileId=$4\""];
	}
	// markdown
	else {
		NSString *pattern = [NSString stringWithFormat: @"!\\[(.*?)\\]\\(%@/(api/)*file/(outputImage|getImage)\\?fileId=([a-z0-9A-Z]{24})\\)", [UserService getHost]];
		NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
		content = [regularExpression stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:@"![$1](leanote://getImage?fileId=$4)"];
	}
	return content;
}


- (NSDictionary *) fixContentForPush:(NSString *)content isMarkdown:(BOOL)isMarkdown
{
	if([Common isBlankString:content]) {
		return @{@"content": @""};
	}
	
	NSMutableArray *fileIds = [[NSMutableArray alloc ]init];
	
	// 非markdown
	if(!isMarkdown) {
		
		NSString *pattern = [NSString stringWithFormat:@"src=('|\")leanote://getImage\\?fileId=([a-z0-9A-Z]{24})('|\")"];
		NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
		
		NSArray *array = [reg matchesInString:content options:0 range:NSMakeRange(0, [content length])];
		NSString *fileId = nil;
		for (NSTextCheckingResult* b in array)
		{
//			NSLog(@"%ld", b.numberOfRanges);
			// str2 是每个和表达式匹配好的字符串。
			fileId = [content substringWithRange:[b rangeAtIndex:2]];

			[fileIds addObject:fileId];
		}
		
		// 替换之
		content = [reg stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, content.length)
										   withTemplate:[NSString stringWithFormat:@"src=\"%@/api/file/getImage?fileId=$2\"", [UserService getHost]]];
	}
	// markdown
	else {
		NSString *pattern = [NSString stringWithFormat: @"!\\[(.*?)\\]\\(leanote://getImage\\?fileId=([a-z0-9A-Z]{24})\\)"];
		NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
		
		NSArray *array = [reg matchesInString:content options:0 range:NSMakeRange(0, [content length])];
		NSString *fileId = nil;
		for (NSTextCheckingResult* b in array)
		{
			// NSLog(@"%ld", b.numberOfRanges);
			// str2 是每个和表达式匹配好的字符串。
			fileId = [content substringWithRange:[b rangeAtIndex:2]];
			
			[fileIds addObject:fileId];
		}
		
		content = [reg stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, content.length) withTemplate:[NSString stringWithFormat:@"![$1](%@/api/file/getImage?fileId=$2)", [UserService getHost]]];
	}
	
	// 获得所有file信息
	NSArray *files = [FileService getAllImages:fileIds];
	if(files) {
		return @{@"files": files, @"content": content};
	}
	// nil不能当作value
	return @{@"content": content};
	
	// return content;
}

- (void) getNoteContent:(Note *) note
				success:(void (^)(NSString *))success
				   fail:(void (^)())fail
{
	// 查看本地, 是否需要重新获取内容
	if([note.isInitSync boolValue]) {
		[ApiService getNoteContent:note.serverNoteId success:^(id obj) {
			// 存到本地
			note.isInitSync = M_NO;
			note.content = obj[@"Content"];
			note.content = [self fixContent:note.content isMarkdown:[note.isMarkdown boolValue]];
			[self saveContextAndWrite];
			success(note.content);
		} fail:^{
			if(fail) {
				fail();
			}
		}];
	}
	else {
		// 不用再处理了, TODO去掉
		// 不要这行, 不然每次都会改变这一行
//		note.content = [self fixContent:note.content isMarkdown:[note.isMarkdown boolValue]];
		success(note.content);
	}
}

#pragma 发送改变


// 这个note是mainContext的, controller调用
- (void) pushNoteAndWrite:(Note *) note
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
	
	[self pushNote:note success:success fail:fail];
}

- (void) pushNote:(Note *) note
		  success:(void (^)())success
			 fail:(void (^)(id))fail
{
	// 发送改变之
	[self push:note success:^{
		if(success) {
			success();
		}
	} fail:^(id ret){
		if(fail) {
			fail(ret);
		}
	}];
}


// 发送所有dirty数据
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
	
	NSArray *notes = [self getDirtyNotes];
	if(!notes || [notes count] == 0) {
		success();
		return;
	}
	unsigned long total = [notes count];
	__block unsigned long  i = 0;
	for(Note *note in notes) {
		if(self.canceled) return;
		[self push:note success:^{
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

- (void) push:(Note *)note
	  success:(void (^)())success
		 fail:(void (^)(id))fail

{
	[self push:note success:success fail:fail noOp:nil];
}

- (void) push:(Note *)note
	  success:(void (^)())success
		 fail:(void (^)(id))fail
		 noOp:(void (^)())noOp
{
	// 非dirty, 不要push
	if(![note.isDirty boolValue]) {
		if(noOp) noOp();
		return;
	}
	
	if([note.localIsDelete boolValue]) {
		if(![Common isBlankString:note.serverNoteId]) {
			// TODO 删除
			[self pushDeleteNote:note success:success fail:fail];
		} else {
			if(noOp) noOp();
		}
		return;
	}
	
	if([Common isBlankString:note.serverNoteId] || [note.localIsNew boolValue]) {
		if(![note.isTrash boolValue]) {
			[self pushAddNote:note success:success fail:fail];
		} else {
			if(noOp) noOp();
		}
	}
	else {
		[self pushUpdateNote:note success:success fail:fail];
	}
}

- (void) saveFileMap:(id)ret
{
	if(!ret) {
		return;
	}
	// files
	NSArray *files = ret[@"Files"];
	if(![Common isNull:files] && [files count] > 0) {
		for(NSDictionary *file in files) {
			NSString *localFileId = file[@"LocalFileId"];
			NSString *serverFileId = file[@"FileId"];
			if(localFileId && serverFileId && [localFileId length] > 0 && [serverFileId length] > 0) {
				[FileService mapLocalFileIdToServiceFileId:localFileId serverFileId:serverFileId];
			}
		}
	}
}

- (void) pushUpdateNote:(Note *)note
				success:(void (^)())success
				   fail:(void (^)(id))fail
{
	
	NSDictionary *filesAndContent = [self fixContentForPush:note.content isMarkdown:[note.isMarkdown boolValue]];
	
	NSString *fixedContent = filesAndContent[@"content"];
	NSArray *files = filesAndContent[@"files"];
	
	note.status = [NSNumber numberWithInt:-1];
	
	[ApiService updateNote:note content:fixedContent files:files success:^(id ret) {
		note.status = [NSNumber numberWithInt:1];
		
		NSNumber *usn = ret[@"Usn"];
		note.usn = usn;
		note.isContentDirty = M_NO;
		note.isDirty = M_NO;
		
		[self saveFileMap:ret];
		
		[self saveContext];
		NSLog(@"pushUpdateNote %@", ret);
		
		if(success) {
			success();
		}
	} fail:^(id ret) {
		note.status = [NSNumber numberWithInt:2];
		
		if(ret) {
			NSString *msg = ret[@"Msg"];
			// 冲突, 复制之
			if(msg && [msg isEqualToString:@"conflict"]) {
				[ApiService getNote:note.serverNoteId success:^(id obj) {
					[self copyNoteForConflict:obj localNote:note];
				} fail:^{
				}];
			}
		}
		if(fail) {
			// 是否冲突
			fail(ret);
		}
	}];
}

- (void) pushAddNote:(Note *)note
				success:(void (^)())success
				fail:(void (^)(id))fail
{
	NSDictionary *filesAndContent = [self fixContentForPush:note.content isMarkdown:[note.isMarkdown boolValue]];
	
	NSString *fixedContent = filesAndContent[@"content"];
	NSArray *files = filesAndContent[@"files"];
	
	note.status = [NSNumber numberWithInt:-1];
	
	[ApiService addNote:note content:fixedContent files:files success:^(id ret) {
		note.status = [NSNumber numberWithInt:1];
		
		NSNumber *usn = ret[@"Usn"];
		note.serverNoteId = ret[@"NoteId"];
		note.usn = usn;
		note.isContentDirty = M_NO;
		note.isDirty = M_NO;
					
		[self saveFileMap:ret];
					
		[self saveContext];
		NSLog(@"pushAddNote %@", ret);
		
		if(success) {
			success();
		}
	} fail:^(id ret) {
		note.status = [NSNumber numberWithInt:2];
		
		if(fail) {
			// 是否冲突
			fail(ret);
		}
	}];
}

- (void) pushDeleteNote:(Note *)note
				success:(void (^)())success
				fail:(void (^)(id))fail
{
	[ApiService deleteNote:note success:^(id ret) {
		if(success) {
			[self.tmpContext deleteObject:note];
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

#pragma others

+ (void) getImage:(NSString *)serverFileId
		  success:(void (^)(NSString *))success
			 fail:(void (^)())fail
{
	// 先查files表是否存在
	File *file = [FileService getFileByServerFileId:serverFileId];
	if(file) {
		success(file.filePath);
		return;
	}
	else {
		file = [FileService getFileByFileId:serverFileId];
		if(file) {
			success(file.filePath);
			return;
		}
	}
	
	[ApiService getImage:serverFileId success:^(NSString * relatedPath) {
		// 存到files表中
		[FileService addOrUpdateFile:nil serverFileId:serverFileId filePath:relatedPath];
		success(relatedPath);
	} fail:^{
		fail();
	}];
}



@end
