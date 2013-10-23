@class BPRule;
@class BPAlert;

@interface BPAlertRulesController : NSObject {
@private
	NSMutableArray *_allRules;
	NSMutableArray *_disabledRules;

	NSTimeInterval _wakeTime;

	NSTimeInterval _waitAfterWakeInterval;
	NSTimeInterval _ignoreStateChanges;
	NSTimeInterval _timeBetweenSameRule;
}

@property (nonatomic, readonly) NSArray *allRules;

+ (BPAlertRulesController *) sharedInstance;

- (void) checkIfRuleIsMatched;

- (BOOL) ruleCanFire:(BPRule *) rule;
- (void) checkAndActivateRule:(BPRule *) rule;

- (void) enableOrDisableAllRules;
- (void) enableOrDisableRuleAtIndex:(NSInteger) ruleIndex;

- (void) addRule:(BPRule *) rule;
- (void) removeRule:(BPRule *) rule;
- (void) removeRuleAtIndex:(NSInteger) ruleIndex;

- (void) replaceRuleAtIndex:(NSInteger) ruleIndex withRule:(BPRule *) rule;

- (NSInteger) numberOfRules;
- (BPRule *) ruleAtIndex:(NSInteger) ruleIndex;

- (NSInteger) indexOfRule:(NSString *) rule;
- (BOOL) containsRule:(BPRule *) rule;

- (void) saveRule:(BPRule *) rule;
- (void) saveAlert:(BPAlert *) alert forRule:(BPRule *) rule;
@end
