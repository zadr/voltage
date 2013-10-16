#import "BPAlert.h"
#import "BPRule.h"

#import "BPAlertRulesController.h"

#import "BPTimeIntervalFormatter.h"

@implementation BPRule
@synthesize rule = _ruleString;

#pragma mark -

- (id) initWithRule:(NSString *) rule type:(NSString *) ruleType {
	if (!(self = [super init]))
		return nil;

	// If we don't have a rule or have an unknown type, don't make a rule that won't be run, and don't allow a rule for 0 minutes remaining
	if (!rule.length || ([ruleType isEqualToString:BPPowerTimeRemainingRule] && ![[rule substringFromIndex:2] integerValue]))
		return nil;

	_ruleString = rule;
	_type = ruleType;
	_alerts = [NSMutableArray array];
	_canFire = NO;
	_enabled = YES;
	_timeFormat = @"minutes"; // TODO: hours, days, seconds

	if ([_type isEqualToString:BPPowerTimeRemainingRule]) {
		NSString *quantifier = ([_ruleString characterAtIndex:0] == '>') ? [BPTimeIntervalFormatter moreOrLess:LESS] : [BPTimeIntervalFormatter moreOrLess:MORE];
		NSUInteger ruleValue = [[_ruleString substringFromIndex:2] unsignedIntegerValue];
		_humanReadableFormat = [NSString stringWithFormat:NSLocalizedString(@"%@ than %d %@ remaining", @"%@ than %@ %d remaining title text"), quantifier, [[_ruleString substringFromIndex:2] integerValue], [BPTimeIntervalFormatter interval:ruleValue format:_timeFormat]];
	} else if ([_type isEqualToString:BPPowerPercentRule]) {
		NSString *quantifier = ([_ruleString characterAtIndex:0] == '>') ? [BPTimeIntervalFormatter moreOrLess:LESS] : [BPTimeIntervalFormatter moreOrLess:MORE];
		_humanReadableFormat = [NSString stringWithFormat:NSLocalizedString(@"%@ than %d percent remaining", @"%@ than %d percent remaining title text"), quantifier, [[_ruleString substringFromIndex:2] integerValue]];
	} else if ([_type isEqualToString:BPPowermAhRule]) {
		NSString *quantifier = ([_ruleString characterAtIndex:0] == '>') ? [BPTimeIntervalFormatter moreOrLess:LESS] : [BPTimeIntervalFormatter moreOrLess:MORE];
		_humanReadableFormat = [NSString stringWithFormat:NSLocalizedString(@"%@ than %d mAh remaining", @"%@ than %d mAh remaining title text"), quantifier, [[_ruleString substringFromIndex:2] integerValue]];
	} else if ([_type isEqualToString:BPPowerSourceLostRule])
		_humanReadableFormat = NSLocalizedString(@"Power source lost", @"Power source lost title text");
	else if ([_type isEqualToString:BPPowerSourceFoundRule])
		_humanReadableFormat = NSLocalizedString(@"Power source found", @"Power source gained title text");

	return self;
}

+ (id) ruleWithRule:(NSString *) rule type:(NSString *) type {
	return [[self alloc] initWithRule:rule type:type];
}

#pragma mark -

- (NSString *) description {
	return [NSString stringWithFormat:@"%@:%@:%@", _type, _ruleString, _alerts];
}

#pragma mark -

- (BOOL) isEqualToRule:(BPRule *) otherRule {
	if (!otherRule || [_ruleString isEqualToString:otherRule.rule])
		return NO;
	return YES;
}

- (BOOL) hasAlertType:(NSString *) type {
	for (BPAlert *alert in _alerts)
		if ([alert.type isEqualToString:type])
			return YES;
	return NO;
}

#pragma mark -

- (void) _addAlert:(BPAlert *) alert withLogging:(BOOL) logging {
	if (!alert) return;

	if ([self containsAlert:alert])
		return;

	[_alerts addObject:alert];
}

- (void) addAlert:(BPAlert *) alert {
	[self _addAlert:alert withLogging:YES];
}

#pragma mark -

- (void) _removeAlert:(BPAlert *) alert withLogging:(BOOL) logging {
	if (!alert) return;

	[_alerts removeObject:alert];
}

- (void) removeAlert:(BPAlert *) alert {
	[self _removeAlert:alert withLogging:YES];
}

#pragma mark -

- (void) modifyAlert:(BPAlert *) alert {
	if (!alert) return;

	[self _removeAlert:alert withLogging:NO];
	[self _addAlert:alert withLogging:NO];
}

- (BOOL) containsAlert:(BPAlert *) alert {
	for (BPAlert *_alert in _alerts)
		if ([_alert isEqualToAlert:alert])
			return YES;
	return NO;
}

- (BOOL) containsAlertType:(NSString *) alertType {
	for (BPAlert *_alert in _alerts) {
		if ([alertType isEqualToString:BPNSAlert] && [_alert.type isEqualToString:BPNSAlert])
			return YES;
		if ([alertType isEqualToString:BPAudioAlert] && [_alert.type isEqualToString:BPAudioAlert])
			return YES;
		if ([alertType isEqualToString:BPGrowlAlert] && [_alert.type isEqualToString:BPGrowlAlert])
			return YES;
	}

	return NO;
}
@end
