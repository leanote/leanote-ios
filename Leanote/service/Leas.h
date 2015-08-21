//
//  Leas.h
//  Leanote
//
//  Created by life on 15/7/30.
//  Copyright (c) 2015年 Leanote. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NotebookService.h"
#import "NoteService.h"
#import "TagService.h"

@interface Leas : NSObject

+(TagService *)tag;
+(NoteService *)note;
+(NotebookService *)notebook;
+(void)initService;
@end
