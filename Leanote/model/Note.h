//
//  Note.h
//  
//
//  Created by life on 15/7/18.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Note : NSManagedObject

@property (nonatomic, retain) NSString * abstract;
@property (nonatomic, retain) NSString * attachs;
@property (nonatomic, retain) NSString * conflictedNoteId;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSDate * createdTime;
@property (nonatomic, retain) NSNumber * hasDeleted;
@property (nonatomic, retain) NSString * imgSrc;
@property (nonatomic, retain) NSNumber * isBlog;
@property (nonatomic, retain) NSNumber * isContentDirty;
@property (nonatomic, retain) NSNumber * isDirty;
@property (nonatomic, retain) NSNumber * isInitSync;
@property (nonatomic, retain) NSNumber * isMarkdown;
@property (nonatomic, retain) NSNumber * isTrash;
@property (nonatomic, retain) NSNumber * localIsDelete;
@property (nonatomic, retain) NSNumber * localIsNew;
@property (nonatomic, retain) NSString * notebookId;
@property (nonatomic, retain) NSString * noteId;
@property (nonatomic, retain) NSDate * publicTime;
@property (nonatomic, retain) NSString * serverNoteId;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * updatedTime;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSNumber * usn;

@end
