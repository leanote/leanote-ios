//
//  LeanoteTests.m
//  LeanoteTests
//
//  Created by life on 15/6/7.
//  Copyright (c) 2015年 Leanote. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "AFNetworkTool.h"

#import "Notebook.h"

#import "SyncService.h"
#import "ApiService.h"
#import "UserService.h"
#import "NoteService.h"

#import "Common.h"


@interface LeanoteTests : XCTestCase {
	NSManagedObjectModel *model;
	NSPersistentStoreCoordinator *coordinator;
	NSPersistentStore *store;
	NSManagedObjectContext *context;
}

@end

@implementation LeanoteTests

- (NSURL *)applicationDocumentsDirectory
{
	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)setUp {
	[super setUp];
}

- (void)tearDown {
	[super tearDown];
}

- (void)testSync {
	__block BOOL done = NO;
	
	/*
	[UserService login:@"a@a.com" pwd:@"abc123" host:nil success:^(id obj) {
		NSLog(@"%@", obj);
	} fail:^{
		NSLog(@"xx");
	}];
	
	User *user = [UserService init];
	NSLog(@"cur user %@", user.userId);
	*/
	
	/*
	Note *note = [NoteService getNoteByServerNoteId:@"5531235305fcd1357a000000"];
	[ApiService updateNote:note
				   success:^(id ret) {
					   
				   } fail:^(id ret){
					   
				   }];
	*/
	
//	[AFNetworkTool download:nil success:nil fail:nil];
	
	NSLog([Common newObjectId]);
	
//	[SyncService incrSync];
	
	XCTAssertTrue([self waitFor:&done timeout:100],
				  @"Timed out waiting for response asynch method completion");
//	XCTAssert(YES, @"Pass");
}

- (BOOL)waitFor:(BOOL *)flag timeout:(NSTimeInterval)timeoutSecs {
	NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutSecs];
	
	do {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
		if ([timeoutDate timeIntervalSinceNow] < 0.0) {
			break;
		}
	}
	while (!*flag);
	return *flag;
}

- (void)te_stExample {
	NSLog(@"xxxxx");
	
	dispatch_semaphore_t sema = dispatch_semaphore_create(0);
	
	NSString *url = @"http://localhost:9000/api/auth/login";
	NSDictionary *dict = @{@"email": @"admin", @"pwd": @"abc123"};
	
	// token = 5572864a99c37b5865000006;
	
	//	NSArray *array = @[dict, dict1];
	/*
	 [AFNetworkTool post:url parameters:dict success:^(id responseObject) {
		NSLog(@"请求 Ok");
		// NSLog(responseObject);
		NSLog(@"%@", responseObject);
		NSLog(@"%@", responseObject[@"Username"]);
		dispatch_semaphore_signal(sema);
	 } fail:^{
		NSLog(@"请求失败");
		dispatch_semaphore_signal(sema);
	 }];
	 */
	
	NSString *url2 = @"http://localhost:9000/api/notebook/getSyncNotebooks";
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"token": @"5572864a99c37b5865000006", @"usn": @"-1", @"maxEntry": @"3"}];
	// [NSMutableDictionary dictionaryWithObjectsAndKeys:@"admin",@"email",@"abc123",@"pwd",nil];
	[AFNetworkTool get:url2 params:params success:^(id json) {
		//		NSLog(@"%@", json);
		
		NSArray * objs = (NSArray *)json;
		NSLog(@"%lu", (unsigned long)[objs count]);
		
		// cast to notebook
		NSMutableArray *notebooks = [NSMutableArray array];
		
		NSString *test = @"xxxx";
		for(id eachObj in objs){
			//			Notebook *notebook = [[Notebook alloc] initWithEntity:nil insertIntoManagedObjectContext:nil];
//			NotebookInfo *notebookInfo = [[NotebookInfo alloc] init];
			NSLog(@"title: %@", eachObj[@"Title"]);
			
//			notebookInfo = (NotebookInfo *) eachObj;
			NSLog(@"%@", eachObj);
			
			NSNumber *aa = [NSNumber numberWithInt:11];
			NSLog(@"Seq type %@", [aa class]);
			NSLog(@"Seq type %@", [eachObj[@"Seq"] class]);
			NSLog(@"IsDeleted %@", [eachObj[@"IsDeleted"] boolValue] ? @"true" : @"false");
			
			NSLog(@"IsDeleted %@", eachObj[@"IsDeleted"] == NO ? @"false" : @"true");
			
			//			NSLog(notebookInfo.Title);
			
			// notebook = [[Notebook alloc] init];
			//			[notebook setServerNotebookId:test];
			//			notebook.serverNotebookId = @"xx"; // (NSString *)eachObj[@"NotebookId"];
			[notebooks addObject:eachObj];
		}
		
		int count = [notebooks count];
		NSLog(@"count %lu", (count));
		NSLog(@"count %lu", (count-1));
		NSNumber *maxUsn = [notebooks objectAtIndex:count-1][@"Usn"];
		
		NSLog(@"maxUsn %@", maxUsn);
		
		NSInteger maxEntryInt = 200;
		int i = 200;
		NSLog(@"max==Usn %@", maxEntryInt == i ? @"xx" : @"??");
		
		// This is an example of a functional test case.
		XCTAssert(YES, @"Pass");
		dispatch_semaphore_signal(sema);
	} fail:^(id ret){
		NSLog(@"请求失败");
		dispatch_semaphore_signal(sema);
	}];
	
	//	dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
	
	while (dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW)) {
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
	}
	
	// This is an example of a functional test case.
	// XCTAssert(YES, @"Pass");
}

@end
