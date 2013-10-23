#import "BPAlert.h"

// Hardcoded minimums, to prevent from quitting/halting everything at once
#define BPHardcodedMinimumHaltCPUUsage 15.
#define BPHardcodedMinimumQuitCPUUsage 15.

@implementation BPAlert
- (NSString *) description {
	return [NSString stringWithFormat:@"%@:%@", _type, _values];
}

#pragma mark -

- (void) _createAlertWithValues:(NSDictionary *) values {
	id object = nil;

	/*
	 type: BPNSAlert
	 Additional Keys:
		BPNSAlertAlwaysOnTop - BOOL, Should the alert window always be on top?
	*/
	if ([_type isEqualToString:BPNSAlert]) {
		_humanReadableFormat = NSLocalizedString(@"Pop up a window", @"Pop up a window human readable string");

		object = values[BPNSAlertAlwaysOnTop];
		if (object) {
			_values[BPNSAlertAlwaysOnTop] = object;

			_humanReadableFormat = NSLocalizedString(@"Pop up a window on top of all other windows", @"Pop up a window on top of all other windows. human readable string");
		}
	}

	/*
	 type: BPAudioAlert
	 Additional Keys:
		 BPAudioPath - NSString, File to play
		 BPAudioRepeats - BOOL, Should it repeat until stopped?
		 BPMaximumVolume — BOOL, Should it play at max volume regardless?
	*/
	else if ([_type isEqualToString:BPAudioAlert]) {
		object = values[BPAudioPath];
		if ([(NSString *)object length]) {
			if ([(NSString *)object isEqualToString:@"Beep"])
				_values[BPAudioPath] = @"Beep";
			else if ([[BPAlert systemAudioFiles] containsObject:object])
				_values[BPAudioPath] = [NSString stringWithFormat:@"/System/Library/Sounds/%@", object];
			else if ([[NSFileManager defaultManager] fileExistsAtPath:object])
				_values[BPAudioPath] = object;
			else _values[BPAudioPath] = @"/System/Library/Sounds/Ping.aiff";
		}

		_humanReadableFormat = [NSString stringWithFormat:NSLocalizedString(@"Play %@", @"Play %@ human readable string"), (NSString *)object];

		BOOL audioRepeats = NO;
		object = values[BPAudioRepeats];
		if (object) {
			audioRepeats = YES;
			_values[BPAudioRepeats] = object;

			_humanReadableFormat = [NSString stringWithFormat:NSLocalizedString(@"Play %@ on repeat", @"Play %@  on repeat. human readable string"), (NSString *)object];
		}

		object = values[BPMaximumVolume];
		if (object) {
			_values[BPMaximumVolume] = object;

			if (audioRepeats)
				_humanReadableFormat = [NSString stringWithFormat:NSLocalizedString(@"Play %@ on repeat, at maximum volume", @"Play %@  on repeat, at maximum volume. human readable string"), (NSString *)object];
			else _humanReadableFormat = [NSString stringWithFormat:NSLocalizedString(@"Play %@ at maximum volume", @"Play %@ at maximum volume human readable string"), (NSString *)object];
		}
	}

	/*
	 type: BPScriptAlert
	 Additional Keys:
		BPScriptPaths - NSString, Path to script to run

	*/
	else if ([_type isEqualToString:BPScriptAlert]) {
		object = values[BPScriptPath];
		if ([(NSString *)object length]) {
			if ([[NSFileManager defaultManager] fileExistsAtPath:object] && [[NSFileManager defaultManager] isExecutableFileAtPath:object])
				_values[BPScriptPath] = object;

			_humanReadableFormat = NSLocalizedString(@"Run %@", @"Run %@ human readable");
		}
	}
}

- (id) initWithAlert:(NSString *) alert values:(NSDictionary *) values {
	if (![[BPAlert singleAlertKeys] containsObject:alert] && ![[BPAlert multipleAlertKeys] containsObject:alert])
		return nil;

	if (!(self = [super init]))
		return nil;

	_type = alert;
	_values = [NSMutableDictionary dictionary];
	_enabled = YES;

	[self _createAlertWithValues:values];

	return self;
}

+ (id) alertWithAlert:(NSString *) alert values:(NSDictionary *) values {
	return [[self alloc] initWithAlert:alert values:values];
}

#pragma mark -

- (BOOL) isSingleInstance {
	if ([[BPAlert singleAlertKeys] containsObject:[self type]])
		return YES;
	return NO;
}

- (BOOL) isEqualToAlert:(BPAlert *) alert {
	return [_type isEqualToString:alert.type] && [_values isEqualToDictionary:alert.values];
}

+ (NSSet *) singleAlertKeys {
	static NSSet *singleAlertKeys = nil;

	if (!singleAlertKeys)
		singleAlertKeys = [NSSet setWithObjects:BPNSAlert, BPAudioAlert, nil];
	return singleAlertKeys;
}

+ (NSSet *) multipleAlertKeys {
	static NSSet *multipleAlertKeys = nil;

	if (!multipleAlertKeys)
		multipleAlertKeys = [NSSet setWithObjects:BPScriptAlert, nil];

	return multipleAlertKeys;
}

#pragma mark -

+ (NSSet *) systemAudioFiles {
	static NSSet *systemAudioFiles = nil;

	if (!systemAudioFiles)
		systemAudioFiles = [NSSet setWithObjects:@"Basso.aiff", @"Blow.aiff", @"Bottle.aiff", @"Frog.aiff", @"Funk.aiff", @"Glass.aiff", @"Hero.aiff", @"Morse.aiff", @"Ping.aiff", @"Pop.aiff", @"Purr.aiff", @"Sosumi.aiff", @"Submarine.aiff", @"Tink.aiff", nil];
	return systemAudioFiles;
}
@end
