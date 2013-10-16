@interface NSArray (NSArrayAdditions)
- (id) safeObjectAtSignedIndex:(NSInteger) index;

@property (nonatomic, readonly) NSInteger signedCount;
@end

@interface NSMutableArray (NSMutableArrayAdditions)
- (void) safeRemoveObjectAtSignedIndex:(NSInteger) index;
- (void) safeReplaceObjectAtSignedIndex:(NSInteger) index withObject:(id) object;
@end
