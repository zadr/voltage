#import "BPPowerSourceInformation.h"
#import "BPAlertGenerator.h"

#import "BPAlert.h"

@implementation BPAlertGenerator
+ (BPAlertGenerator *) sharedInstance {
	static BPAlertGenerator *sharedInstance = nil;
	static dispatch_once_t once_t;

	dispatch_once(&once_t, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (id) init {
	if (!(self = [super init]))
		return nil;

	return self;
}

#pragma mark -

- (BOOL) popupAlertWithInformation:(NSDictionary *) information {
	NSString *informativeText = information[@"informative-text"];
	NSString *messageText = information[@"message-text"];

	NSAlert *alert = [NSAlert alertWithMessageText:messageText defaultButton:NSLocalizedString(@"OK", @"OK button title") alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", informativeText];
	[alert runModal];

	return YES;
}

- (BOOL) audioAlertWithInformation:(NSDictionary *) information {
	NSString *audioPath = information[@"BPAudioPath"];

	if (![[NSFileManager defaultManager] fileExistsAtPath:audioPath])
		return NO;

	if (_sound && [_sound isPlaying])
		[_sound stop];

	_sound = [[NSSound alloc] initWithContentsOfFile:audioPath byReference:NO];

	if ([information[@"BPMaximumVolume"] boolValue])
		_sound.volume = 1.;

	if ([information[@"BPAudioRepeats"] boolValue])
		_sound.loops = YES;

	[_sound play];

	return YES;
}

- (BOOL) notificationAlertWithInformation:(NSDictionary *) information {
	// notification center

	return YES;
}

- (BOOL) scriptAlertWithInformation:(NSDictionary *) information {
	NSString *scriptPath = information[@"BPScriptPath"];

	if (![[NSFileManager defaultManager] fileExistsAtPath:scriptPath])
		return NO;

	[NSTask launchedTaskWithLaunchPath:scriptPath arguments:@[]];

	return YES;
}

- (BOOL) flashScreenAlertWithInformation:(NSDictionary *) information {
	return YES;
}
@end
