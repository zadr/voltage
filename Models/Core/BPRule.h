#import "BPModel.h"

@class BPAlert;

@interface BPRule : BPModel {
@private
	NSString *_ruleString; // The literal comparison, > 50 (for percent) or > 180 (minutes)
	NSMutableArray *_alerts; // All the alerts for this rule
	BOOL _canFire; // Can the rule be fired? (Or did we just fire and should we wait for the inverse?
	NSString *_timeFormat; // For BPPowerTimeRemainingRuleAlert, BPPowerTimeOnACAlert and BPPowerTimeOnBatteryAlert. Minutes, Hours or Days
	NSTimeInterval _lastFiredDate;
}
@property (nonatomic, copy) NSString *rule;
@property (nonatomic, strong) NSMutableArray *alerts;
@property (nonatomic) BOOL canFire;
@property (nonatomic, copy) NSString *timeFormat;
@property (nonatomic) NSTimeInterval lastFiredDate;

+ (id) ruleWithRule:(NSString *) rule type:(NSString *) type;
- (BOOL) isEqualToRule:(BPRule *) otherRule;

- (void) addAlert:(BPAlert *) alert;
- (void) modifyAlert:(BPAlert *) alert;
- (void) removeAlert:(BPAlert *) alert;
- (BOOL) containsAlert:(BPAlert *) alert;
- (BOOL) containsAlertType:(NSString *) alertType;
@end
