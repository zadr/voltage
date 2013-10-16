#import "BPGraphLoggingController.h"
#import "BPPowerSourceInformation.h"

#include <dispatch/dispatch.h>

@implementation BPGraphLoggingController
#if GENERATE_GRAPHS
- (BOOL) plistFileCanBeCreatedOrExistsInAUsableStateAtURL:(NSURL *) fileURL {
	if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
		if (![[NSDictionary dictionary] writeToURL:fileURL atomically:YES])
			return [[BPLoggingController sharedInstance] log:[NSString stringWithFormat:NSLocalizedString(@"Unable to create file: %@", @"Unable to create file: %@ logging message"), fileURL.path] error:YES];
		else return [[BPLoggingController sharedInstance] log:[NSString stringWithFormat:NSLocalizedString(@"File: \"%@\" was created", @"File: \"%@\" was created logging message"), fileURL.path] error:NO];
	}

	return [[NSFileManager defaultManager] canReadAndWriteFileAtPath:fileURL.path];
}

#pragma mark -

- (BOOL) writeContentsOfDictionary:(NSDictionary *) dictionary toPlistAtURL:(NSURL *) plistURL forKey:(NSString *) key {
	if (![self plistFileCanBeCreatedOrExistsInAUsableStateAtURL:plistURL])
		return NO;

	NSMutableDictionary *plist = [[NSMutableArray arrayWithContentsOfURL:plistURL] mutableCopy];

	[plist setObject:dictionary forKey:key];
	return [plist writeToURL:plistURL atomically:YES];
}

- (BOOL) appendContentsOfPlistAtURL:(NSURL *) plistURL toPlistAtURL:(NSURL *) otherPlistURL {
	if (![self plistFileCanBeCreatedOrExistsInAUsableStateAtURL:plistURL])
		return NO;

	NSDictionary *plist = [NSDictionary dictionaryWithContentsOfURL:plistURL];

	return [self writeContentsOfDictionary:plist toPlistAtURL:otherPlistURL forKey:nil]; // todo: key, the hour, as a string
}

#pragma mark -

- (NSDateComponents *) dateComponentsForCurrentDay {
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	return [gregorian components:NSWeekdayCalendarUnit fromDate:[NSDate date]];
}

- (NSString *) shortDateString {
	NSDateComponents *dateComponents = [self dateComponentsForCurrentDay];
	return [NSString stringWithFormat:@"%@-%@-%@", dateComponents.year, dateComponents.month, dateComponents.day];
}

- (NSInteger) currentHour {
	return [self dateComponentsForCurrentDay].hour;
}

- (BOOL) firstDayOfMonth {
	return [self dateComponentsForCurrentDay].day == 1;
}

- (NSURL *) rootGraphFolderURL {
	static NSURL *rootURL = nil;
	
	if (rootURL)
		return rootURL;
	
	rootURL = [[[NSFileManager defaultManager] userLibraryURL] URLByAppendingPathComponent:@"/Application Support/Voltage/Graphs/"];

	return rootURL;
}

#pragma mark -

// Logs all information per-hour to a file
- (void) logHourlyPowerSourceInformationToURL:(NSURL *) pathURL {
	if (![[NSFileManager defaultManager] canReadAndWriteFileAtPath:pathURL.path])
		return;

	static NSMutableDictionary *hourlyInformation = nil;

	if (!hourlyInformation)
		hourlyInformation = [NSMutableDictionary dictionaryWithCapacity:9];

	BPPowerSourceInformation *powerSourceInformation = [BPPowerSourceInformation sharedInstance];

	if (!_updatedHourlyInformation) {
		[hourlyInformation setObject:[NSNumber numberWithInteger:powerSourceInformation.numberOfPowerSources] forKey:@"number-of-power-sources"];
		[hourlyInformation setObject:[NSNumber numberWithBool:(powerSourceInformation.isCharging || powerSourceInformation.isFinishingCharge)] forKey:@"is-charging"];
		[hourlyInformation setObject:[NSNumber numberWithBool:powerSourceInformation.isCharged] forKey:@"is-charged"];
		[hourlyInformation setObject:[NSNumber numberWithInteger:powerSourceInformation.powerSourceState] forKey:@"power-source-state"];
		[hourlyInformation setObject:[NSNumber numberWithInteger:powerSourceInformation.percentRemaining] forKey:@"percent-remaining"];
		[hourlyInformation setObject:[NSNumber numberWithInteger:powerSourceInformation.timeRemaining] forKey:@"time-remaining"];
		[hourlyInformation setObject:[NSNumber numberWithInteger:powerSourceInformation.currentCapacity] forKey:@"current-capacity"];
		[hourlyInformation setObject:[NSNumber numberWithInteger:powerSourceInformation.chargeCount] forKey:@"charge-count"];
		[hourlyInformation setObject:[NSNumber numberWithInteger:[self currentHour]] forKey:@"time"];
	}

	[self writeContentsOfDictionary:hourlyInformation toPlistAtURL:pathURL forKey:nil]; // TODO: key, the hour as a string
}

// Saves subset of the information to a file
// Subset includes: Maximum time remaining when on battery (if applicable)
//					Charge count
// 					Number of times cycled/drained per day? (subtract current charge count from the one 24 hours ago)
- (void) logDailyPowerSourceInformation {
	NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:BPPreviousDailyGraphUpdateDate];

	if (([NSDate timeIntervalSinceReferenceDate] - [date timeIntervalSinceReferenceDate] ) < 86400)
		return;

	NSInteger updateHour = [[NSUserDefaults standardUserDefaults] integerForKey:BPDailyUpdateHour];
	NSDateComponents *dateComponents = [self dateComponentsForCurrentDay];
	dateComponents.hour = updateHour; // check to see if this works with 24 hour time or not (or if it varies per locale?)

	// NSDateComponents to set up a date for the next update, then look to see if its the right time to update or not
	// If its not time to update, return

	NSMutableArray *itemsInFolder = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self rootGraphFolderURL].path error:nil] mutableCopy];
	NSInteger numberOfItemsInFolder = (itemsInFolder.signedCount - 1); // -1 to ignore the Archive/ folder
	NSInteger numberOfDaysInMonthlyGraph = [[NSUserDefaults standardUserDefaults] integerForKey:BPDaysInMonthlyGraph];
	for (NSInteger i = 0; numberOfItemsInFolder > numberOfDaysInMonthlyGraph && i < numberOfItemsInFolder; i++) {
		// TODO: Move head of itemsInFolder to /Archive
		[itemsInFolder removeObjectAtIndex:0];
		numberOfItemsInFolder--;
	}
}

- (void) logPowerSourceInformation {
	if ([BPPowerSourceInformation sharedInstance].updating) {
		[self performSelector:@selector(logPowerSourceInformation) withObject:nil afterDelay:15.0];
		return;
	}

	_updatedHourlyInformation = NO;

	[[NSProcessInfo processInfo] disableSuddenTermination];
	NSURL *sessionURL = [[self rootGraphFolderURL] URLByAppendingPathComponent:@"Session.plist"];

	[self logHourlyPowerSourceInformationToURL:sessionURL];

	_updatedHourlyInformation = YES;
	NSString *hourlyFileName = [NSString stringWithFormat:@"Daily/%@.plist", [self shortDateString]];
	NSURL *hourlyURL = [[self rootGraphFolderURL] URLByAppendingPathComponent:hourlyFileName];

	[self logHourlyPowerSourceInformationToURL:hourlyURL];
	[self logDailyPowerSourceInformation];
	[[NSProcessInfo processInfo] enableSuddenTermination];

	_updatedHourlyInformation = NO;
}

#pragma mark -

- (id) init {
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"BPGenerateGraphs"] || ![BPPowerSourceInformation sharedInstance].hardwareSerialNumber.length || [[NSUserDefaults standardUserDefaults] boolForKey:@"BPSingleBatterySystem"])
		return nil;

	if (!(self = [super init]))
		return nil;

	uint64_t interval = 3600000000000;
	uint64_t repeat = 60000000000;
	dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
	dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, interval, repeat); // Run once an hour and let it be delayed by up to a minute
	dispatch_source_set_event_handler(timer, ^{
		[self logPowerSourceInformation];
	});

	_updatedHourlyInformation = NO;

	return self;
}
#endif
@end
