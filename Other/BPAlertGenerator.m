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
	NSString *informativeText = [information objectForKey:@"informative-text"];
	NSString *messageText = [information objectForKey:@"message-text"];

	NSAlert *alert = [NSAlert alertWithMessageText:messageText defaultButton:NSLocalizedString(@"OK", @"OK button title") alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", informativeText];
	[alert runModal];

	return YES;
}

- (BOOL) audioAlertWithInformation:(NSDictionary *) information {
	NSString *audioPath = [information objectForKey:@"BPAudioPath"];

	if (![[NSFileManager defaultManager] fileExistsAtPath:audioPath])
		return NO;

	if (_sound && [_sound isPlaying])
		[_sound stop];

	_sound = [[NSSound alloc] initWithContentsOfFile:audioPath byReference:NO];

	if ([[information objectForKey:@"BPMaximumVolume"] boolValue])
		_sound.volume = 1.;

	if ([[information objectForKey:@"BPAudioRepeats"] boolValue])
		_sound.loops = YES;

	[_sound play];

	return YES;
}

- (BOOL) notificationAlertWithInformation:(NSDictionary *) information {
	// notification center

	return YES;
}

- (BOOL) scriptAlertWithInformation:(NSDictionary *) information {
	NSString *scriptPath = [information objectForKey:@"BPScriptPath"];

	if (![[NSFileManager defaultManager] fileExistsAtPath:scriptPath])
		return NO;

	[NSTask launchedTaskWithLaunchPath:scriptPath arguments:nil];

	return YES;
}

- (BOOL) flashScreenAlertWithInformation:(NSDictionary *) information {
	return YES;
}
@end
