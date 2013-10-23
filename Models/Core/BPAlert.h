#import "BPModel.h"

@interface BPAlert : BPModel {
@private
	NSMutableDictionary *_values; // The values for the alert, what sound file to play, etc
}

@property (nonatomic, strong) NSMutableDictionary *values;

+ (id) alertWithAlert:(NSString *) alert values:(NSDictionary *) values;

- (BOOL) isSingleInstance;

- (BOOL) isEqualToAlert:(BPAlert *) alert;

+ (NSSet *) singleAlertKeys;
+ (NSSet *) multipleAlertKeys;

+ (NSSet *) systemAudioFiles;
@end
