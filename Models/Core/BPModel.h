@interface BPModel : NSObject {
@public
	BOOL _enabled;

	NSString *_type;
	NSString *__weak _humanReadableFormat;
}
@property BOOL enabled;
@property (nonatomic, copy) NSString *type;
@property (weak, nonatomic, readonly) NSString *humanReadableFormat;
@end
