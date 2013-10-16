#import "NSFileManagerAdditions.h"

@implementation NSFileManager (Additions)
- (NSURL *) userApplicationSupportURL {
	return [self URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
}

- (NSString *) userApplicationSupportPath {
	return [self userApplicationSupportURL].path;
}

#pragma mark -

- (NSURL *) userLibraryURL {
	return [self URLForDirectory:NSLibraryDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
}

- (NSString *) userLibraryPath {
	return [self userLibraryURL].path;
}

- (BOOL) canReadAndWriteFileAtPath:(NSString *) path {
	if (![self fileExistsAtPath:path])
		return NO;

	if (![self isReadableFileAtPath:path])
		return NO;

	if (![self isWritableFileAtPath:path])
		return NO;

	return YES;
}
@end
