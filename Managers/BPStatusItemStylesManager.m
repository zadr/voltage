#import "BPStatusItemStylesManager.h"

#import "BPStatusItemStyle.h"

@implementation BPStatusItemStylesManager
+ (BPStatusItemStylesManager *) sharedInstance {
	static BPStatusItemStylesManager *sharedInstance = nil;
	static dispatch_once_t once_t;

	dispatch_once(&once_t, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (void) loadExistingStyles {
	NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity:5];

	NSBundle *selfClassBundle = [NSBundle bundleForClass:[self class]];
	[paths addObject:[NSString stringWithFormat:@"%@/Styles", selfClassBundle.resourcePath]];
	if (![[NSBundle mainBundle] isEqual:selfClassBundle])
		[paths addObject:[NSString stringWithFormat:@"%@/Styles", [NSBundle mainBundle].resourcePath]];
	[paths addObject:[NSString stringWithFormat:@"%@/%@/Styles",[[NSFileManager defaultManager] userApplicationSupportPath], bundleName]];
	[paths addObject:[NSString stringWithFormat:@"/Library/Application Support/%@/Styles", bundleName]];
	[paths addObject:[NSString stringWithFormat:@"/Network/Library/Application Support/%@/Styles", bundleName]];

	[self addStatusItemStyle:[BPStatusItemStyle emptyStyle]];

	for (NSString *path in paths) {
		for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL]) {
			BPStatusItemStyle *style = [BPStatusItemStyle styleFromPath:[path stringByAppendingPathComponent:file]];

			if (style && ![self containsStatusItemStyle:style])
				[self addStatusItemStyle:style];
		}
	}
}

- (void) addStatusItemStyle:(BPStatusItemStyle *) style {
	if (![self containsStatusItemStyle:style])
		_statusItemStyles[style.identifier] = style;
}

- (void) removeStatusItemStyleWithIdentifier:(NSString *) identifier {
	[_statusItemStyles removeObjectForKey:identifier];
}

- (BOOL) containsStatusItemStyle:(BPStatusItemStyle *) style {
	return ((BPStatusItemStyle *)_statusItemStyles[style.identifier]).identifier.length > 0;
}

#pragma mark -

- (BPStatusItemStyle *) currentStatusItemStyle {
	NSString *currentStatusItemStyleIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:@"BPStatusItemStyle"];
	BPStatusItemStyle *currentStatusItemStyle = _statusItemStyles[currentStatusItemStyleIdentifier];

	if (currentStatusItemStyle.identifier.length)
		return currentStatusItemStyle;

	currentStatusItemStyle = _statusItemStyles[@"net.thisismyinter.voltageStyle.default"];
	if (currentStatusItemStyle.identifier.length)
		return currentStatusItemStyle;

	return nil;
}
@end
