#import "BPTimeIntervalFormatter.h"

@implementation BPTimeIntervalFormatter
+ (NSString *) moreOrLess:(BOOL) less {
	if (less)
		return NSLocalizedString(@"Less", @"Less table value substitution string");
	return NSLocalizedString(@"More", @"More table value substitution string");
}

+ (NSString *) interval:(NSTimeInterval) interval format:(NSString *) format {
	if ([format isEqualToString:@"seconds"]) {
		if (interval == 1) return NSLocalizedString(@"second", @"second string");
		return NSLocalizedString(@"seconds", @"seconds string");
	} else if ([format isEqualToString:@"minutes"]) {
		if (interval == 1) return NSLocalizedString(@"minute", @"minute string");
		return NSLocalizedString(@"minutes", @"minutes string");
	} else if ([format isEqualToString:@"hours"]) {
		if (interval == 1) return NSLocalizedString(@"hour", @"hour string");
		return NSLocalizedString(@"hours", @"hours string");
	} else {
		if (interval == 1) return NSLocalizedString(@"day", @"day string");
		return NSLocalizedString(@"days", @"days string");
	}
}

#pragma mark -

+ (NSString *) intervalWithSeconds:(NSUInteger) interval {
	if (interval == 1)
		return NSLocalizedString(@"1 second", @"1 second string");
	return [NSString stringWithFormat:NSLocalizedString(@"%d seconds", @"%d seconds string"), interval];
}

+ (NSString *) intervalWithMinutes:(NSUInteger) interval {
	if (interval == 1)
		return NSLocalizedString(@"1 minute", @"1 minute string");
	return [NSString stringWithFormat:NSLocalizedString(@"%d minutes", @"%d minutes string"), interval];
}

+ (NSString *) intervalWithHours:(NSUInteger) interval {
	if (interval == 1)
		return NSLocalizedString(@"1 hour", @"1 hour string");
	return [NSString stringWithFormat:NSLocalizedString(@"%d hours", @"%d hours string"), interval];
}

+ (NSString *) intervalWithDays:(NSUInteger) interval {
	if (interval == 1)
		return NSLocalizedString(@"1 day", @"1 day string");
	return [NSString stringWithFormat:NSLocalizedString(@"%d days", @"%d days string"), interval];
}

#pragma mark -

+ (NSString *) intervalWithMinutes:(NSUInteger) minutes seconds:(NSUInteger) seconds {
	return [NSString stringWithFormat:NSLocalizedString(@"%@ and %@", @"x minute(s) and x second(s)"), [self intervalWithMinutes:minutes], [self intervalWithSeconds:seconds]];
}

+ (NSString *) intervalWithHours:(NSUInteger) hours seconds:(NSUInteger) seconds {
	return [NSString stringWithFormat:NSLocalizedString(@"%@ and %@", @"x hour(s) and x second(s)"), [self intervalWithHours:hours], [self intervalWithSeconds:seconds]];
}

+ (NSString *) intervalWithDays:(NSUInteger) days seconds:(NSUInteger) seconds {
	return [NSString stringWithFormat:NSLocalizedString(@"%@ and %@", @"x day(s) and x second(s)"), [self intervalWithDays:days], [self intervalWithSeconds:seconds]];
}

#pragma mark -

+ (NSString *) intervalWithHours:(NSUInteger) hours minutes:(NSUInteger) minutes seconds:(NSUInteger) seconds {
	return [NSString stringWithFormat:NSLocalizedString(@"%@, %@ and %@", @"%@ hour(s), %@ minute(s) and %@ second(s)"), [self intervalWithHours:hours], [self intervalWithMinutes:minutes], [self intervalWithSeconds:seconds]];
}

+ (NSString *) intervalWithDays:(NSUInteger) days hours:(NSUInteger) hours seconds:(NSUInteger) seconds {
	return [NSString stringWithFormat:NSLocalizedString(@"%@, %@ and %@", @"%@ hour(s), %@ minute(s) and %@ second(s)"), [self intervalWithDays:days], [self intervalWithHours:hours], [self intervalWithSeconds:seconds]];
}

+ (NSString *) intervalWithDays:(NSUInteger) days hours:(NSUInteger) hours minutes:(NSUInteger) minutes seconds:(NSUInteger) seconds {
	return [NSString stringWithFormat:NSLocalizedString(@"%@, %@, %@ and %@", @"%@ day(s), %@ hour(s), %@ minute(s), %@ second(s)"), [self intervalWithDays:days], [self intervalWithHours:hours], [self intervalWithMinutes:minutes], [self intervalWithSeconds:seconds]];
}

#pragma mark -

+ (NSString *) intervalWithHours:(NSUInteger) hours minutes:(NSUInteger) minutes {
	return [NSString stringWithFormat:NSLocalizedString(@"%@ and %@", @"x hour(s) and x minute(s)"), [self intervalWithHours:hours], [self intervalWithMinutes:minutes]];
}

+ (NSString *) intervalWithDays:(NSUInteger) days minutes:(NSUInteger) minutes {
	return [NSString stringWithFormat:NSLocalizedString(@"%@ and %@", @"x day(s) and x minute(s)"), [self intervalWithDays:days], [self intervalWithMinutes:minutes]];
}

+ (NSString *) intervalWithDays:(NSUInteger) days hours:(NSUInteger) hours {
	return [NSString stringWithFormat:NSLocalizedString(@"%@ and %@", @"x day(s) and x hour(s)"), [self intervalWithDays:days], [self intervalWithHours:hours]];
}

#pragma mark -

+ (NSString *) intervalWithDays:(NSUInteger) days hours:(NSUInteger) hours minutes:(NSUInteger) minutes {
	return [NSString stringWithFormat:NSLocalizedString(@"%@, %@ and %@", @"%@ day(s), %@ hour(s) and %@ minute(s)"), [self intervalWithDays:days], [self intervalWithHours:hours], [self intervalWithMinutes:minutes]];
}

#pragma mark -

+ (NSString *) abbreviatedFormattedInterval:(NSTimeInterval) interval {
	NSUInteger timeInterval = (NSUInteger)interval;

	NSUInteger days = timeInterval / 86400;
	timeInterval = (timeInterval - (days * 86400));

	NSUInteger hours = timeInterval / 3600;
	timeInterval = (timeInterval - (hours * 3600));

	NSUInteger minutes = timeInterval / 60;

	return days ? [NSString stringWithFormat:NSLocalizedString(@"%d:%.2d:%.2d", @"%d:%.2d:%.2d formatter"), days, hours, minutes] : [NSString stringWithFormat:NSLocalizedString(@"%d:%.2d", @"%d:%.2d formatter"), hours, minutes];
}

+ (NSString *) formattedInterval:(NSTimeInterval) interval showEmptyTimePeriods:(BOOL) showEmptyTimePeriods {
	NSUInteger timeInterval = (NSUInteger)interval;

	NSUInteger days = timeInterval / 86400;
	timeInterval = (timeInterval - (days * 86400));

	NSUInteger hours = timeInterval / 3600;
	timeInterval = (timeInterval - (hours * 3600));

	NSUInteger minutes = timeInterval / 60;
	timeInterval = (timeInterval - (minutes * 60));

	NSUInteger seconds = timeInterval;


	if (showEmptyTimePeriods) {
		if (days)
			return [self intervalWithDays:days hours:hours minutes:minutes seconds:seconds];
		if (hours)
			return [self intervalWithHours:hours minutes:minutes seconds:seconds];
		if (minutes)
			return [self intervalWithMinutes:minutes seconds:seconds];
		return [self intervalWithSeconds:seconds];
	}

	if (days) {
		if (hours) {
			if (minutes) {
				if (seconds)
					return [self intervalWithDays:days hours:hours minutes:minutes seconds:seconds];
				return [self intervalWithDays:days hours:hours seconds:seconds];
			}
			return [self intervalWithDays:days hours:hours];
		}

		if (minutes)
			return [self intervalWithDays:days minutes:minutes];
		if (seconds)
			return [self intervalWithDays:days seconds:seconds];
		return [self intervalWithDays:days];
	}

	if (hours) {
		if (minutes)
			return [self intervalWithHours:hours minutes:minutes];
		if (seconds)
			return [self intervalWithHours:hours seconds:seconds];
		return [self intervalWithHours:hours];
	}

	if (minutes) {
		if (seconds)
			return [self intervalWithMinutes:minutes seconds:seconds];
		return [self intervalWithMinutes:minutes];
	}

	return [self intervalWithSeconds:seconds];
}

+ (NSString *) formattedInterval:(NSTimeInterval) interval {
	return [self formattedInterval:interval showEmptyTimePeriods:NO];
}
@end
