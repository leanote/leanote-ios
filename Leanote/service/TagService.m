//
//  FileService.m
//  Leanote
//
//  Created by life on 15/6/14.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "TagService.h"
#import "Common.h"
#import "UserService.h"
#import "NoteService.h"
#import "ApiService.h"

@implementation TagService

+(void) addTags:(NSArray *)arr
	  inContext:(NSManagedObjectContext *)inContext
{
	if(!arr) {
		return;
	}
	for (NSString *title in arr) {
		[self addTag:title isForce:NO usn:nil inContext:inContext];
	}
}

+ (Tag *)getTagByTitle:(NSString *)title
			inContext:(NSManagedObjectContext *)inContext
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:inContext];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSPredicate * predicate = [NSPredicate predicateWithFormat:@"title = %@", title];
	[fetchRequest setPredicate:predicate];
	
	NSError * requestError = nil;
	NSArray * tags = [inContext executeFetchRequest:fetchRequest error:&requestError];
//	NSLog(@"getTagByTagTitle ret: %@", tags);
	if ([tags count] >= 1) {
		return tags[0];
	}
//	NSLog(@"getTagByTagTitle ret nil");
	return nil;
}

- (Tag *) addTag:(NSString *)title isForce:(BOOL)isForce usn:(NSNumber *)usn
{
	return [self.class addTag:title isForce:isForce usn:usn inContext:self.tmpContext];
}

- (Tag *) addTagForce:(id)obj
{
	NSString *title = obj[@"Tag"];
	NSNumber *usn = obj[@"Usn"];
	
	NSDate *createdTime = [Common goDate:obj[@"CreatedTime"]];
	NSDate *updatedTime = [Common goDate:obj[@"UpdatedTime"]];
	
	return [self.class addTag:title
				isForce:YES
			createdTime:createdTime
			updatedTime:updatedTime
					usn:usn
			  inContext:self.tmpContext];
	
}

// 新增或更新
+ (Tag *) addTag:(NSString *)title
		 isForce:(BOOL)isForce
			 usn:(NSNumber *)usn
	   inContext:(NSManagedObjectContext *)inContext
{
	return [self addTag:title
				isForce:isForce
			createdTime:[NSDate date]
			updatedTime:[NSDate date]
					usn:usn inContext:inContext];
}

// 新增或更新
+ (Tag *) addTag:(NSString *)title
		 isForce:(BOOL)isForce
	 createdTime:(NSDate *)createdTime
	 updatedTime:(NSDate *)updatedTime
			 usn:(NSNumber *)usn
	   inContext:(NSManagedObjectContext *)inContext
{
	// 空标题不让新增
	if(!title || [title isEqualToString:@""]) {
		return nil;
	}
	
	Tag *tag = [self.class getTagByTitle:title inContext:inContext];
	
	if(tag) {
		if(isForce) {
			tag.usn = usn;
			tag.updatedTime = tag.createdTime;
		}
		tag.noteCount = [self.class getTagCount:tag.title inContext:inContext];
		if(!isForce) {
			[self saveContext];
		}
		return tag;
	}
	
	// 新增
	tag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:inContext];
	tag.title = title;
	tag.createdTime = createdTime;
	tag.updatedTime = updatedTime;
	tag.isDirty = isForce ? M_NO : M_YES;
	tag.localIsDelete = M_NO;
	tag.userId = [UserService getCurUserId];

	if(isForce) {
		tag.usn = usn;
	}
	tag.noteCount = [self.class getTagCount:tag.title inContext:inContext];
	if(!isForce) {
		[self saveContext];
	}

	// 发送改变之
	/*
	[self push:tag success:^{
	} fail:^{
	}];
	*/
	return tag;
}

// 这两个方法供noteService调用
// 不save
+ (void)recountTagNoteCountByTitlesStr:(NSString *)titlesStr
							inContext:(NSManagedObjectContext *)inContext
{
	if(![Common isNull:titlesStr]) {
		NSArray *titles = [titlesStr componentsSeparatedByString:@","];
		for(NSString *title in titles) {
			[self.class recountTagNoteCount:title inContext:inContext];
		}
	}
	
	// 不要save, 调用者save
//	[self saveContextInOnly:inContext];
}
// 不save
+ (void)recountTagNoteCountByTitles:(NSArray *)titles
						 inContext:(NSManagedObjectContext *)inContext
{
	if(![Common isNull:titles]) {
		for(NSString *title in titles) {
			[self.class recountTagNoteCount:title inContext:inContext];
		}
	}
	
	[self saveContextInOnly:inContext];
}


// 这里一个耗时的活
+ (NSNumber *) getTagCount:(NSString *)title
				inContext:(NSManagedObjectContext *)inContext
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription * entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:inContext];
	[fetchRequest setEntity:entity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"tags CONTAINS[cd] %@", title];
	[fetchRequest setPredicate:predicate];
	
	NSError *err;
	NSUInteger count = [inContext countForFetchRequest:fetchRequest error:&err];
	
	if(count == NSNotFound) {
		count = 0;
	}
	return [NSNumber numberWithInteger:count];;
}


// 这里一个耗时的活
+ (void)recountTagNoteCount:(NSString *)title
				 inContext:(NSManagedObjectContext *)inContext
{
	if([Common isBlankString:title]) {
		return;
	}
	Tag *tag = [self getTagByTitle:title inContext:inContext];
	if(!tag) {
		return;
	}
	tag.noteCount = [self getTagCount:title inContext:inContext];
}

// sync删除
// 删除tag, 也要调用noteService删除之
- (void) deleteTagForce:(NSString *)title
{
	Tag *tag = [self.class getTagByTitle:title inContext:self.tmpContext];
	
	if(tag) {
		[self.tmpContext deleteObject:tag];
		[self saveContext];
		
		// 笔记中有该tag的都要删除掉
		[NoteService deleteTag:title inContext:self.tmpContext];
	}
}

// 本地删除
- (void) deleteTag:(Tag *) tag
		   success:(void (^)())successCb
			  fail:(void (^)())failCb
{
	void (^success)(void) = ^(void) {
		successCb();
		[self saveContextAndWrite];
	};
	void (^fail)(id) = ^(id ret) {
		failCb(ret);
		[self saveContextAndWrite];
	};
	
	tag.localIsDelete = M_YES;
	tag.isDirty = M_YES;
	[NoteService deleteTag:tag.title inContext:self.tmpContext];
	if([self saveContext]) {
		// 发送改变之
		[self push:tag success:success fail:fail];
		 return;
	}
}

// 删除所有
+(void)deleteAllTags:(NSString *)userId
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:self.context];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSString *q = [NSString stringWithFormat:@"userId='%@'", userId];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:q];
	[fetchRequest setPredicate:predicate];
	
	NSError *requestError = nil;
	NSArray *tags = [self.context executeFetchRequest:fetchRequest error:&requestError];
	
	for(Note *tag in tags) {
		[self.context deleteObject:tag];
	}
	
	[self saveContext];
}

- (NSArray *)getDirtyTags
{
	NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tag" inManagedObjectContext:self.tmpContext];
	[fetchRequest setEntity:entity];
	
	// 设置查询条件
	NSString *userId = [UserService getCurUserId];
	NSString *q = [NSString stringWithFormat:@"isDirty == YES AND userId='%@'", userId];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:q];
	[fetchRequest setPredicate:predicate];
	
	NSError *requestError = nil;
	NSArray *tags = [self.tmpContext executeFetchRequest:fetchRequest error:&requestError];
	return tags;
}

# pragma 发送改变

- (void) pushAll:(void (^)())successCb
		 fail:(void (^)(id))failCb
{
	void (^success)(void) = ^(void) {
		[self saveContextAndWrite];
		successCb();
	};
	void (^fail)(id) = ^(id ret) {
		[self saveContextAndWrite];
		failCb(ret);
	};
	
	NSArray *tags = [self getDirtyTags];
	if(!tags || [tags count] == 0) {
		success();
		return;
	}
	unsigned long total = [tags count];
	__block unsigned long  i = 0;
	for(Tag *tag in tags) {
		if(self.canceled) return;
		[self push:tag success:^{
			i++;
			if(i == total) {
				success();
			}
			
		} fail:^(id ret) {
			i++;
			if(i == total) {
				success();
			}
		} noOp:^{
			i++;
			if(i == total) {
				success();
			}
		}];
	}
}

- (void) pushByTagTitle:(NSString *)title
	  success:(void (^)())successCb
		 fail:(void (^)())failCb
{
	void (^success)(void) = ^(void) {
		[self saveContextAndWrite];
		successCb();
	};
	void (^fail)() = ^(void) {
		[self saveContextAndWrite];
		failCb();
	};
	
	Tag *tag = [self.class getTagByTitle:title inContext:self.tmpContext ];
	if (!tag) {
		if(fail) fail();
	}
	else {
		[self push:tag success:success fail:fail];
	}
}

- (void) push:(Tag *)tag
	  success:(void (^)())success
		 fail:(void (^)())fail
{
	[self push:tag success:success fail:fail noOp:nil];
}

- (void) push:(Tag *)tag
	  success:(void (^)())success
		 fail:(void (^)())fail
		 noOp:(void (^)())noOp
{
	if([tag.localIsDelete boolValue]) {
		[self pushDeleteTag:tag success:success fail:fail];
		return;
	}
	
	[self pushAddTag:tag success:success fail:fail];
}

- (void) pushAddTag:(Tag *)tag
				success:(void (^)())success
				fail:(void (^)())fail
{
	tag.status = [NSNumber numberWithInt:-1];
	
	[ApiService addTag:tag.title success:^(id ret) {
		tag.status = [NSNumber numberWithInt:1];
		
		NSNumber *usn = ret[@"Usn"];
		tag.isDirty = M_NO;
		tag.usn = usn;
		[self saveContext];
		NSLog(@"pushAddTag %@", ret);
		
		if(success) {
			success();
		}
	} fail:^(id ret){
		tag.status = [NSNumber numberWithInt:2];
		
		if(fail) {
			// 是否冲突
			fail();
		}
	}];
}

- (void) pushDeleteTag:(Tag *)tag
				success:(void (^)())success
				   fail:(void (^)())fail
{
	[ApiService deleteTag:tag success:^(id ret) {
		if(success) {
			[self.tmpContext deleteObject:tag];
			[self saveContext];
			success();
		}
	} fail:^(id ret){
		if(fail) {
			// 是否冲突
			fail();
		}
	}];
}


@end
