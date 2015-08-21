//
//  Notebook.h
//  
//
//  Created by life on 15/6/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Notebook : NSManagedObject

@property (nonatomic, retain) NSDate * createdTime;
@property (nonatomic, retain) NSNumber * hasDeleted;
@property (nonatomic, retain) NSNumber * isBlog;
@property (nonatomic, retain) NSNumber * isDirty;
@property (nonatomic, retain) NSNumber * localIsNew;
@property (nonatomic, retain) NSString * notebookId;
@property (nonatomic, retain) NSNumber * noteCount;
@property (nonatomic, retain) NSString * parentNotebookId;
@property (nonatomic, retain) NSNumber * seq;
@property (nonatomic, retain) NSString * serverNotebookId;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * updatedTime;
@property (nonatomic, retain) NSString * urlTitle;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSNumber * usn;
@property (nonatomic, retain) NSNumber * localIsDelete;
@property (nonatomic, retain) NSNumber * status;

@end
