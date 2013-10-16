@interface NSFileManager (Additions)
- (NSURL *) userApplicationSupportURL;
- (NSString *) userApplicationSupportPath;
- (NSURL *) userLibraryURL;
- (NSString *) userLibraryPath;

- (BOOL) canReadAndWriteFileAtPath:(NSString *) path;
@end
