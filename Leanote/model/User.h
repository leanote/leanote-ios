//
//  User.h
//  
//
//  Created by life on 15/6/18.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * host;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSDate * lastSyncTime;

@property (nonatomic, retain) NSNumber * lastSyncUsn;
// 以下3个主要是为了第一次全量同步时用
@property (nonatomic, retain) NSNumber * lastSyncNotebookUsn;
@property (nonatomic, retain) NSNumber * lastSyncNoteUsn;
@property (nonatomic, retain) NSNumber * lastSyncTagUsn;

@property (nonatomic, retain) NSString * logo;
@property (nonatomic, retain) NSString * pwd;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSDate * createdTime;
@property (nonatomic, retain) NSDate * updatedTime;

@end
