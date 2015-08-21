//
//  SyncService.m
//  Leanote
//
//  Created by life on 15/6/7.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "SyncService.h"
#import "UserService.h"
#import "ApiService.h"

#import "Notebook.h"
#import "NotebookService.h"

#import "Note.h"
#import "NoteService.h"

#import "Tag.h"
#import "TagService.h"

@interface SyncService ()

@property (strong, nonatomic) NotebookService *notebookService;
@property (strong, nonatomic) NoteService *noteService;
@property (strong, nonatomic) TagService *tagService;
@property BOOL canceled; //  = NO; // 是否取消了, 原因是toggle user了

@end

@implementation SyncService

//@synthesize tmpContext = _tmpContext;

NSInteger maxEntryInt = 200;
SyncService *curSyncService; // 当前

BOOL inSyncing = NO;

# pragma 笔记本

// 将笔记本存到本地中, 并处理冲突
- (void) syncNotebookToLocal:(NSArray * )notebookObjs {
	
	[self.tmpContext performBlock:^{
		if(self.canceled) {
			return;
		}
//		NSLog(@"%@", notebookObjs);
		NSString *serverNotebookId;
		NSNumber *usn;
		for(id eachObj in notebookObjs) {
			serverNotebookId = eachObj[@"NotebookId"];
			usn = eachObj[@"Usn"];
			
			// 服务器端删除了, 本地也要删除
			if([eachObj[@"IsDeleted"] boolValue]) {
				NSLog(@"is deleted");
				[_notebookService deleteNotebookForceByServerNotebookId:serverNotebookId];
				continue;
			}
			
			// 得到本地笔记
			Notebook *notebook = [_notebookService getNotebookByServerNotebookId:serverNotebookId];
			
			// 存在, 更新即可, 不管是否有冲突
			if (notebook) {
				NSComparisonResult c = [usn compare:notebook.usn];
				
				// 相同或 服务器上的 < 本地的(不可能小于本地的), 表示服务器上的数据不是新的, 不用改
				if(c == NSOrderedSame || c == NSOrderedAscending) {
					NSLog(@" 重复sync笔记本, 不更新, 因为和本地一样或本地有修改 %@", notebook);
				}
				else {
					NSLog(@" updateNotebookForce %@", notebook);
					[_notebookService updateNotebookForce:eachObj];
				}
			}
			// 不存在, 添加即可
			else {
				NSLog(@" addNotebookForce ");
				[_notebookService addNotebookForce:eachObj];
			}
		}
		
		// push到context中, 并写
		[UserService saveLastSyncNotebookUsn:usn];
		[self.class saveContextIn:self.tmpContext push:YES write:YES];
	}];
}

// 同步笔记本
- (void) syncNotebook:(NSNumber *)afterUsn callback:(void (^)(BOOL))callback
{
	NSNumber *maxEntry = [NSNumber numberWithInt:maxEntryInt];
	[ApiService getSyncNotebooks:afterUsn maxEntry:maxEntry success:^(NSArray * notebookObjs) {
		if(self.canceled) {
			return;
		}
		[self syncNotebookToLocal:notebookObjs];
		
		// 如果一样, 表示很可能还有笔记本, 得到最大的usn, 递归调用之
		int count = [notebookObjs count];
		if (count == maxEntryInt) {
			NSNumber *maxUsn = notebookObjs[count-1][@"Usn"];
			[self syncNotebook:maxUsn callback:callback];
		}
		else {
			if(callback) {
				callback(YES);
			}
		}
		
	} fail:^{
		// 有错误
		if(callback) {
			callback(NO);
		}
		return;
	}];
}

# pragma 笔记

// 将笔记存到本地中, 并处理冲突
- (void) syncNoteToLocal:(NSArray * )noteObjs {
	
	[self.tmpContext performBlock:^{
		
		NSNumber *usn;
		NSString *serverNoteId;
		for(id eachObj in noteObjs) {
			if(self.canceled) {
				return;
			}
			serverNoteId = eachObj[@"NoteId"];
			usn = eachObj[@"Usn"];
			
			// 服务器端删除了, 本地也要删除
			if([eachObj[@"IsDeleted"] boolValue]) {
				NSLog(@"is deleted");
				[_noteService deleteNoteForceByServerNoteId:serverNoteId];
				continue;
			}
			
			// 得到本地笔记
			Note *note = [_noteService getNoteByServerNoteId:serverNoteId];
			
			// 存在, 更新即可, 不管是否有冲突
			if (note) {
				NSComparisonResult c = [usn compare:note.usn]; // usn是服务器上的
				
				// 相同或 服务器上的 < 本地的(不可能小于本地的), 表示服务器上的数据不是新的, 不用改
				if (c == NSOrderedSame || c == NSOrderedAscending) {
					NSLog(@" 重复sync笔记, 不更新, 因为和本地一样或本地有修改 %@", note);
				}
				// 服务器上的数据是新的, 此时
				else {
					
					// 本地修改了, 有冲突, 则复制一个
					if ([note.isDirty boolValue]) {
						NSLog(@"有冲突 服务器USN=%ld 本地note:%@", (long)[usn integerValue], note);
						[_noteService copyNoteForConflict:eachObj localNote:note];
					}
					// 本地没修改, 则用服务器的数据
					else {
						NSLog(@" updateNoteForce %@", note);
						[_noteService updateNoteForce:eachObj];
					}
				}
			}
			// 不存在, 添加即可
			else {
				NSLog(@" addNoteForce %@", eachObj);
				[_noteService addNoteForce:eachObj];
			}
		}
		
		// push到context中, 并写
		[UserService saveLastSyncNoteUsn:usn];
		[self.class saveContextIn:self.tmpContext push:YES write:YES];
		
	}];
}

// 同步笔记
- (void) syncNote:(NSNumber *)afterUsn callback:(void (^)(BOOL))callback
{
	NSNumber *maxEntry = [NSNumber numberWithInt:maxEntryInt];
	[ApiService getSyncNotes:afterUsn maxEntry:maxEntry success:^(NSArray * noteObjs) {
		if(self.canceled) {
			return;
		}
		[self syncNoteToLocal:noteObjs];
		
		// 如果一样, 表示很可能还有笔记本, 得到最大的usn, 递归调用之
		int count = [noteObjs count];
		if (count == maxEntryInt) {
			NSNumber *maxUsn = noteObjs[count-1][@"Usn"];
			[self syncNote:maxUsn callback:callback];
		}
		else if(callback) {
			callback(YES);
		}
		
	} fail:^{
		if(callback) {
			callback(NO);
		}
		return;
	}];
}

# pragma 标签

// 将笔记存到本地中, 并处理冲突
- (void) syncTagToLocal:(NSArray * )tagObjs {
	[self.tmpContext performBlock:^{
		NSNumber *usn;
		NSString *title;
		for(id eachObj in tagObjs) {
			if(self.canceled) {
				return;
			}
			title = eachObj[@"Tag"];
			usn = eachObj[@"Usn"];
			
			// 服务器端删除了, 本地也要删除
			if([eachObj[@"IsDeleted"] boolValue]) {
				NSLog(@"tag is deleted");
				[_tagService deleteTagForce:title];
				continue;
			}
			
			[_tagService addTagForce:eachObj];
		}
		
		// push到context中, 并写
		[UserService saveLastSyncTagUsn:usn];
		[self.class saveContextIn:self.tmpContext push:YES write:YES];
	}];
}

// 同步标签
- (void) syncTag:(NSNumber *)afterUsn callback:(void (^)(BOOL))callback
{
	NSNumber *maxEntry = [NSNumber numberWithInt:maxEntryInt];
	[ApiService getSyncTags:afterUsn maxEntry:maxEntry success:^(NSArray * tagObjs) {
		if(self.canceled) {
			return;
		}
		[self syncTagToLocal:tagObjs];
		
		// 如果一样, 表示很可能还有Tag, 得到最大的usn, 递归调用之
		int count = [tagObjs count];
		if (count == maxEntryInt) {
			NSNumber *maxUsn = tagObjs[count-1][@"Usn"];
			[self syncTag:maxUsn callback:callback];
		}
		else if(callback) {
			callback(YES);
		}
		
	} fail:^{
		if(callback) {
			callback(NO);
		}
		return;
	}];
}

- (void) pull:(NSNumber *)lastSyncUsn
	 callback:(void (^)(BOOL))callback
	 progress:(void (^)(int))progress
{
	if(self.canceled) {
		return;
	}
	
	// 牛!!
	NSNumber *localLastSyncNotebookUsn = [UserService getLastSyncNotebookUsn];
	NSNumber *localLastSyncNoteUsn = [UserService getLastSyncNoteUsn];
	NSNumber *localLastSyncTagUsn = [UserService getLastSyncTagUsn];

	[self syncNotebook:localLastSyncNotebookUsn callback:^(BOOL ok1) {
		[self setProgress:progress number:10];
		if(self.canceled) {
			return;
		}
		
		if(!ok1) {
			if(callback) callback(NO);
			return;
		}
		[self syncNote:localLastSyncNoteUsn callback:^(BOOL ok2) {
			[self setProgress:progress number:40];
			if(self.canceled) {
				return;
			}
			
			if(!ok2) {
				if(callback) callback(NO);
				return;
			}
			[self syncTag:localLastSyncTagUsn callback:^(BOOL ok3) {
				[self setProgress:progress number:50];
				if(self.canceled) {
					return;
				}
				if(callback) callback(ok3);
			}];
		}];
	}];
}

- (void) push:(void (^)(BOOL))success
	 progress:(void (^)(int))progress
{
	if(self.canceled) {
		return;
	}
	[_notebookService pushAll:^{
		[self setProgress:progress number:60];
		if(self.canceled) {
			return;
		}
		[_noteService pushAll:^{
			[self setProgress:progress number:90];
			if(self.canceled) {
				return;
			}
			[_tagService pushAll:^{
				[self setProgress:progress number:100];
				success(YES);
			} fail:^(id retTag) {
				[self setProgress:progress number:100];
				success(NO);
			}];
		} fail:^(id retNote) {
			[self setProgress:progress number:90];
			success(NO);
		}];
	} fail:^(id retNotebook) {
		[self setProgress:progress number:60];
		success(NO);
	}];
}

// 增量同步

- (void) setProgress:(void (^)(int))progress number:(int) number
{
	if(progress) {
		progress(number);
	}
}

- (void) initService
{
	_notebookService = [[NotebookService alloc] init];
	_notebookService.tmpContext = self.tmpContext;
	
	_noteService = [[NoteService alloc] init];
	_noteService.tmpContext = self.tmpContext;
	
	_tagService = [[TagService alloc] init];
	_tagService.tmpContext = self.tmpContext;
	
	// 可以去掉, 默认为NO
	_notebookService.canceled = NO;
	_tagService.canceled = NO;
	_noteService.canceled = NO;
}

// 取消sync, toggle user时调用
+ (void) cancelSync
{
	if(curSyncService) {
		NSLog(@"cancel Sync 取消sync");
		curSyncService.canceled = YES;
		curSyncService.notebookService.canceled = YES;
		curSyncService.noteService.canceled = YES;
		curSyncService.tagService.canceled = YES;
	}
	else {
		NSLog(@"当前没有在sync");
	}
	inSyncing = NO;
}

// 实例化
+ (SyncService *) newSync
{
	SyncService *syncService = [[SyncService alloc] init];
	syncService.tmpContext = [self getTmpContext];
	
	[syncService initService];
	syncService.canceled = NO;
	
	return syncService;
}

// progress, 0-100
// pull notebook 10, note 30, tag 10
// push notebook 10, note 30, tag 30
+ (void) incrSync:(void (^)(BOOL))cb // 结束之后调用
		 progress:(void (^)(int))progress // 进度调用
{
	SyncService *syncService = [self newSync];
	
	// 正在同步
	if(inSyncing) {
		[syncService setProgress:progress number:-1];
		return;
	}
	
	// 当前正在同步的syncService
	curSyncService = syncService;
	
	// 这个callback在完成时会调用
	void (^callback)(BOOL) = ^(BOOL ret) {
		inSyncing = NO;
		if(cb) {
			cb(ret);
			if(!ret) {
				[syncService setProgress:progress number:-2];
			}
		}
	};

	// 开始同步喽
	[syncService setProgress:progress number:1];

	NSNumber *localLastSyncUsn = [UserService getLastSyncUsn];
	
	// 得到服务端的usn, 与本地usn对比, 看是否需要pull
	[ApiService getSyncState:^(id ret) {
		NSNumber *lastSyncUsn = ret[@"LastSyncUsn"];

		if([lastSyncUsn integerValue] > [localLastSyncUsn integerValue]) {
			NSLog(@"需要pull");
			
			// 1. pull
			[syncService pull:localLastSyncUsn callback:^(BOOL pullOk) {
				if(!pullOk) {
					if(callback) callback(NO);
				} else {
					// 2. push
					[syncService push:^(BOOL ok4) {
						[UserService saveLastSyncUsn];
						if(callback) {
							callback(ok4);
						}
					} progress:progress];
				}
			} progress:progress];
		}
		else {
			NSLog(@"无需pull");
			[syncService setProgress:progress number:50];
			// 2. push
			[syncService push:^(BOOL ok4) {
				[UserService saveLastSyncUsn];
				if(callback) {
					callback(ok4);
				}
			} progress:progress];
		}

	} fail:^(id f) {
		NSLog(@"getSyncState 出错, 要重来吗?");
		if(callback) callback(NO);
	}];
}

@end
