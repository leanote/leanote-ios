//
//  Common.h
//  Leanote
//
//  Created by life on 15/6/12.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Common : NSObject
+ (BOOL) isNull:(id) i;
+ (BOOL) isBlankString:(NSString *)string;
+ (NSString *) getDocPath;
+ (NSString *) getAbsPath:(NSString *)relatedPath;
+ (NSURL *) getDocPathURL;
+ (BOOL) createDir:(NSString *) relatedPath;
+ (NSString *) newObjectId;
+ (NSString *)getFileIdFromUrl:(NSString *)url;
+ (BOOL) validateEmail: (NSString *) candidate;
+ (NSString *) trimNewLine:(NSString *) str;

+(void) showProgress;
+(void) hideProgress;
+(void) showProgressWithStatus:(NSString *) status;
+(void) showSuccessMsg:(NSString *)msg;

+(void) setTimeout:(int)seconds callback:(void (^)())callback;
+(void) async:(void (^)())func;

+(void) setBarStyleLight;
+(void) setBarStyleBlack;

+ (BOOL)isiOSVersionEarlierThan8;

+ (NSDate *)goDate:(NSString *)dateStr;
@end
