//
//  FileService.m
//  Leanote
//
//  Created by life on 15/6/14.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "FileService.h"
#import "Common.h"
#import "UserService.h"

@implementation FileService

+ (File *)getFileByFileId:(NSString *)fileId {
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"File" inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"fileId = %@", fileId];
	[fetchRequest setPredicate:predicate];
	
	NSError * requestError = nil;
	NSArray * files = [self.context executeFetchRequest:fetchRequest error:&requestError];
	NSLog(@"getFileByFileId ret: %@", files);
	if ([files count] == 1) {
		return files[0];
	}
	NSLog(@"getFileByFileId ret nil");
	return nil;
}

+ (NSString *) getFileAbsPathByFileIdOrServerFileId:(NSString *) fileId
{
	File *file = [self getFileByFileId:fileId];
	if(!file) {
		file = [self getFileByServerFileId:fileId];
	}
	if(!file) {
		return nil;
	}
	
	return [Common getAbsPath:file.filePath];
}

+ (File *)getFileByServerFileId:(NSString *)serverFileId {
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"File" inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"serverFileId = %@", serverFileId];
	[fetchRequest setPredicate:predicate];
	
	NSError * requestError = nil;
	NSArray * files = [self.context executeFetchRequest:fetchRequest error:&requestError];
	NSLog(@"getFileByServerFileId ret: %@", files);
	if ([files count] == 1) {
		return files[0];
	}
	NSLog(@"getFileByServerFileId ret nil");
	return nil;
}

// 新增或更新
+ (File *) addOrUpdateFile:(NSString *)fileId serverFileId:(NSString *)serverFileId filePath:(NSString *)filePath
{
	File *file = [self getFileByServerFileId:fileId];
	
	if(file) {
		file.filePath = filePath;
		[self saveContext];
		return file;
	}
	
	// 新增
	file = [NSEntityDescription insertNewObjectForEntityForName:@"File" inManagedObjectContext:self.context];
	if(!fileId) {
		fileId = [Common newObjectId];
	}
	file.serverFileId = serverFileId;
	file.fileId = fileId;
	file.filePath = filePath;
	file.userId = [UserService getCurUserId];
	file.isAttach = M_NO;
	[self saveContext];
	
	return file;
}

// 新增本地图片
+ (File *) addLocalFile:(NSString *) relativePath
{
	// 新增
	File *file = [NSEntityDescription insertNewObjectForEntityForName:@"File" inManagedObjectContext:self.context];
	
	// localFileId
	file.fileId = [Common newObjectId];
	
	file.serverFileId = @"";
	file.filePath = relativePath;
	// file.isDirty = M_YES;
	file.userId = [UserService getCurUserId];
	file.isAttach = M_NO;
	[self saveContext];
	
	return file;
}

// 得到所有图片
+ (NSArray *) getAllImages:(NSArray *)fileIds
{
	if(!fileIds || [fileIds count] == 0) {
		return nil;
	}
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"File" inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"serverFileId in %@ or fileId in %@", fileIds, fileIds];
	[fetchRequest setPredicate:predicate];
	
	NSError * requestError = nil;
	NSArray * files = [self.context executeFetchRequest:fetchRequest error:&requestError];
	return files;
}

// 建立localFileId与serverFileId的映射
+ (void) mapLocalFileIdToServiceFileId:(NSString *)localFileId serverFileId:(NSString *)serverFileId
{
	File *file = [self getFileByFileId:localFileId];
	if(file) {
		file.serverFileId = serverFileId;
		[self saveContext];
	}
}

+(void)deleteAllFiles:(NSString *)userId
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"File" inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSString *q = [NSString stringWithFormat:@"userId='%@'", userId];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:q];
	[fetchRequest setPredicate:predicate];
	
	NSError *requestError = nil;
	NSArray *files = [self.context executeFetchRequest:fetchRequest error:&requestError];
	
	NSFileManager *fileMgr = [NSFileManager defaultManager];
	NSError *err;
	for(File *file in files) {
		// 先删除本地
		NSString *absPath = [Common getAbsPath:file.filePath];
		BOOL exists = [fileMgr fileExistsAtPath:absPath];
		if (exists) {
			[fileMgr removeItemAtPath:absPath error:&err];
		}
		
		[self.context deleteObject:file];
	}
	
	[self saveContext];
}


@end
