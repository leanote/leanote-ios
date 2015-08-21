//
//  File.h
//  
//
//  Created by life on 15/6/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface File : NSManagedObject

@property (nonatomic, retain) NSString * fileId;
@property (nonatomic, retain) NSString * serverFileId;
@property (nonatomic, retain) NSNumber * isAttach;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSNumber * size;
@property (nonatomic, retain) NSString * userId;

@end
