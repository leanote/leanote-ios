//
//  BaseService.m
//  Leanote
//
//  Created by life on 15/6/12.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "BaseService.h"

@implementation BaseService

static NSManagedObjectContext * context; // 当前视图context
static NSManagedObjectContext * writerContext; // 数据库context

// http://stackoverflow.com/questions/695980/how-do-i-declare-class-level-properties-in-objective-c
+ (NSManagedObjectContext *) context {
	@synchronized(self) {
		return context;
	}
}

+ (void)setContext:(NSManagedObjectContext *)val
{
	context = val;
}

+ (NSManagedObjectContext *) writerContext {
	@synchronized(self) {
		return writerContext;
	}
}

+ (void)setWriterContext:(NSManagedObjectContext *)val
{
	writerContext = val;
}

- (BOOL)saveContextAndPush
{
	return [self.class saveContextIn:self.tmpContext push:YES write:NO];
}
- (BOOL)saveContextAndWrite
{
	return [self.class saveContextIn:self.tmpContext push:YES write:YES];
}
- (BOOL)saveContext
{
	return [self.class saveContextIn:self.tmpContext push:NO write:NO];
}

+ (BOOL)saveContext
{
	return [self saveContextIn:context push:YES write:YES];
}

+ (BOOL)saveContextInOnly:(NSManagedObjectContext *)inContext
{
	return [self saveContextIn:inContext push:NO write:NO];
}

+ (BOOL)saveContextIn:(NSManagedObjectContext *)inContext
				 push:(BOOL)push
				 write:(BOOL)write
{
	// 如果是private context, 则
	if(inContext != context) {
		NSError * savingError = nil;
		BOOL ok = [inContext save:&savingError];
		
		// 如果不要push到mainContext上
		if(!push) {
			return ok;
		}
	}
	
	// 如果inContext === context, 那么肯定是push的, 即context save
	else {
		push = YES;
	}
	
	if(push || write) {
		[context performBlock:^{
			NSError * savingError = nil;
			if ([context save:&savingError]) {
				NSLog(@"successfully saved the context......");
			} else {
				NSLog(@"failed to save the context error = %@", savingError);
				
			}
			
			if(write) {
				// 异步写到磁盘上
				
				[writerContext performBlock:^{
					NSError * error;
					if(![writerContext save:&error]) {
						NSLog(@"Save Error: %@", [error localizedDescription]);
					}
					else {
						NSLog(@"successfully write the context..");
					}
				}];
			}
		}];
	}
	
	return YES;
}

// 新建一个
// 得到临时context, parent为context
+ (NSManagedObjectContext *)getTmpContext
{
	NSManagedObjectContext *temporaryContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	temporaryContext.parentContext = context;
	
	return temporaryContext;
}

@end
