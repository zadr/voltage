#import "BPRulesCriterionWindowController.h"

#import "BPAlertRulesController.h"

#import "BPRule.h"

#define TimeRemainingIsTag 1
#define PercentRemainingIsTag 2
#define RunningOnBatteryForTag 3
#define APowerSourceWasLostTag 4
#define APowerSourceWasFoundTag 5
#define IsGreaterThanTag 6
#define IsEqualToTag 8
#define IsLessThanTag 9
#define MinutesTag 12
#define HoursTag 13
#define DaysTag 14

#pragma mark -

@interface BPRulesCriterionWindowController (Private)
- (NSString *) ruleForSelection;
- (NSString *) selectedType;
@end

@implementation BPRulesCriterionWindowController
- (id) initWithRule:(BPRule *) rule {
	if (!(self = [super initWithWindowNibName:@"singleRule" owner:self]))
		return nil;

	_initialRule = rule;

	return self;
}

#pragma mark -

- (void) windowDidLoad {
	[super windowDidLoad];

	self.window.delegate = self;

	if (!_initialRule.rule.length)
		return;

	NSString *type = _initialRule.type;
	if ([type isEqualToString:BPPowerTimeRemainingRule])
		[_ruleTypePopUp selectItemWithTag:TimeRemainingIsTag];
	else if ([type isEqualToString:BPPowerPercentRule])
		[_ruleTypePopUp selectItemWithTag:PercentRemainingIsTag];
	else if ([type isEqualToString:BPPowerSourceLostRule])
		[_ruleTypePopUp selectItemWithTag:APowerSourceWasLostTag];
	else if ([type isEqualToString:BPPowerSourceFoundRule])
		[_ruleTypePopUp selectItemWithTag:APowerSourceWasFoundTag];
	
	unichar operator = [_initialRule.rule characterAtIndex:0];
	if (operator == '>') {
		[_ruleValuePopUp selectItemWithTag:IsGreaterThanTag];
		_ruleValueTextFieldCell.placeholderString = [_initialRule.rule substringFromIndex:2]; // skip "> "
	} else if (operator == '<') {
		[_ruleValuePopUp selectItemWithTag:IsLessThanTag];
		_ruleValueTextFieldCell.placeholderString = [_initialRule.rule substringFromIndex:2]; // skip "< "
	} else {
		[_ruleValuePopUp selectItemWithTag:IsEqualToTag];
		_ruleValueTextFieldCell.placeholderString = [_initialRule.rule substringFromIndex:3]; // skip "== "
	}

	NSString *timeFormat = _initialRule.timeFormat;
	if ([timeFormat isEqualToString:@"minutes"])
		[_timeIntervalPopUp selectItemWithTag:MinutesTag];
	else if ([timeFormat isEqualToString:@"hours"])
		[_timeIntervalPopUp selectItemWithTag:HoursTag];
	else [_timeIntervalPopUp selectItemWithTag:DaysTag];

	[super windowDidLoad];
}

- (BOOL) windowShouldClose:(id) sender {
	BOOL close = YES;
	BPRule *rule = [BPRule ruleWithRule:[self ruleForSelection] type:[self selectedType]];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:BPWarnBeforeCancelingModification] && _ruleValueTextFieldCell.title.length && ![rule isEqualToRule:_initialRule]) {
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Rule changed", @"Rule changed message text.") defaultButton:NSLocalizedString(@"Close window", @"Save modification button title") alternateButton:NSLocalizedString(@"Don't close window", @"Don't save changes button title") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The rule changed, are you sure you want to cancel editing it? ", @"The rule changed, are you sure you want to cancel editing it? informative text")];
		alert.alertStyle = NSInformationalAlertStyle;
		alert.showsSuppressionButton = YES;

		((NSCell *)alert.suppressionButton.cell).controlSize = NSSmallControlSize;
		((NSCell *)alert.suppressionButton.cell).font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];

		if (![alert runModal])
			close = NO;

		if (alert.suppressionButton.state == NSOnState)
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:BPWarnBeforeCancelingModification];
	}

	return close;
}

#pragma mark -

- (IBAction) updateWindowForSelection:(id) sender {
	NSInteger selectedRuleTag = _ruleTypePopUp.selectedItem.tag;

	[_timeIntervalPopUp itemAtIndex:0].title = NSLocalizedString(@"minutes", @"minutes menu item");
	[_timeIntervalPopUp itemAtIndex:1].title = NSLocalizedString(@"hours", @"hours menu item");
	[_timeIntervalPopUp itemAtIndex:2].title = NSLocalizedString(@"days", @"days menu item");

	_informationLabel.title = @"";

	if (selectedRuleTag == PercentRemainingIsTag)
		_timeIntervalPopUp.enabled = NO;
	else {
		_timeIntervalPopUp.enabled = YES;

		BOOL powerSourceLost = (selectedRuleTag == APowerSourceWasLostTag);

		if (powerSourceLost || selectedRuleTag == APowerSourceWasFoundTag) {
			[_timeIntervalPopUp itemAtIndex:0].title = NSLocalizedString(@"minutes ago", @"minutes ago menu item");
			[_timeIntervalPopUp itemAtIndex:1].title = NSLocalizedString(@"hours ago", @"hours ago menu item");
			[_timeIntervalPopUp itemAtIndex:2].title = NSLocalizedString(@"days ago", @"days ago menu item");

			if (powerSourceLost)
				_informationLabel.title = NSLocalizedString(@"Use \"… exactly 0 …\" to alert when unplugged", @"Use \"… exactly 0 …\" to alert when unplugged information label");
			else _informationLabel.title = NSLocalizedString(@"Use \"… exactly 0 …\" to alert when plugged in", @"Use \"… exactly 0 …\" to alert when plugged in information label");
		}
	}
}

#pragma mark -

- (NSString *) ruleForSelection {
	NSString *ruleValue = _ruleValueTextFieldCell.title;

	if (!ruleValue.length)
		ruleValue = _ruleValueTextFieldCell.placeholderString;

	NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
	numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;

	if (!ruleValue.length || ![numberFormatter numberFromString:ruleValue])
		return nil;

	NSString *sign = nil;

	if (_ruleTypePopUp.tag == IsGreaterThanTag)
		sign = @">";
	else if (_ruleTypePopUp.tag == IsEqualToTag)
		sign = @"==";
	else sign = @"<";

	return [NSString stringWithFormat:@"%@ %@", sign, ruleValue];
}

- (NSString *) selectedType {
	NSInteger selectedRuleTag = _ruleTypePopUp.selectedItem.tag;

	if (selectedRuleTag == TimeRemainingIsTag)
		return BPPowerTimeRemainingRule;
	else if (selectedRuleTag == PercentRemainingIsTag)
		return BPPowerPercentRule;
	else if (selectedRuleTag == APowerSourceWasLostTag)
		return BPPowerSourceLostRule;
	else return BPPowerSourceFoundRule;
}

#pragma mark -

- (IBAction) createOrModifyRule:(id) sender {
	NSString *ruleValue = [self ruleForSelection];

	if (!ruleValue.length) {
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unable to make a rule", @"Unable to make a rule message text.") defaultButton:NSLocalizedString(@"Ok", @"Ok button title") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Voltage is unable to make a rule from the given input. Try entering a new value in the text box!", @"Voltage is unable to make a rule from the given input. Try entering a new value in the text box! informative text")];
		alert.alertStyle = NSInformationalAlertStyle;

		[alert runModal];

		return;
	}

	NSString *selectedRuleType = [self selectedType];

	if (_initialRule.rule) {
		NSInteger ruleIndex = [[BPAlertRulesController sharedInstance] indexOfRule:_initialRule.rule];
		BPRule *rule = [[BPAlertRulesController sharedInstance] ruleAtIndex:ruleIndex];

		rule.rule = ruleValue;
		rule.type = selectedRuleType;

		[[BPAlertRulesController sharedInstance] replaceRuleAtIndex:ruleIndex withRule:rule];
	} else {
		BPRule *rule = [BPRule ruleWithRule:ruleValue type:selectedRuleType];

		[[BPAlertRulesController sharedInstance] addRule:rule];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:BPRulesChangedNotification object:nil];

	[self close];
}
@end
