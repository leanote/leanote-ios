//
//  Note+Create.m
//  Leanote

#import "Note+Create.h"

@implementation Note (Create)

+ (Note*)noteWithText:(NSString*)text inManagedObjectContext:(NSManagedObjectContext*)context
{
    Note *note = nil;
    note = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:context];
    
    note.title = text;
    note.createdTime = [NSDate date];
    
    NSError *saveError;
    [context save:&saveError];
    if(saveError)
    {
        NSLog(@"[%@ %@] Error: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [saveError localizedDescription]);
    }

    return note;
    
}

@end
