//
//  UserService.h
//  Leanote
//
//  Created by life on 15/6/6.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseService.h"
#import "User.h"

@interface UserService : BaseService

+ (BOOL) getOpenInited;
+ (BOOL) setOpenInited:(BOOL)inited;

+ (User *) init;
+ (User *) getCurUser;
+ (NSString *) getCurUserId;
+ (NSString *) getHost;
+ (NSString *) getDefaultHost;
+ (NSString *) getToken;

+ (NSNumber *) getLastSyncUsn;
+ (NSNumber *) getLastSyncNotebookUsn;
+ (NSNumber *) getLastSyncNoteUsn;
+ (NSNumber *) getLastSyncTagUsn;

+ (void) saveLastSyncUsn;

+ (void) saveLastSyncNotebookUsn:(NSNumber *) usn;
+ (void) saveLastSyncNoteUsn:(NSNumber *) usn;
+ (void) saveLastSyncTagUsn:(NSNumber *) usn;

+ (void) activeUser:(User *)user;

+ (void) login:(NSString *) username
				 pwd: (NSString *) pwd
		  host: (NSString *) host
	   success:(void (^)(User *))success
		  fail:(void (^)())fail;

+ (void) register:(NSString *) email
				 pwd: (NSString *) pwd
	   success:(void (^)(User *))success
		  fail:(void (^)(id))fail;

+ (NSArray *) getUsers;
+ (void) deleteAllData:(User *)user;

+ (NSString *) getMyBlogUrl;
+ (NSString *) getPostUrl:(NSString *)noteId;

+ (BOOL) isNormalEditor;
+ (void) setDefaultEditor:(BOOL)isNormalEditor;

@end
