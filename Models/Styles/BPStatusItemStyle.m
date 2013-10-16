#import "BPStatusItemStyle.h"

@implementation BPStatusItemStyle
- (id) _initStyleFromPath:(NSString *) path {
	if (!(self = [super init]))
		return nil;

	NSURL *url = [NSURL URLWithString:[path stringByAppendingString:@"/information.plist"]];
	NSDictionary *information = [NSDictionary dictionaryWithContentsOfURL:url];

	_path = path;
	_identifier = [information objectForKey:@"identifier"];
	_displayName = [information objectForKey:@"display-name"];

	if (![self isValid])
		return nil;

	NSNumber *percentBasedString = [information objectForKey:@"percent-based-string"];

	_percentBasedStyle = percentBasedString ? [percentBasedString boolValue] : YES;

	return self;
}

+ (BPStatusItemStyle *) styleFromPath:(NSString *) path {
	return [[BPStatusItemStyle alloc] _initStyleFromPath:path];
}

#pragma mark -

- (id) _initEmptyStyle {
	if (!(self = [super init]))
		return nil;

	_identifier = @"net.thisismyinter.voltageStyle.emptyStyle";
	_displayName = NSLocalizedString(@"No Status Icons", @"No Status Icons display name");

	return self;
}

+ (BPStatusItemStyle *) emptyStyle {
	return [[BPStatusItemStyle alloc] _initEmptyStyle];
}

#pragma mark -

// Intentionally not an ivar or static. Don't want to hold onto dictionaries for every style's images if the style isn't active.
- (NSMutableDictionary *) imageDictionary {
	NSDictionary *information = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/information.plist", _path]];
	NSMutableDictionary *_imageDictionary = [NSMutableDictionary dictionary];

	NSImage *image = nil;
	image.cacheMode = NSImageCacheNever;

	for (NSString *key in information) {
		if ([key isEqualToString:@"identifier"] || [key isEqualToString:@"display-name"] || [key isEqualToString:@"percent-based-string"])
			continue;

		image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", _path, key]];

		if (![image isValid])
			continue;

		[_imageDictionary setObject:[information objectForKey:key] forKey:key];
	}

	return _imageDictionary;
}

- (BOOL) isValid {
	return (_identifier.length && _displayName.length && self.imageDictionary.count);
}

- (BOOL) isEqualToStyle:(BPStatusItemStyle *) style {
	return [_identifier isEqualToString:style.identifier];
}

#pragma mark -

- (NSImage *) updatingImage {
	NSString *file = [NSString stringWithFormat:@"%@/%@", _path, [[self imageDictionary] objectForKey:@"updating"]];

	return [[NSImage alloc] initWithContentsOfFile:file];
}

- (NSImage *) nearestImageForNumber:(NSInteger) status {
	NSString *previousStatus = nil;
	NSDictionary *_imageDictionary = [self imageDictionary];
	
	for (NSString *number in _imageDictionary) {
		if ([number integerValue] >= status)
			previousStatus = number;
		else break;
	}

	NSString *file = [NSString stringWithFormat:@"%@/%@", _path, [_imageDictionary objectForKey:previousStatus]];

	return [[NSImage alloc] initWithContentsOfFile:file];
}
@end
