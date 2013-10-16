#import "BPAlertRulesController.h"

#import "BPPowerSourceInformation.h"
#import "BPAlertGenerator.h"

#import "BPTimeIntervalFormatter.h"

#import "BPRule.h"
#import "BPAlert.h"

@interface BPAlertRulesController (Private)
- (void) powerSourceLost;
- (void) powerSourceFound;

- (void) didReceiveWakeNotification;

- (void) generateAlertsForRule:(BPRule *) rule;
@end

#pragma mark -

@implementation BPAlertRulesController
+ (BPAlertRulesController *) sharedInstance {
	static BPAlertRulesController *sharedInstance = nil;
	static dispatch_once_t once_t;

	dispatch_once(&once_t, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (id) init {
	if (!(self = [super init]))
		return nil;

	_allRules = [NSMutableArray array];
	_disabledRules = [NSMutableArray array];
	_wakeTime = [NSDate timeIntervalSinceReferenceDate];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkIfRuleIsMatched) name:BPPowerSourceUpdateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerSourceLost) name:BPPowerSourceLostNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerSourceFound) name:BPPowerSourceFoundNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveWakeNotification) name:NSWorkspaceDidWakeNotification object:nil];

	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -

- (void) didReceiveWakeNotification {
	_wakeTime = [NSDate timeIntervalSinceReferenceDate];
}

#pragma mark -

- (void) powerSourceLost {
	[NSObject performBlock:^(BPRule *rule) {
		if ([rule.type isEqualToString:BPPowerSourceLostRule])
			[self generateAlertsForRule:rule];
	} onObjectsInCollection:_allRules];
}

- (void) powerSourceFound {
	[NSObject performBlock:^(BPRule *rule) {
		if ([rule.type isEqualToString:BPPowerSourceFoundRule])
			[self generateAlertsForRule:rule];
	} onObjectsInCollection:_allRules];
}

#pragma mark -

- (NSInteger) currentStatusForType:(NSString *) type {
	if ([type isEqualToString:BPPowerTimeRemainingRule])
		return [BPPowerSourceInformation sharedInstance].timeRemaining;
	else if ([type isEqualToString:BPPowerPercentRule])
		return [BPPowerSourceInformation sharedInstance].percentRemaining;
	else if ([type isEqualToString:BPPowermAhRule])
		return [BPPowerSourceInformation sharedInstance].currentCapacity;
	else return -2; // The only two rules without a currentStatus (powerSourceLost and powerSourceFound) are triggered through notfications. -1 is used to indicate "still charging".
}

- (BOOL) ruleCanFire:(BPRule *) rule {
	NSInteger currentStatus = [self currentStatusForType:rule.type];

	if (currentStatus == -1 || currentStatus == -2)
		return NO;

	NSString *predicateString = [NSString stringWithFormat:@"%ld %@", currentStatus, rule.rule];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];

	return ![predicate evaluateWithObject:nil] && !rule.canFire;
}

- (void) checkAndActivateRule:(BPRule *) rule {
	rule.canFire = [self ruleCanFire:rule];
}

- (void) reactivateRules {
	[NSObject performBlock:^(BPRule *rule) {
		[self checkAndActivateRule:rule];
	} onObjectsInCollection:_allRules withPriority:DISPATCH_QUEUE_PRIORITY_HIGH];
}

- (void) generateAlertsForRule:(BPRule *) rule {
	[NSObject performBlock:^(BPAlert *alert) {
		NSString *logString = nil;
		NSString *ruleType = rule.type;
		NSString *alertType = alert.type;
		NSMutableDictionary *values = alert.values;

		NSString *notificationType = nil;
		NSString *informativeText = nil;
		NSInteger number = 0;
		NSString *form = nil;

		[values setObject:ruleType forKey:@"type"];

		if ([alertType isEqualToString:BPNSAlert] || [alertType isEqualToString:BPGrowlAlert]) {
			if ([ruleType isEqualToString:BPPowerTimeRemainingRule]) {
				number = [BPPowerSourceInformation sharedInstance].timeRemaining;

				if (number == -1)
					return;

				form = [BPTimeIntervalFormatter formattedInterval:(number * 60)];
				notificationType = @"Time Remaining";
				informativeText = [NSString stringWithFormat:NSLocalizedString(@"You now have %@ or less of power remaining on your battery", @"You now have %@ or less of power remaining on your battery informative text"), form];
			} else if ([ruleType isEqualToString:BPPowerPercentRule]) {
				number = [BPPowerSourceInformation sharedInstance].percentRemaining;
				notificationType = @"Percent Remaining";
				informativeText = [NSString stringWithFormat:NSLocalizedString(@"You now have %d or less percent power remaining in your battery", @"You now have %d or less percent power remaining in your battery informative text"), number];
			} else if ([ruleType isEqualToString:BPPowermAhRule]) {
				number = [BPPowerSourceInformation sharedInstance].currentCapacity;
				notificationType = @"mAh Remaining";
				informativeText = [NSString stringWithFormat:NSLocalizedString(@"You now have %d or less mAh remaining in your battery", @"You now have %d or less mAh remaining in your battery informative text"), number];
			} else if ([ruleType isEqualToString:BPPowerSourceLostRule]) {
				notificationType = @"Power Source Lost";
				informativeText = NSLocalizedString(@"A power source was removed from your Mac.", @"A power source was removed from your Mac informative text.");
			} else if ([ruleType isEqualToString:BPPowerSourceFoundRule]) {
				notificationType = @"Power Source Gained";
				informativeText = NSLocalizedString(@"A power source was added from your Mac.", @"A power source was added to your Mac informative text.");
			}

			[values setObject:rule.humanReadableFormat forKey:@"message-text"];
			[values setObject:informativeText forKey:@"informative-text"];

			if ([alertType isEqualToString:BPNSAlert]) {
				if ([[BPAlertGenerator sharedInstance] popupAlertWithInformation:values])
					logString = NSLocalizedString(@"NSAlert alert displayed", @"NSAlert alert type displayed logging message");
			} else {
				[values setObject:notificationType forKey:@"notification-type"];
			}
		} else if ([alertType isEqualToString:BPAudioAlert]) {
			if ([[BPAlertGenerator sharedInstance] audioAlertWithInformation:values])
				logString = NSLocalizedString(@"Audio alert sounded", @"Audio alert fired logging message");
			else logString = NSLocalizedString(@"Unable to sound audio alert", @"Unable to fire audio alert logging message");
		} else if ([alertType isEqualToString:BPScriptAlert]) {
			if ([[BPAlertGenerator sharedInstance] scriptAlertWithInformation:values])
				logString = NSLocalizedString(@"Script alert run", @"Script alert run logging message");
			else logString = NSLocalizedString(@"Unable to run script alert", @"Unable to run script alert logging message");
		}
	} onObjectsInCollection:rule.alerts withPriority:DISPATCH_QUEUE_PRIORITY_HIGH];
}

#pragma mark -

- (void) enableOrDisableAllRules {
	if (_disabledRules.count) { // There are already rules that are disabled. We reenable them instead

		for (BPRule *rule in _disabledRules)
			rule.enabled = YES;

		[_disabledRules removeAllObjects];
	} else { // Disable allactive rules
		BPRule *rule = nil;

		for (NSUInteger i = 0; i < _allRules.count; i++) {
			rule = [_allRules objectAtIndex:i];

			if (rule.enabled) {
				rule.enabled = NO;

				[_disabledRules addObject:rule];
			}
		}
	}
}

- (void) enableOrDisableRuleAtIndex:(NSInteger) ruleIndex {
	BPRule *rule = [_allRules safeObjectAtSignedIndex:ruleIndex];

	if (rule.enabled) {
		rule.enabled = NO;
		[_disabledRules removeObject:rule];
	} else {
		rule.enabled = YES;
		[_disabledRules addObject:rule];
	}
}

#pragma mark -

- (void) saveRulesAndAlerts:(NSArray *) newRulesAndAlerts {
	[newRulesAndAlerts writeToFile:[@"~/Library/Application Support/Voltage/Rules and Alerts.plist" stringByExpandingTildeInPath] atomically:YES];
}

- (NSMutableArray *) currentRulesAndAlerts {
	NSString *alertsAndRulesPath = [@"~/Library/Application Support/Voltage/Rules and Alerts.plist" stringByExpandingTildeInPath];
	NSString *applicationDataFolder = [@"~/Library/Application Support/Voltage/" stringByExpandingTildeInPath];
	NSMutableArray *alertsAndRules = nil; // Holds all the rules and alerts we have

	// Try and open everything to read
	if (![[NSFileManager defaultManager] fileExistsAtPath:applicationDataFolder]) {
		NSError *error = nil;

		[[NSFileManager defaultManager] createDirectoryAtPath:applicationDataFolder withIntermediateDirectories:NO attributes:nil error:&error];

		if (![[NSFileManager defaultManager] fileExistsAtPath:applicationDataFolder])
			return nil;
	}

	if ([[NSFileManager defaultManager] fileExistsAtPath:alertsAndRulesPath]) {
		if (![[NSFileManager defaultManager] isWritableFileAtPath:alertsAndRulesPath])
			return nil;

		alertsAndRules = [NSMutableArray arrayWithContentsOfFile:alertsAndRulesPath];
	}

	if (!alertsAndRules.count)
		return [NSMutableArray array];

	return alertsAndRules;
}

- (void) saveRule:(BPRule *) rule {
	NSMutableArray *currentRulesAndAlerts = [self currentRulesAndAlerts];
	if (!currentRulesAndAlerts)
		return;

	for (NSDictionary *dictionary in currentRulesAndAlerts) {
		NSMutableDictionary *ruleDictionary = [dictionary objectForKey:@"rule"];
		NSString *ruleString = [ruleDictionary objectForKey:@"rule-string"];
		NSString *ruleType = [ruleDictionary objectForKey:@"rule-type"];

		if ([ruleString isEqualToString:rule.rule] && [ruleType isEqualToString:rule.type])
			return;
	}

	NSDictionary *ruleDictionary = [NSDictionary  dictionaryWithObject:[NSDictionary dictionaryWithObjectsAndKeys:rule.type, @"rule-type", rule.rule, @"rule-string", [NSNumber numberWithBool:rule.enabled], @"rule-enabled", nil] forKey:@"rule"];
	[currentRulesAndAlerts addObject:ruleDictionary];

	[self saveRulesAndAlerts:currentRulesAndAlerts];
}

- (void) saveAlert:(BPAlert *) alert forRule:(BPRule *) rule {
	NSMutableArray *currentRulesAndAlerts = [self currentRulesAndAlerts];
	if (!currentRulesAndAlerts)
		return;

	BOOL changed = NO;
	NSMutableDictionary *dictionary = nil;
	NSUInteger i = 0;
	for (i = 0; i < currentRulesAndAlerts.count; i++) {
		dictionary = [[currentRulesAndAlerts objectAtIndex:i] mutableCopy];

		NSMutableDictionary *ruleDictionary = [[dictionary objectForKey:@"rule"] mutableCopy];
		NSString *ruleString = [ruleDictionary objectForKey:@"rule-string"];
		if (![ruleString isEqualToString:rule.type]) 
			continue;

		NSString *ruleType = [ruleDictionary objectForKey:@"rule-type"];
		if (![ruleType isEqualToString:rule.type])
			continue;

		changed = YES;

		NSMutableArray *alertsArray = [NSMutableArray array];
		for (BPAlert *newAlert in rule.alerts)
			[alertsArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:newAlert.values, @"alert-values", newAlert.type, @"alert-type", [NSNumber numberWithBool:newAlert.enabled], @"alert-enabled", nil]];
		[dictionary setObject:alertsArray forKey:@"alerts"];

		break;
	}

	if (changed) {
		[currentRulesAndAlerts replaceObjectAtIndex:i withObject:dictionary];

		[self saveRulesAndAlerts:currentRulesAndAlerts];
	}
}

#pragma mark -

// Disable the rule and keep track of it, if all the rules are disabled
- (void) addRule:(BPRule *) rule {
	if ([self containsRule:rule])
		return;

	if (_disabledRules.count) {
		rule.enabled = NO;
		[_disabledRules addObject:[NSNumber numberWithUnsignedInteger:(_allRules.count + 1)]];
	}

	[_allRules addObject:rule];

	[self saveRule:rule];

	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInteger:(_allRules.count - 1)], @"position", [NSNumber numberWithBool:YES], @"added", nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:BPRulesChangedNotification object:nil userInfo:userInfo];
}

// Remove it from the _disabledRules array and decrease everything after it by one, if necessary
- (void) removeRule:(BPRule *) rule {
	NSNumber *number = [NSNumber numberWithInteger:[self indexOfRule:rule.rule]];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:number, @"position", [NSNumber numberWithBool:NO], @"added", nil];

	[_allRules removeObject:rule];
	[_disabledRules removeObject:number]; // Rather then getting the count of the array AND iterating through it to remove the object, just try and remove it. If it fails, it just looks through once, rather than twice, nothing else.

	[[NSNotificationCenter defaultCenter] postNotificationName:BPRulesChangedNotification object:nil userInfo:userInfo];
}

// Remove it from the _disabledRules array and decrease everything after it by one, if necessary
- (void) removeRuleAtIndex:(NSInteger) ruleIndex {
	NSNumber *number = [NSNumber numberWithInteger:ruleIndex];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:number, @"position", [NSNumber numberWithBool:NO], @"added", nil];

	[_allRules safeRemoveObjectAtSignedIndex:ruleIndex];
	[_disabledRules removeObject:number];

	[[NSNotificationCenter defaultCenter] postNotificationName:BPRulesChangedNotification object:nil userInfo:userInfo];
}

- (void) replaceRuleAtIndex:(NSInteger) ruleIndex withRule:(BPRule *) rule {
	[_allRules safeReplaceObjectAtSignedIndex:ruleIndex withObject:rule];

	NSNumber *number = [NSNumber numberWithInteger:ruleIndex];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:number, @"position", [NSNumber numberWithBool:NO], @"added", nil];

	[[NSNotificationCenter defaultCenter] postNotificationName:BPRulesChangedNotification object:nil userInfo:userInfo];
}

#pragma mark -

- (NSInteger) numberOfRules {
	return _allRules.signedCount;
}

- (BPRule *) ruleAtIndex:(NSInteger) ruleIndex {
	return [_allRules safeObjectAtSignedIndex:ruleIndex];
}

#pragma mark -

- (void) checkIfRuleIsMatched {
	if ([BPPowerSourceInformation sharedInstance].onACPower)
		return;

	if (_waitAfterWakeInterval && (([NSDate timeIntervalSinceReferenceDate] - _wakeTime) < _waitAfterWakeInterval))
		return;

	if (_ignoreStateChanges > [BPPowerSourceInformation sharedInstance].timeSincePowerSourceChanged)
		return;

	[self reactivateRules];

	[NSObject performBlock:^(BPRule * rule) {
		NSTimeInterval timeIntervalSinceReferenceDate = [NSDate timeIntervalSinceReferenceDate];
		if (rule.lastFiredDate && ((timeIntervalSinceReferenceDate - rule.lastFiredDate) < _timeBetweenSameRule))
			return;

		NSInteger currentStatus = [self currentStatusForType:rule.type];

		if (!currentStatus || [BPPowerSourceInformation sharedInstance].updating) // 0 is sometimes returned when changing power states.
			return;
		else if (currentStatus == -2 || !rule.canFire) // -2 is power source gained/lost, shouldn't be called from here (won't create a valid predicate). Or if we just can't fire the rule, don't bother checking it.
			return;

		NSString *ruleString = rule.rule;

		NSString *predicateString = [NSString stringWithFormat:@"(%ld %@)", currentStatus, ruleString];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString];

		// If we can and should fire the rule, and the predicate (and not its inverse) is matched
		if (rule.canFire && [predicate evaluateWithObject:nil]) {
			[self generateAlertsForRule:rule];

			rule.lastFiredDate = timeIntervalSinceReferenceDate;
			rule.canFire = NO;
		}
	} onObjectsInCollection:_allRules withPriority:DISPATCH_QUEUE_PRIORITY_HIGH];
}

- (NSInteger) indexOfRule:(NSString *) rule {
	for (NSInteger i = 0; i < _allRules.signedCount; i++)
		if ([((BPRule *)[_allRules safeObjectAtSignedIndex:i]).rule isEqualToString:rule])
			return i;

	return -1;
}

- (BOOL) containsRule:(BPRule *) rule {
	for (BPRule *_rule in _allRules)
		if ([rule.rule isEqualToString:_rule.rule])
			return YES;

	return NO;
}
@end
