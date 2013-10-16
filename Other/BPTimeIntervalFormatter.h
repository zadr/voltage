#define MORE YES
#define LESS NO

@interface BPTimeIntervalFormatter : NSObject
+ (NSString *) moreOrLess:(BOOL) value;

+ (NSString *) interval:(NSTimeInterval) interval format:(NSString *) format; // Gives the singular or plural for a given time interval

+ (NSString *) abbreviatedFormattedInterval:(NSTimeInterval) interval; // hh:mm or dd:hh:mm. Needs to be localized

+ (NSString *) formattedInterval:(NSTimeInterval) interval; // 1 day, 2 hours and 3 minutes
+ (NSString *) formattedInterval:(NSTimeInterval) interval showEmptyTimePeriods:(BOOL) showEmptyTimePeriods; // 1 day and 2 minutes or 1 day, 0 hours and 2 minutes
@end
