#import "NSMenuItemAdditions.h"

@implementation NSMenuItem (Additions)
@dynamic enabled;

+ (NSMenuItem *) menuItem {
	return [self menuItemWithTitle:[NSString string] action:NULL keyEquivalent:[NSString string]];
}

+ (NSMenuItem *) menuItemWithTitle:(NSString *) title {
	return [self menuItemWithTitle:title action:NULL keyEquivalent:[NSString string]];
}

+ (NSMenuItem *) menuItemWithTitle:(NSString *) title action:(SEL) action {
	return [self menuItemWithTitle:title action:action keyEquivalent:[NSString string]];
}

+ (NSMenuItem *) menuItemWithTitle:(NSString *) title action:(SEL) action keyEquivalent:(NSString *) keyEquivalent {
	return [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:keyEquivalent];
}
@end
