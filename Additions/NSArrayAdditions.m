#import "NSArrayAdditions.h"

static inline BOOL safeAtSignedIndex(NSInteger index, NSUInteger count) {
	return !(index < 0 || (NSUInteger)index > INT_MAX || (NSUInteger)index > count);
}

@implementation NSArray (NSArrayAdditions)
- (id) safeObjectAtSignedIndex:(NSInteger) index {
	return (safeAtSignedIndex(index, self.count)) ? self[(NSUInteger)index] : nil;
}

- (NSInteger) signedCount {
	NSUInteger count = self.count;
	return (count > INT_MAX) ? -1 : (NSInteger)count;
}
@end

#pragma mark -

@implementation NSMutableArray (NSMutableArrayAdditions)
- (void) safeRemoveObjectAtSignedIndex:(NSInteger) index {
	if (safeAtSignedIndex(index, self.count))
		[self removeObjectAtIndex:(NSUInteger)index];
}

- (void) safeReplaceObjectAtSignedIndex:(NSInteger) index withObject:(id) object {
	if (safeAtSignedIndex(index, self.count))
		self[(NSUInteger)index] = object;
}
@end
