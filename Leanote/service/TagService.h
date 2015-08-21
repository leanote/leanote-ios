//
//  FileService.h
//  Leanote
//
//  Created by life on 15/6/14.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseService.h"
#import "Tag.h"

@interface TagService : BaseService
@property BOOL canceled; //  = NO; // 是否取消了, 原因是toggle user了

+(void) addTags:(NSArray *)arr
	  inContext:(NSManagedObjectContext *)inContext;

-(Tag *)addTag:(NSString *)title isForce:(BOOL)isForce usn:(NSNumber *)usn;
+ (Tag *) addTag:(NSString *)title isForce:(BOOL)isForce usn:(NSNumber *)usn
	   inContext:(NSManagedObjectContext *)inContext;

-(void)deleteTagForce:(NSString *)title;
- (void) deleteTag:(Tag *) tag
		   success:(void (^)())success
			  fail:(void (^)())fail;
+(void)deleteAllTags:(NSString *)userId;

+(void)recountTagNoteCountByTitlesStr:(NSString *)titlesStr
							inContext:(NSManagedObjectContext *)inContext;
+(void)recountTagNoteCountByTitles:(NSArray *)titles
						 inContext:(NSManagedObjectContext *)inContext;

- (void) pushByTagTitle:(NSString *)title
				success:(void (^)())success
				   fail:(void (^)())fail;

-(void)push:(Tag *)tag
	  success:(void (^)())success
		 fail:(void (^)())fail;
-(void)pushAll:(void (^)())success
		 fail:(void (^)(id))fail;
@end
