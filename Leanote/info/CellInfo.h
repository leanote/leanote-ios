//
//  File.h
//  
//
//  Created by life on 15/6/14.
//
//

#import <Foundation/Foundation.h>
#import "Notebook.h"
#import "Tag.h"

@interface CellInfo : NSObject

@property (nonatomic, retain) NSString * idd;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * count;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSDate * updatedTime;
@property (nonatomic) BOOL isDirty;

+ (CellInfo *) getCellInfo:(Notebook *) notebook;
+ (CellInfo *) getCellInfoByTag:(Tag *) tag;

@end
