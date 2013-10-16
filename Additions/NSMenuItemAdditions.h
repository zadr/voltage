@interface NSMenuItem (Additions)
@property (assign, getter=isEnabled) BOOL enabled;

+ (NSMenuItem *) menuItem;
+ (NSMenuItem *) menuItemWithTitle:(NSString *) title;
+ (NSMenuItem *) menuItemWithTitle:(NSString *) title action:(SEL) action;
+ (NSMenuItem *) menuItemWithTitle:(NSString *) title action:(SEL) action keyEquivalent:(NSString *) keyEquivalent;
@end
