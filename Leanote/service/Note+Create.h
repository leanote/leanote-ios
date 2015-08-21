//
//  Note+Create.h
//  Leanote

#import "Note.h"

@interface Note (Create)

+ (Note*)noteWithText:(NSString*)text inManagedObjectContext:(NSManagedObjectContext*)context;

@end
