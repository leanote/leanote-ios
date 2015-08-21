//
//  FileService.h
//  Leanote
//
//  Created by life on 15/6/14.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseService.h"
#import "File.h"

@interface FileService : BaseService
+ (File *)getFileByServerFileId:(NSString *)serverFileId;
+ (File *)getFileByFileId:(NSString *)fileId;
+ (File *) addOrUpdateFile:(NSString *)fileId serverFileId:(NSString *)serverFileId filePath:(NSString *)filePath;
+ (File *) addLocalFile:(NSString *) relativePath;
+ (NSArray *) getAllImages:(NSArray *)fileIds;
+ (void) mapLocalFileIdToServiceFileId:(NSString *)localFileId serverFileId:(NSString *)serverFileId;

+ (NSString *) getFileAbsPathByFileIdOrServerFileId:(NSString *) fileId;
+(void)deleteAllFiles:(NSString *)userId;

@end
