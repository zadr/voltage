@interface BPAudioMetadataReader : NSObject
+ (NSString *) artistForFileAtPath:(NSString *) path;
+ (NSString *) songForFileAtPath:(NSString *) path;
+ (NSString *) albumForFileAtPath:(NSString *) path;
+ (NSTimeInterval) durationForFileAtPath:(NSString *) path;
@end
