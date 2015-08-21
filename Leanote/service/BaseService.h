//
//  BaseService.h
//  Leanote
//
//  Created by life on 15/6/12.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaseService : NSObject

@property (strong, nonatomic) NSManagedObjectContext *tmpContext;


+ (NSManagedObjectContext *) context;
+ (NSManagedObjectContext *) writerContext;
+ (void) setContext:(NSManagedObjectContext *)context;
+ (void) setWriterContext:(NSManagedObjectContext *)context;
- (BOOL) saveContext;
- (BOOL) saveContextAndPush;
- (BOOL) saveContextAndWrite;
+ (BOOL) saveContext;
+ (BOOL) saveContextInOnly:(NSManagedObjectContext *)inContext;
+ (BOOL) saveContextIn:(NSManagedObjectContext *)inContext
				  push:(BOOL)push write:(BOOL)write;
+ (NSManagedObjectContext *)getTmpContext;
@end
