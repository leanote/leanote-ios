//
//  NotebookService.h
//  Leanote
//
//  Created by life on 15/4/30.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "Notebook.h"
#import "Tag.h"
#import "BaseService.h"

@interface NotebookService : BaseService
@property BOOL canceled; //  = NO; // 是否取消了, 原因是toggle user了

// 以下方法都已过时
//+ (NotebookService *) getInstance;
//+ (Notebook *) getCurNotebook;
//+ (void) setCurNotebook:(Notebook *)notebook;
////+ (void) clearCurNotebook;
//+ (void) init: (NSManagedObjectContext *) managedObjectContext;


+ (NSString *) getFirstNotebookId:(NSManagedObjectContext *)inContext;

#pragma 同步操作
- (BOOL)deleteNotebookForceByServerNotebookId:(NSString *)serverNotebookId;
- (NSString *)getNotebookTitleByNotebookId:(NSString *)notebookId;
- (Notebook *)getNotebookByNotebookId: (NSString *)notebookId;

- (Notebook *)getNotebookByServerNotebookId:(NSString *)serverNotebookId;
+ (Notebook *)getNotebookByServerNotebookId:(NSString *)serverNotebookId
								  inContext:(NSManagedObjectContext *)inContext;

- (Notebook *)updateNotebookForce:(id)obj;
- (Notebook *)addNotebookForce:(id)obj;

#pragma 本地笔记本操作
- (Notebook *)addNotebook:(NSString *)name;

+ (void)recountNotebookNoteCount:(Notebook *)notebook
					   inContext:(NSManagedObjectContext *)inContext;
+ (void)recountNotebookNoteCountByNotebookId:(NSString *)notebookId
								   inContext:(NSManagedObjectContext *)inContext;

- (BOOL)deleteNotebok:(Notebook *)notebook
		  success:(void (^)())success
			 fail:(void (^)(id))fail;
+ (void)deleteAllNoteboks:(NSString *)userId;

#pragma push

- (void) push:(Notebook *)notebook
	  success:(void (^)())success
		 fail:(void (^)(id))fail;
- (void) pushAndWrite:(Notebook *)notebook
			  success:(void (^)())successCb
				 fail:(void (^)(id))failCb;

- (void) pushAll:(void (^)())success
		 fail:(void (^)(id))fail;

- (void)deleteNotebook;
- (void)updateNotebook;
- (void)getNotebook;



@end