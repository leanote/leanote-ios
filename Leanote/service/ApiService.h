//
//  ApiService.h
//  Leanote
//
//  Created by life on 15/6/6.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Notebook.h"
#import "Note.h"
#import "Tag.h"

@interface ApiService : NSObject


+ (void) login:(NSString *) username
				 pwd: (NSString *) pwd
		  host: (NSString *) host
				  success:(void (^)(id))success
					 fail:(void (^)())fail;

+ (void) register:(NSString *) email
	pwd:(NSString *) pwd
	success:(void (^)(id))success
	fail:(void (^)(id))fail;

+ (void) getNote:(NSString *) serverNoteId
		 success:(void (^)(id))success
			fail:(void (^)())fail;

+ (void) getSyncNotebooks:(NSNumber *) afterUsn
				 maxEntry:(NSNumber *) maxEntry
				  success:(void (^)(NSArray *))success
					 fail:(void (^)())fail;

+ (void) getSyncNotes:(NSNumber *) afterUsn
			 maxEntry:(NSNumber *) maxEntry
			  success:(void (^)(NSArray *))success
				 fail:(void (^)())fail;

+ (void) getSyncTags:(NSNumber *) afterUsn
			 maxEntry:(NSNumber *) maxEntry
			  success:(void (^)(NSArray *))success
				 fail:(void (^)())fail;

+ (void) getNoteContent:(NSString *) serverNoteId
				success:(void (^)(id))success
				   fail:(void (^)())fail;

+ (void) updateNote:(Note *) note
			content:(NSString *)content
			  files:(NSArray *)files
			success:(void (^)(id))success
			   fail:(void (^)(id))fail;

+ (void) addNote:(Note *) note
		 content:(NSString *)content
		   files:(NSArray *)files
			success:(void (^)(id))success
			   fail:(void (^)(id))fail;

+ (void) deleteNote:(Note *) note
			success:(void (^)(id))success
			   fail:(void (^)(id))fail;

+ (void) getImage:(NSString *)fileId
		  success:(void (^)(NSString *))success
			 fail:(void (^)())fail;

+ (void) addTag:(NSString *) tagTitle
			success:(void (^)(id))success
			fail:(void (^)(id))fail;

+ (void) deleteTag:(Tag *) tag
			success:(void (^)(id))success
			   fail:(void (^)(id))fail;

#pragma notebook push

+ (void) addNotebook:(Notebook *) notebook
			 success:(void (^)(id))success
				fail:(void (^)(id))fail;
+ (void) updateNotebook:(Notebook *) notebook
			 success:(void (^)(id))success
				fail:(void (^)(id))fail;
+ (void) deleteNotebook:(Notebook *) notebook
			 success:(void (^)(id))success
				fail:(void (^)(id))fail;

+ (void) getSyncState:(void (^)(id))success
				   fail:(void (^)(id))fail;
@end
