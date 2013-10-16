@class BPStatusItemStyle;

@interface BPStatusItemStylesManager : NSObject {
@private
	NSMutableDictionary *_statusItemStyles;
}
+ (BPStatusItemStylesManager *) sharedInstance;

- (void) loadExistingStyles;

- (void) addStatusItemStyle:(BPStatusItemStyle *) style;
- (void) removeStatusItemStyleWithIdentifier:(NSString *) identifier;

- (BOOL) containsStatusItemStyle:(BPStatusItemStyle *) style;

- (BPStatusItemStyle *) currentStatusItemStyle;
@end
