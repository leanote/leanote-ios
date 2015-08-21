//
//  SyncService.h
//  Leanote
//
//  Created by life on 15/6/7.
//  Copyright (c) 2015年 life. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseService.h"

@interface SyncService : BaseService

+ (void) incrSync:(void (^)(BOOL))callback progress:(void (^)(int))progress;
+ (void) cancelSync;
@end
