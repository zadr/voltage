#import "NSObjectAdditions.h"

@implementation NSObject (Additions)
+ (void) performBlock:(void (^)(id object))block onObjectsInCollection:(id <NSFastEnumeration>) collection {
	[NSObject performBlock:block onObjectsInCollection:collection withPriority:DISPATCH_QUEUE_PRIORITY_DEFAULT];
}

+ (void) performBlock:(void (^)(id object))block onObjectsInCollection:(id <NSFastEnumeration>) collection withPriority:(dispatch_queue_priority_t) priority {
	dispatch_queue_t queue = dispatch_get_global_queue(priority, 0);

	for (id object in collection) {
		dispatch_async(queue, ^{
			block(object);
		});
	}
}
@end
