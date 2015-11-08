//
//  Leas.m
//  Leanote单例Service, AppDelegate.m实例化, BaseService.context 为其tmpContext
//
//  Created by life on 15/7/30.
//  Copyright (c) 2015年 Leanote. All rights reserved.
//

#import "Leas.h"
#import "BaseService.h"

@implementation Leas

static NotebookService *notebook;
static NoteService *note;
static TagService *tag;

+(NotebookService *)notebook
{
	return notebook;
}

+(NoteService *)note
{
	return note;
}

+(TagService *)tag
{
	return tag;
}

// 初始化service, 建立tmpContext
+(void)initService
{
//	NSManagedObjectContext *tmpContext = [BaseService getTmpContext];
	notebook = [[NotebookService alloc] init];
	note = [[NoteService alloc] init];
	tag = [[TagService alloc] init];
	
	// 使用主context, 与view建立直接关联
	notebook.tmpContext = BaseService.context;
	note.tmpContext = BaseService.context;
	tag.tmpContext = BaseService.context;
}

@end
