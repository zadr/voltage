#import "NSStringAdditions.h"

@implementation NSString (Additions)
+ (NSString *) stringWithData:(NSData *) data encoding:(NSStringEncoding) encoding {
	return [[NSString alloc] initWithData:data encoding:encoding];
}

- (NSUInteger) unsignedIntegerValue {
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;

#if __LP64__ || TARGET_OS_EMBEDDED || TARGET_OS_IPHONE || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
	return [[formatter numberFromString:self] unsignedLongValue];
#else
	return [[formatter numberFromString:self] unsignedIntegerValue];
#endif
}

- (BOOL) hasCaseInsensitivePrefix:(NSString *) prefix {
	return [self rangeOfString:prefix options:(NSCaseInsensitiveSearch | NSAnchoredSearch) range:NSMakeRange(0, self.length)].location != NSNotFound;
}
@end
