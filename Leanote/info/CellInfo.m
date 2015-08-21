//
//  File.m
//  
//
//  Created by life on 15/6/14.
//
//

#import "CellInfo.h"

@implementation CellInfo

static CellInfo *cellInfo = nil;

+ (CellInfo *) getCellInfo:(Notebook *) notebook
{
//	if (!cellInfo) {
//		cellInfo = [[CellInfo alloc] init];
//	}

	// 不能是单例, 不然文字宽度都是一样的!
	CellInfo *cellInfo = [[CellInfo alloc] init];
	
//	cellInfo.idd = notebook.notebookId;
	cellInfo.title = notebook.title;
	cellInfo.count = notebook.noteCount;
	cellInfo.isDirty = [notebook.isDirty boolValue];
	cellInfo.status = notebook.status;
	return cellInfo;
}

+ (CellInfo *) getCellInfoByTag:(Tag *) tag
{
	//	if (!cellInfo) {
	//		cellInfo = [[CellInfo alloc] init];
	//	}
	
	// 不能是单例, 不然文字宽度都是一样的!
	CellInfo *cellInfo = [[CellInfo alloc] init];
	
	cellInfo.title = tag.title;
	cellInfo.count = tag.noteCount;
	cellInfo.isDirty = [tag.isDirty boolValue];
	cellInfo.status = tag.status;
	
	return cellInfo;
}


@end
