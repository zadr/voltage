@interface BPStatusItemStyle : NSObject {
@private
	NSString *__weak _identifier;
	NSString *__weak _displayName;
	BOOL _percentBasedStyle;

	NSString *__weak _path;
}
@property (weak, nonatomic, readonly) NSString *identifier;
@property (weak, nonatomic, readonly) NSString *displayName;
@property (nonatomic, readonly) BOOL percentBasedStyle;
@property (weak, nonatomic, readonly) NSMutableDictionary *imageDictionary;
@property (weak, nonatomic, readonly) NSString *path;

+ (BPStatusItemStyle *) styleFromPath:(NSString *) path;
+ (BPStatusItemStyle *) emptyStyle;

- (BOOL) isValid;

- (BOOL) isEqualToStyle:(BPStatusItemStyle *) style;

- (NSImage *) updatingImage;
- (NSImage *) nearestImageForNumber:(NSInteger) status;
@end
