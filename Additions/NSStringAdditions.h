@interface NSString (Additions)
+ (NSString *) stringWithData:(NSData *) data encoding:(NSStringEncoding) encoding;

- (NSUInteger) unsignedIntegerValue;

- (BOOL) hasCaseInsensitivePrefix:(NSString *) prefix;
@end
