typedef long dispatch_queue_priority_t;

@interface NSObject (Additions)
// Asynchronosly performs a given block using the object within a collection as its single parameter.
+ (void) performBlock:(void (^)(id object))block onObjectsInCollection:(id <NSFastEnumeration>) collection;
+ (void) performBlock:(void (^)(id object))block onObjectsInCollection:(id <NSFastEnumeration>) collection withPriority:(dispatch_queue_priority_t) priority;

// TODO: Asynchronously performs a given block using the object within a collection as its single parameter. Will end and stop all queues if a block returns YES
//+ (BOOL) performBlockingBlock:(BOOL (^)(id object))block onObjectsInCollection:(id <NSFastEnumeration>) collection;
//+ (BOOL) performBlockingBlock:(BOOL (^)(id object))block onObjectsInCollection:(id <NSFastEnumeration>) collection withPriority:(dispatch_queue_priority_t) priority;
@end
