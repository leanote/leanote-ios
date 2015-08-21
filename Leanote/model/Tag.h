//
//  Tag.h
//  
//
//  Created by life on 15/6/16.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Tag : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * createdTime;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSDate * updatedTime;
@property (nonatomic, retain) NSNumber * usn;
@property (nonatomic, retain) NSNumber * isDirty;
@property (nonatomic, retain) NSNumber * noteCount;
@property (nonatomic, retain) NSNumber * localIsDelete;
@property (nonatomic, retain) NSNumber * status;

@end
