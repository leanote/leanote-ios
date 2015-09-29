//
//  ApiService.m
//  Leanote
//
//  Created by life on 15/6/6.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "ApiService.h"

#import "AFNetworkTool.h"
#import "UserService.h"
#import "NotebookService.h"
#import "Leas.h"
#import "Note.h"
#import "Common.h"
#import "File.h"

@implementation ApiService

// 因为用户有可能会自定义host, 故api url不固定
// 自动加上token
+ (NSString *) getApiUrl:(NSString *)urlSuffix
{
	return [NSString stringWithFormat:@"%@/api/%@?token=%@", [UserService getHost], urlSuffix, [UserService getToken]];
}

// 登录
+ (void) login:(NSString *) username
		   pwd:(NSString *) pwd
		  host:(NSString *) host // http://localhost:9000
	   success:(void (^)(id))success
		  fail:(void (^)())fail {
	NSString *url = [NSString stringWithFormat:@"%@/api/auth/login", host];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"email": username,
																				  @"pwd": pwd,
																				  }];
	[AFNetworkTool post:url params:params success:^(id obj) {
		if (success) {
			NSLog(@"ret: %@", obj);
			success(obj);
		}
		
	} fail:^(id ret){
		NSLog(@"请求失败");
		if (fail) {
			fail();
		}
	}];
}

// 注册
+ (void) register:(NSString *) email
		   pwd:(NSString *) pwd
	   success:(void (^)(id))success
		  fail:(void (^)(id))fail {
	
	NSString *url;
	
	url = [self getApiUrl:@"auth/register"];
	
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"email": email,
																				  @"pwd": pwd,
																				  }];
	[AFNetworkTool post:url params:params success:^(id obj) {
		if (success) {
			NSLog(@"ret: %@", obj);
			success(obj);
		}
		
	} fail:^(id ret){
		NSLog(@"请求失败");
		if (fail) {
			fail(ret);
		}
	}];
}

// 获取note
+ (void) getNote:(NSString *) serverNoteId
				  success:(void (^)(id))success
					 fail:(void (^)())fail
{
	NSString *url = [self getApiUrl:@"note/getNote"];
	NSLog(@"url %@", url);
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"noteId": serverNoteId,
																				  }];
	[AFNetworkTool get:url params:params success:^(id obj) {
				if (success) {
			NSLog(@" get note---> %@", obj);
			success(obj);
		}
		
	} fail:^(id ret) {
		NSLog(@"请求失败 %@", ret);
	}];
}


// 获取需要同步的笔记本
+ (void) getSyncNotebooks:(NSNumber *) afterUsn
				 maxEntry:(NSNumber *) maxEntry
				  success:(void (^)(NSArray *))success
					 fail:(void (^)())fail
{
	NSString *url = [self getApiUrl:@"notebook/getSyncNotebooks"];
	NSLog(@"url %@", url);
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"afterUsn": afterUsn,
																				  @"maxEntry": maxEntry,
																				  }];
	[AFNetworkTool get:url params:params success:^(id objs) {
		// {Ok: false, Msg: "NOTLOGIN"}
		NSLog(@"class %@", [objs class]); // __NSCFDictionary
		
		// 组装成一个数组[id, id]
		NSMutableArray *notebooks = [NSMutableArray array];
		for(id eachObj in objs){
			[notebooks addObject:eachObj];
		}
		if (success) {
			NSLog(@"---> %@", objs);
			NSLog(@"getSyncNotebooks %lu", (unsigned long)[notebooks count]);
			success(notebooks);
		}
		
	} fail:^(id ret) {
		NSLog(@"请求失败 %@", ret);
		if(fail) fail();
	}];
}

// 获取需要同步的笔记
+ (void) getSyncNotes:(NSNumber *) afterUsn
				 maxEntry:(NSNumber *) maxEntry
				  success:(void (^)(NSArray *))success
					 fail:(void (^)())fail
{
	NSString *url = [self getApiUrl:@"note/getSyncNotes"];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"afterUsn": afterUsn,
																				  @"maxEntry": maxEntry,
																				  }];
	[AFNetworkTool get:url params:params success:^(id objs) {
		// 组装成一个数组[id, id]
		NSMutableArray *notebooks = [NSMutableArray array];
		for(id eachObj in objs){
			[notebooks addObject:eachObj];
		}
		if (success) {
			NSLog(@"getSyncNotes %lu", (unsigned long)[notebooks count]);
			success(notebooks);
		}
		
	} fail:^(id ret){
		NSLog(@"请求失败");
		if(fail) fail();
	}];
}


// 获取需要同步的标签
+ (void) getSyncTags:(NSNumber *) afterUsn
			 maxEntry:(NSNumber *) maxEntry
			  success:(void (^)(NSArray *))success
				 fail:(void (^)())fail
{
	NSString *url = [self getApiUrl:@"tag/getSyncTags"];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"afterUsn": afterUsn,
																				  @"maxEntry": maxEntry,
																				  }];
	[AFNetworkTool get:url params:params success:^(id objs) {
		// 组装成一个数组[id, id]
		NSMutableArray *tags = [NSMutableArray array];
		for(id eachObj in objs){
			[tags addObject:eachObj];
		}
		if (success) {
			NSLog(@"getSyncTags %lu", (unsigned long)[tags count]);
			success(tags);
		}
		
	} fail:^(id ret){
		NSLog(@"请求失败");
		if(fail) fail();
	}];
}


+ (void) getNoteContent:(NSString *) serverNoteId
				success:(void (^)(id))success
				   fail:(void (^)())fail
{
	NSString *url = [self getApiUrl:@"note/getNoteContent"];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"noteId": serverNoteId
																				  }];
	[AFNetworkTool get:url params:params success:^(id obj) {
		if (success) {
			success(obj);
		}
		
	} fail:^(id ret){
		NSLog(@"请求失败");
		if(fail) fail();
	}];
}

// 更新笔记
+ (void) updateNote:(Note *)note
			content:(NSString *)content
			  files:(NSArray *)files
			success:(void (^)(id))success
			   fail:(void (^)(id))fail
{
	NSString *serverNotebookId = @"";
	if(![Common isBlankString:note.notebookId]) {
		Notebook *notebook = [Leas.notebook getNotebookByNotebookId:note.notebookId];
		if(notebook && notebook.serverNotebookId) {
			serverNotebookId = notebook.serverNotebookId;
		}
	}
	
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"NoteId": note.serverNoteId,
																				  @"NotebookId": serverNotebookId,
																				  @"Title": note.title ? note.title : @"",
																				  @"Usn": note.usn,
																				  @"IsTrash": note.isTrash,
																				  @"IsBlog": note.isBlog, // 是否是博客
																				  // FileDatas: note.FileDatas,
																				  @"Tags[0]": @""
																				  }];
	// 处理标签
	NSArray *tags = [note.tags componentsSeparatedByString:@","];
	if(!tags) {
		tags = @[];
	}
	int i = 0;
	for(NSString *eachTag in tags) {
		[params setObject:eachTag forKey:[NSString stringWithFormat:@"Tags[%d]", i]];
		i++;
	}
	
	// 处理文件
	if(![Common isNull:files]) {
		int i = 0;
		for(File *file in files) {
			NSMutableDictionary *obj = [NSMutableDictionary dictionaryWithDictionary:@{
																						@"FileId":file.serverFileId,
																						@"LocalFileId": file.fileId,
																						@"HasBody": [file.serverFileId length] > 0 ? M_NO : M_YES,
																						// @"Title": file.type,
																						// @"Type": @"jpg",
																						@"IsAttach":M_NO
																						}];
			[params setObject:obj forKey:[NSString stringWithFormat:@"Files[%d]", i]];
			i++;
		}
	}
	
	
	if([note.isContentDirty boolValue]) {
		params[@"Content"] = content;
	}
	
	NSString *url = [self getApiUrl:@"note/updateNote"];
	[AFNetworkTool postWithData:url
						 params:params
						  files:files
						success:^(id ret) {
		if (success) {
			NSLog(@"updateNote ret: %@", ret);
			success(ret);
		}
	} fail:^(id ret){
		NSLog(@"请求失败");
		if (fail) {
			fail(ret);
		}
	}];
}

// 添加笔记
+ (void) addNote:(Note *)note
			content:(NSString *)content
		   files:(NSArray *)files
			success:(void (^)(id))success
			   fail:(void (^)(id))fail
{
	NSString *serverNotebookId = @"";
	if(![Common isBlankString:note.notebookId]) {
		Notebook *notebook = [Leas.notebook getNotebookByNotebookId:note.notebookId];
		if(notebook && notebook.serverNotebookId) {
			serverNotebookId = notebook.serverNotebookId;
		}
	}
	
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"NotebookId": serverNotebookId,
																				  @"Title": note.title,
																				  @"IsTrash": note.isTrash,
																				  @"IsMarkdown": note.isMarkdown,
																				  @"IsBlog": note.isBlog, // 是否是博客
																				  // Files: note.Files,
																				  // FileDatas: note.FileDatas,
																				  @"Tags[0]": @"",
																				  @"Content": content,
																				  }];
	// 处理标签
	NSArray *tags = [note.tags componentsSeparatedByString:@","];
	if(!tags) {
		tags = @[];
	}
	int i = 0;
	for(NSString *eachTag in tags) {
		[params setObject:eachTag forKey:[NSString stringWithFormat:@"Tags[%d]", i]];
		i++;
	}
	
	// 处理文件
	if(![Common isNull:files]) {
		int i = 0;
		for(File *file in files) {
			NSMutableDictionary *obj = [NSMutableDictionary dictionaryWithDictionary:@{
																					   @"FileId":file.serverFileId,
																					   @"LocalFileId": file.fileId,
																					   @"HasBody": [file.serverFileId length] > 0 ? M_NO : M_YES,
																					   // @"Title": file.type,
																					   // @"Type": @"jpg",
																					   @"IsAttach":M_NO
																					   }];
			[params setObject:obj forKey:[NSString stringWithFormat:@"Files[%d]", i]];
			i++;
		}
	}
	
	NSString *url = [self getApiUrl:@"note/addNote"];
	[AFNetworkTool postWithData:url params:params files:files success:^(id ret) {
		if (success) {
			NSLog(@"addNote ret: %@", ret);
			success(ret);
		}
	} fail:^(id ret){
		NSLog(@"addNote 请求失败 %@", ret);
		if (fail) {
			fail(ret);
		}
	}];
}

+ (void) deleteNote:(Note *) note
			success:(void (^)(id))success
			fail:(void (^)(id))fail
{
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"noteId": note.serverNoteId,
																				  @"usn": note.usn,
																				  }];
	NSString *url = [self getApiUrl:@"note/deleteTrash"];
	[AFNetworkTool post:url params:params success:^(id ret) {
		if (success) {
			NSLog(@"deleteTrash ret: %@", ret);
			success(ret);
		}
	} fail:^(id ret){
		NSLog(@"deleteTrash 请求失败 %@", ret);
		if (fail) {
			fail(ret);
		}
	}];
}

// 下载图片
+ (void) getImage:(NSString *)fileId
		  success:(void (^)(NSString *))success
			 fail:(void (^)())fail

{
	NSString *url = [self getApiUrl:@"file/getImage"];
	url  = [NSString stringWithFormat:@"%@&fileId=%@", url, fileId];
	[AFNetworkTool download:url success:^(NSString *relativePath) {
		success(relativePath);
	} fail:^{
		fail();
	}];
}

#pragma  tag

+ (void) addTag:(NSString *) tagTitle
		success:(void (^)(id))success
		   fail:(void (^)(id))fail
{
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"tag": tagTitle
																				  }];
	NSString *url = [self getApiUrl:@"tag/addTag"];
	[AFNetworkTool post:url params:params success:^(id ret) {
		if (success) {
			NSLog(@"addTag ret: %@", ret);
			success(ret);
		}
	} fail:^(id ret){
		NSLog(@"addTag 请求失败 %@", ret);
		if (fail) {
			fail(ret);
		}
	}];
}


+ (void) deleteTag:(Tag *) tag
			success:(void (^)(id))success
			   fail:(void (^)(id))fail
{
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"tag": tag.title,
																				  @"usn": tag.usn,
																				  }];
	NSString *url = [self getApiUrl:@"tag/deleteTag"];
	[AFNetworkTool post:url params:params success:^(id ret) {
		if (success) {
			NSLog(@"deleteTag ret: %@", ret);
			success(ret);
		}
	} fail:^(id ret){
		NSLog(@"deleteTag 请求失败 %@", ret);
		if (fail) {
			fail(ret);
		}
	}];
}

#pragma 笔记本 push

+ (NSString *) getParentServerNotebookId:(Notebook *) notebook
{
	if(![Common isBlankString:notebook.parentNotebookId]) {
		Notebook *parentNotebook = [Leas.notebook getNotebookByNotebookId:notebook.parentNotebookId];
		if(parentNotebook && ![Common isBlankString:parentNotebook.serverNotebookId]) {
			return parentNotebook.serverNotebookId;
		}
	}
	return @"";
}

+ (void) addNotebook:(Notebook *) notebook
		success:(void (^)(id))success
		   fail:(void (^)(id))fail
{
	// 上级笔记本
	NSString *parentServerNotebookId = [self getParentServerNotebookId:notebook];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"title": notebook.title,
																				  @"seq": notebook.seq,
																				  @"parentNotebookId": parentServerNotebookId,
																				  }];
	NSString *url = [self getApiUrl:@"notebook/addNotebook"];
	[AFNetworkTool post:url params:params success:^(id ret) {
		if (success) {
			NSLog(@"addNotebook ret: %@", ret);
			success(ret);
		}
	} fail:^(id ret){
		NSLog(@"addNotebook 请求失败 %@", ret);
		if (fail) {
			fail(ret);
		}
	}];
}

+ (void) updateNotebook:(Notebook *) notebook
			 success:(void (^)(id))success
				fail:(void (^)(id))fail
{
	// 上级笔记本
	NSString *parentNotebookId = [self getParentServerNotebookId:notebook];
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"title": notebook.title,
																				  @"seq": notebook.seq,
																				  @"notebookId": notebook.serverNotebookId,
																				  @"parentNotebookId": parentNotebookId,
																				  @"usn": notebook.usn,
																				  }];
	NSString *url = [self getApiUrl:@"notebook/updateNotebook"];
	[AFNetworkTool post:url params:params success:^(id ret) {
		if (success) {
			NSLog(@"updateNotebook ret: %@", ret);
			success(ret);
		}
	} fail:^(id ret){
		NSLog(@"updateNotebook 请求失败 %@", ret);
		if (fail) {
			fail(ret);
		}
	}];
}

+ (void) deleteNotebook:(Notebook *)notebook
		   success:(void (^)(id))success
			  fail:(void (^)(id))fail
{
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
																				  @"notebookId": notebook.serverNotebookId,
																				  @"usn": notebook.usn,
																				  }];
	NSString *url = [self getApiUrl:@"notebook/deleteNotebook"];
	[AFNetworkTool post:url params:params success:^(id ret) {
		if (success) {
			NSLog(@"deleteNotebook ret: %@", ret);
			success(ret);
		}
	} fail:^(id ret){
		NSLog(@"deleteNotebook 请求失败 %@", ret);
		if (fail) {
			fail(ret);
		}
	}];
}

+ (void) getSyncState:(void (^)(id))success
				 fail:(void (^)(id))fail
{
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{}];
	NSString *url = [self getApiUrl:@"user/getSyncState"];
	[AFNetworkTool get:url params:params success:^(id ret) {
		if (success) {
			NSLog(@"getSyncState ret: %@", ret);
			success(ret);
		}
	} fail:^(id ret){
		NSLog(@"getSyncState 请求失败 %@", ret);
		if (fail) {
			fail(ret);
		}
	}];
}

@end
