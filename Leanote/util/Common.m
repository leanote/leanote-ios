//
//  Common.m
//  Leanote
//
//  Created by life on 15/6/12.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "Common.h"
#import "MongoID.h"

#import "SVProgressHUD.h"
#import "WPStyleGuide.h"

@implementation Common

/*
+ (BOOL) isNull:(id) i {
	if(i) {
		return (NSNull *)i == [NSNull null];
	}
	else {
		return NO;
	}
	// return !i || (NSNull *)i == [NSNull null];
}
*/

+ (BOOL) isNullOrNil:(id) i {
	return !i || (NSNull *)i == [NSNull null];
}

+ (BOOL) isBlankString:(NSString *)string {
	if (string == nil || string == NULL) {
		return YES;
	}
	if ([string isKindOfClass:[NSNull class]]) {
		return YES;
	}
	if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
		return YES;
	}
	return NO;
}

// 去掉字符串前后空格、换行符的方法
+ (NSString *) trimNewLine:(NSString *) str
{
	return [str stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]]; // whitespaceAndNewlineCharacterSet
}

// 去掉所有换行符
+ (NSString *) trimAllNewLine:(NSString *) str
{
	str = [str stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

//  /Users/life/Library/Developer/CoreSimulator/Devices/42036FAF-BEE1-4C4A-8916-FFD229FDA1CB/data/Containers/Data/Application/F4AA8D3C-3242-4E26-BE07-6053F3B62C43/Documents/
+ (NSString *) getDocPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
	return documentsDirectory;
}

+ (NSString *) getAbsPath:(NSString *)relatedPath
{
	NSString *docPath = [self getDocPath];
	// 把relatedPath前面的/去掉
	return [NSString stringWithFormat:@"%@/%@", docPath, relatedPath];
}


//  file:///Users/life/Library/Developer/CoreSimulator/Devices/42036FAF-BEE1-4C4A-8916-FFD229FDA1CB/data/Containers/Data/Application/F4AA8D3C-3242-4E26-BE07-6053F3B62C43/Documents/
+ (NSURL *) getDocPathURL
{
	return [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
}

// relatedPath = @"/images"
+ (BOOL) createDir:(NSString *) relatedPath
{
	NSString *dataPath = [[self getDocPath] stringByAppendingPathComponent:relatedPath];
	if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:nil];
	}
	return YES;
}

// https://github.com/aantthony/mongo-objectid-objc
+ (NSString *) newObjectId
{
	ObjectID _id = [MongoID id];
	NSString *str = [MongoID stringWithId: _id];
	// NSLog(@"ID: %@", str);
	return str;
}

// leanote://getImage?fileId=xxxxx
+ (NSString *)getFileIdFromUrl:(NSString *)url
{
	if([self isBlankString:url]) {
		return nil;
	}
	NSString *pattern = [NSString stringWithFormat:@"leanote://getImage\\?fileId=([a-z0-9A-Z]{24})"];
	NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	
	NSArray *array = [reg matchesInString:url options:0 range:NSMakeRange(0, [url length])];
	for (NSTextCheckingResult* b in array)
	{
		return [url substringWithRange:[b rangeAtIndex:1]];
	}
	return nil;
}

#pragma validate

+ (BOOL) validateEmail: (NSString *) candidate {
	NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	return [emailTest evaluateWithObject:candidate];
}


#pragma SVProgressHUD

+(void) resetProgressStyle
{
//	[SVProgressHUD setBackgroundColor:[[WPStyleGuide littleEddieGrey] colorWithAlphaComponent:0.95]];
//	[SVProgressHUD setForegroundColor:[UIColor whiteColor]];
}

+(void) setProgressStyle
{
//	[SVProgressHUD setBackgroundColor2:[UIColor whiteColor]];
//	[SVProgressHUD setForegroundColor2:[UIColor blackColor]];
}

+(void) showProgress
{
	[self setProgressStyle];
	[SVProgressHUD show];
}

+(void) showProgressWithStatus:(NSString *) status
{
//	[self setProgressStyle];
	[SVProgressHUD showWithStatus:status];
}

+(void) hideProgress
{
	[SVProgressHUD dismiss];
	/*
	// 必须要延迟, 不然hideProgress reset setBackgroundColor 是后面的背景
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
		NSLog(@"hello resetProgressStyle!");
		// [self resetProgressStyle];
	});
	*/
}

+(void) showSuccessMsg:(NSString *)msg
{
	[SVProgressHUD showSuccessWithStatus:msg];
}


+(void) setTimeout:(int)mSeconds callback:(void (^)())callback
{
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, mSeconds * NSEC_PER_MSEC);
	dispatch_after(popTime, dispatch_get_main_queue(), callback);
}

// 异步执行
+(void) async:(void (^)())func
{
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(queue, func);
}

+(void)setBarStyleLight
{
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

+(void)setBarStyleBlack
{
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

+ (BOOL)isiOSVersionEarlierThan8
{
	return [[[UIDevice currentDevice] systemVersion] floatValue] < 8.0;
}

/*
 //2014-01-06T18:29:48.802+08:00
 function goNowToDatetime(goNow) {
	if(!goNow) {
 return "";
	}
	// new Date();
	if(typeof goNow == 'object') {
 var date = new Date(goNow);
 return date.format("yyyy-MM-dd hh:mm:ss");
	}
	return goNow.substr(0, 10) + " " + goNow.substr(11, 8);
*/
+ (NSDate *)goDate:(NSString *)dateStr
{
	if ([Common isBlankString:dateStr]) {
		return [NSDate date];
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	
	NSString *ymd = [dateStr substringWithRange:NSMakeRange(0, 10)];
	NSString *hms = [dateStr substringWithRange:NSMakeRange(11, 8)];
	NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", ymd, hms]];
	return date;
}

// 返回2012-12-32 12:03:30
+ (NSString *)dateStr:(NSDate *)date
{
	if ([self isNullOrNil:date]) {
		date =[NSDate date];
	}
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	return [dateFormatter stringFromDate:date];
}

@end
