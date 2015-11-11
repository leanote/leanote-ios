//
//  NoteService.h
//  Leanote
//
//  Created by life on 15/4/30.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "Note.h"
#import "Notebook.h"
#import "Tag.h"
#import "BaseService.h"

#import "Common.h"

@interface NoteService : BaseService
@property BOOL canceled; //  = NO; // 是否取消了, 原因是toggle user了


//+ (NoteService *) getInstance;
//+ (void) init: (NSManagedObjectContext *) managedObjectContext;

#pragma 同步操作
- (BOOL)deleteNoteForceByServerNoteId:(NSString *)serverNoteId;
- (Note *)getNoteByServerNoteId:(NSString *)serverNoteId;
- (Note *)updateNoteForce:(id)obj
				  content:(NSString*) content;
- (Note *)addNoteForce:(id)obj;
- (void)copyNoteForConflict:(id)obj localNote:(Note *)localNote;

#pragma 本地笔记操作
- (Note *)addNote:(NSString *)title content:(NSString *)content notebook:(Notebook *)notebook tag:(Tag *) tag;

- (void)updateNote:(Note *)note forNotebook:(BOOL)forNotebook forBlog:(BOOL)forBlog forTags:(BOOL)forTags tags:(NSString *)tags;

- (BOOL)updateNote:(Note *)note title:(NSString *)title content:(NSString *)content;
- (void) updateNoteNotebook:(Note *)note notebook:(Notebook*)notebook;
- (void) pushNoteAndWrite:(Note *) note
				  success:(void (^)())successCb
					 fail:(void (^)(id))failCb;
- (void) pushNote:(Note *) note
				success:(void (^)())success
				   fail:(void (^)(id))fail;

- (void) pushAll:(void (^)())success
		 fail:(void (^)(id))fail;

- (BOOL)deleteNote:(Note *)note
		  success:(void (^)())success
			 fail:(void (^)(id))fail;

+ (void) deleteTag:(NSString *)tagTitle
		 inContext:(NSManagedObjectContext *)inContext;

+ (void)deleteAllNotes:(NSString *)userId;

- (void) getNoteContent:(Note *) note
				success:(void (^)(NSString *))success
				   fail:(void (^)())fail;
- (void) getNoteContent:(NSString *) serverNoteId
				isMarkdown:(BOOL) isMarkdown
				success:(void (^)(NSString *))success
				   fail:(void (^)())fail;

+ (void) getImage:(NSString *)serverFileId
		  success:(void (^)(NSString *))success
			 fail:(void (^)())fail;

- (void) pushUpdateNote:(Note *) note
				content:(NSString *)content
				success:(void (^)())success
				   fail:(void (^)(id))fail;

- (NSFetchedResultsController *) fetchedResultsControllerWithPredicate:(NSString *)predicateStr
														withController:(UIViewController *)controller
															  notebook:(Notebook *)notebook
																   tag:(Tag *)tag
																isBlog:(BOOL)isBlog;

@end