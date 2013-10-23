#import "BPStatusBarController.h"
#import "BPAlertRulesController.h"
#import "BPApplicationDelegate.h"

#import "BPRulesCriterionWindowController.h"
#import "BPAlertsRulesWindowController.h"

#import "BPStatusItemStylesManager.h"

#import "BPTimeIntervalFormatter.h"
#import "BPPowerSourceInformation.h"
#import "BPAlertGenerator.h"

#import "BPRule.h"
#import "BPAlert.h"

#import "BPStatusItemStyle.h"

#import "BPMenu.h"

#define MaximumTitleLength 32
#define ManageRulesMenuItemTag 10000
#define PauseRulesMenuItemTag 10001
#define RemoveBuiltInMenuItemTag 10002
#define PreferencesMenuItemTag 10003
#define FeedbackMenuItemTag 10004
#define QuitMenuItemTag 10005
#define VoltageMenuItemTag 10006

#define MainMenuTag 10100
#define RuleMenuTag 10101
#define VoltageMenuTag 10102

#pragma mark -

@implementation BPStatusBarController
+ (BPStatusBarController *) sharedInstance {
	static id sharedInstance = nil;
	static dispatch_once_t once_t;

	dispatch_once(&once_t, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (id) init {
	if (!(self = [super init]))
		return nil;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createStatusBarMenuForDisplay) name:BPRulesChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createStatusBarMenuForDisplay) name:BPAlertChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createStatusBarMenuForDisplay) name:BPPowerSourceUpdateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatusBarItemForDisplay) name:BPPowerSourceUpdateNotification object:nil];

	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BPRulesChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BPAlertChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BPPowerSourceUpdateNotification object:nil];
}

#pragma mark -

- (BOOL) menubarContainsAppleDefaultBatteryStatusItemFromStatusBar {
	static NSString *batteryMenuPath = @"/System/Library/CoreServices/Menu Extras/Battery.menu";
	static NSURL *systemUIServerPreferencesURL = nil;
	if (!systemUIServerPreferencesURL)
		systemUIServerPreferencesURL = [NSURL fileURLWithPath:[[[NSFileManager defaultManager] userLibraryPath] stringByAppendingString:@"/Preferences/com.apple.systemuiserver.plist"]];

	NSMutableDictionary *systemUIServerPreferences = [NSDictionary dictionaryWithContentsOfURL:systemUIServerPreferencesURL];
	NSMutableArray *menuExtras = [systemUIServerPreferences[@"menuExtras"] mutableCopy];

	return [menuExtras containsObject:batteryMenuPath];
}

- (void) removeAppleDefaultBatteryStatusItemFromStatusBar {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:BPHasLaunchedBeforeKey])
		return;

	NSString *batteryMenuPath = @"/System/Library/CoreServices/Menu Extras/Battery.menu";
	NSString *menuExtrasString = @"menuExtras";
	NSURL *systemUIServerPreferencesURL = [NSURL fileURLWithPath:[[[NSFileManager defaultManager] userLibraryPath] stringByAppendingString:@"/Preferences/com.apple.systemuiserver.plist"]];

	NSMutableDictionary *systemUIServerPreferences = [[NSDictionary dictionaryWithContentsOfURL:systemUIServerPreferencesURL] mutableCopy];
	NSMutableArray *menuExtras = [systemUIServerPreferences[menuExtrasString] mutableCopy];

	if (![menuExtras containsObject:batteryMenuPath])
		return;

	NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Remove built-in battery menu item?", @"Remove built-in battery menu item message text") defaultButton:NSLocalizedString(@"Yes", @"Yes button title") alternateButton:NSLocalizedString(@"No", @"No button title") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Would you like to remove the default battery menubar item provided by Apple and replace it with Voltage?", @"Would you like to remove the default battery menubar item provided by Apple and replace it with Voltage? informative text")];

	if (![alert runModal])
		return;

	[menuExtras removeObject:batteryMenuPath];
	systemUIServerPreferences[menuExtrasString] = menuExtras;

	if ([systemUIServerPreferences writeToURL:systemUIServerPreferencesURL atomically:YES]) {
		NSTask *task = [[NSTask alloc] init];
		task.launchPath = @"/usr/bin/killall";
		task.arguments = @[@"SystemUIServer"];

		[task launch];

		[_statusItem.menu removeItem:[_statusItem.menu itemWithTag:RemoveBuiltInMenuItemTag]];
	}
}

#pragma mark -

// The position in the menu that a rule entry will be in
- (NSInteger) startOfRulesInMenu {
	NSInteger startOfRulesInMenu = ([[NSUserDefaults standardUserDefaults] boolForKey:BPLongFormatting]) ? 5 : 4;  // Manage Rules, Separator, Power Source, ((Percent Remaining, Time Remaining) or (Time and Percent))
	return ([BPPowerSourceInformation sharedInstance].batteryIsUnhealthy) ? startOfRulesInMenu + 1 : startOfRulesInMenu;
}

#pragma mark -

- (NSCellStateValue) stateForRule:(BPRule *) rule {
	if (!rule.enabled) {
		return NSOffState;
	}

	if ([[BPAlertRulesController sharedInstance] ruleCanFire:rule]) {
		return NSOnState;
	}

	return NSMixedState;
}

- (NSCellStateValue) stateForAlert:(BPAlert *) alert {
	if (alert.enabled)
		return NSOnState;
	return NSOffState;
}

- (NSMenu *) subMenuForRule:(BPRule *) rule {
	BPMenu *subMenu = [[BPMenu alloc] init];
	subMenu.tag = RuleMenuTag;
	subMenu.delegate = self;
	subMenu.autoenablesItems = NO;

	// Enable/Disable
	NSString *title = rule.enabled ? NSLocalizedString(@"Disable Rule", @"Disable Rule menu title") : NSLocalizedString(@"Enable Rule", @"Enable Rule menu title");
	NSMenuItem *changeRuleStateMenuItem = [NSMenuItem menuItemWithTitle:title action:@selector(changeRuleState)];
	changeRuleStateMenuItem.target = self;
	[subMenu addItem:changeRuleStateMenuItem];
	[subMenu addItem:[NSMenuItem separatorItem]];

	// Alerts
	NSInteger alertTag = 0;
	for (BPAlert *alert in rule.alerts) {
		NSMenuItem *subItem = [NSMenuItem menuItemWithTitle:alert.humanReadableFormat];
		subItem.tag = alertTag;

		subItem.state = [self stateForAlert:alert];
		subItem.target = self;

		alertTag++;

		[subMenu addItem:subItem];
	}

	[subMenu addItem:[NSMenuItem separatorItem]];

	// Modify
	NSMenuItem *modifyRuleMenuItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Modify Rule", @"Modify Rule menu item") action:@selector(modifyRule)];
	modifyRuleMenuItem.target = self;
	[subMenu addItem:modifyRuleMenuItem];

	return subMenu;
}

#pragma mark -

- (NSInteger) _percentForStatusBar {
	BPPowerSourceInformation *powerSourceInformation = [BPPowerSourceInformation sharedInstance];
	NSInteger percentRemaining = 0;
	
	if (powerSourceInformation.isCharging) {
		percentRemaining = 100 - powerSourceInformation.percentRemaining;
		
		if (!percentRemaining)
			percentRemaining = 100;
	} else percentRemaining = powerSourceInformation.percentRemaining;

	return percentRemaining;
}	

- (BOOL) statusBarTitleNeedsRefreshing {
	NSString *status = [[BPPowerSourceInformation sharedInstance] abbreviatedFormattedTimeRemaining];
	NSInteger percent = [self _percentForStatusBar];
	
	return percent && [status isEqualToString:@"0:00"];
}

- (NSString *) titleForStatusBarItem {
	BPPowerSourceInformation *powerSourceInformation = [BPPowerSourceInformation sharedInstance];
	if (powerSourceInformation.updating)
		return NSLocalizedString(@"Updating", @"Updating title");

	if (!powerSourceInformation.isCharging && !powerSourceInformation.timeRemaining && powerSourceInformation.powerSourceState == BPOnACPowerIdentifier)
		return NSLocalizedString(@"Charged", @"Charged title");

	BOOL showPercent = [[NSUserDefaults standardUserDefaults] boolForKey:BPShowPercentInStatusBar];

	if (showPercent && [[NSUserDefaults standardUserDefaults] boolForKey:BPShowTimeInStatusBar]) {
		if ([self statusBarTitleNeedsRefreshing])
			[self performSelector:@selector(updateStatusBarItemForDisplay) withObject:nil afterDelay:.25];
		return [NSString stringWithFormat:@"%@ (%ld%%)", [powerSourceInformation abbreviatedFormattedTimeRemaining], [self _percentForStatusBar]];
	} else if (showPercent)
		return [NSString stringWithFormat:@"%ld%%", [self _percentForStatusBar]];
	else return [powerSourceInformation abbreviatedFormattedTimeRemaining];
}

- (NSString *) titleForTimeAndPercentInStatusBarMenuForDisplay {
	if ([BPPowerSourceInformation sharedInstance].updating)
		return NSLocalizedString(@"Unknown time remaining…", @"Unknown time remaining…");

	if (![BPPowerSourceInformation sharedInstance].numberOfPowerSources)
		return NSLocalizedString(@"No power source found", @"No power source found menu title");

	NSInteger timeRemaining = [BPPowerSourceInformation sharedInstance].timeRemaining;
	NSInteger powerSourceState = [BPPowerSourceInformation sharedInstance].powerSourceState;
	BOOL charging = [BPPowerSourceInformation sharedInstance].isCharging;

	if (!charging && !timeRemaining) {
		NSString *title = nil;

		if (powerSourceState == BPOnACPowerIdentifier) {
			title = [[NSUserDefaults standardUserDefaults] stringForKey:BPFullyChargedTitle];

			if (!title.length)
				return NSLocalizedString(@"Not Charging", @"Not Charging menu title");
		} else if (powerSourceState == BPOnBatteryPowerIdentifier) {
			title = [[NSUserDefaults standardUserDefaults] stringForKey:BPFullyDrainedTitle];

			if (!title.length)
				return NSLocalizedString(@"Fully Drained", @"Fully Drained menu title");
		}

		if (title.length > MaximumTitleLength)
			title = [title stringByReplacingCharactersInRange:NSMakeRange(MaximumTitleLength - 1, (title.length - 1)) withString:@"…"];
		return title;
	}

	NSString *percentRemainingString = charging ? NSLocalizedString(@"Until Charged", @"Until Charged menu title") : NSLocalizedString(@"Remaining", @"Remaining menu title");
	return [NSString stringWithFormat:@"%@ %@", [self titleForStatusBarItem], percentRemainingString];
}

- (NSString *) titleForPowerSourceInStatusBarMenuForDisplay {
	if ([BPPowerSourceInformation sharedInstance].powerSourceState == BPOnACPowerIdentifier)
		return NSLocalizedString(@"Power Source: Plugged In", @"Power Source: Plugged In menu title");
	return NSLocalizedString(@"Power Source: Battery", @"Power Source: Battery menu title");
}

- (NSString *) titleForTimeInStatusBarMenuForDisplay {
	if ([BPPowerSourceInformation sharedInstance].updating)
		return NSLocalizedString(@"Calculating time remaining…", @"Calculating time remaining… menu title");

	if ([BPPowerSourceInformation sharedInstance].isCharging)
		return [NSString stringWithFormat:NSLocalizedString(@"%@ until charged", @"%@ until charged"), [BPTimeIntervalFormatter formattedInterval:([BPPowerSourceInformation sharedInstance].timeRemaining * 60)]];
	return [NSString stringWithFormat:NSLocalizedString(@"%@ remaining", @"%@ remaining"), [BPTimeIntervalFormatter formattedInterval:([BPPowerSourceInformation sharedInstance].timeRemaining * 60)]];
}

- (NSString *) titleForPercentInStatusBarMenuForDisplay {
	if ([BPPowerSourceInformation sharedInstance].updating)
		return NSLocalizedString(@"Calculating percentage remaining…", @"Calculating percentage remaining… menu title");

	if ([BPPowerSourceInformation sharedInstance].isCharging)
		return [NSString stringWithFormat:NSLocalizedString(@"%d percent until fully charged", @"%d uercent until fully charged menu title"), (100 - [BPPowerSourceInformation sharedInstance].percentRemaining)];
	return [NSString stringWithFormat:NSLocalizedString(@"%d percent remaining", @"%d percent remaining menu title"), [BPPowerSourceInformation sharedInstance].percentRemaining];
}

#pragma mark -

- (NSImage *) currentImageForStatusItem {
	return nil;

	BPStatusItemStyle *style = [[BPStatusItemStylesManager sharedInstance] currentStatusItemStyle];

	if ([style isEqualToStyle:[BPStatusItemStyle emptyStyle]])
		return nil;

	if ([BPPowerSourceInformation sharedInstance].updating)
		return [style updatingImage];

	NSInteger status = (style.percentBasedStyle) ? [BPPowerSourceInformation sharedInstance].percentRemaining : [BPPowerSourceInformation sharedInstance].timeRemaining;

	return [style nearestImageForNumber:status];
}

#pragma mark -

- (BOOL) createStatusBarMenuForDisplay {
	if (!_statusItem) {
		_statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

		if (!_statusItem)
			return NO;

		_statusItem.image = [self currentImageForStatusItem];
		_statusItem.title = [self titleForStatusBarItem];
		_statusItem.highlightMode = YES;
	}

	BPMenu *menu = [[BPMenu alloc] init];
	menu.delegate = self;
	menu.autoenablesItems = NO;
	menu.tag = MainMenuTag;

	// Time and Percent
	if ([[NSUserDefaults standardUserDefaults] boolForKey:BPLongFormatting]) {
		NSMenuItem *timeMenuItem = [NSMenuItem menuItemWithTitle:[self titleForTimeInStatusBarMenuForDisplay]];
		timeMenuItem.enabled = NO;
		[menu addItem:timeMenuItem];

		NSMenuItem *percentMenuItem = [NSMenuItem menuItemWithTitle:[self titleForPercentInStatusBarMenuForDisplay]];
		percentMenuItem.enabled = NO;
		[menu addItem:percentMenuItem];
	} else {
		NSMenuItem *timeAndPercentMenuItem = [NSMenuItem menuItemWithTitle:[self titleForTimeAndPercentInStatusBarMenuForDisplay]];
		timeAndPercentMenuItem.enabled = NO;
		timeAndPercentMenuItem.toolTip = [BPTimeIntervalFormatter formattedInterval:[BPPowerSourceInformation sharedInstance].timeRemaining];
		[menu addItem:timeAndPercentMenuItem];
	}

	// Power Source
	NSMenuItem *powerSourceMenuItem = [NSMenuItem menuItemWithTitle:[self titleForPowerSourceInStatusBarMenuForDisplay]];
	powerSourceMenuItem.enabled = NO;
	[menu addItem:powerSourceMenuItem];

	// Battery Health
	if ([BPPowerSourceInformation sharedInstance].batteryIsUnhealthy) {
		NSMenuItem *batteryHealthMenuItem = [NSMenuItem menuItem];
		batteryHealthMenuItem.title = [NSString stringWithFormat:NSLocalizedString(@"Battery Health: %@", @"Battery Health: %@ menu title"), [BPPowerSourceInformation sharedInstance].batteryHealthStatus];;
		batteryHealthMenuItem.enabled = NO;

		[menu addItem:batteryHealthMenuItem];
	}

	[menu addItem:[NSMenuItem separatorItem]];

	// Manage rules
	NSString *title = nil;
	if ([[BPAlertRulesController sharedInstance] numberOfRules])
		title = NSLocalizedString(@"Add or Remove a Rule", @"Add or Remove a Rule menu item");
	else title = NSLocalizedString(@"Add a Rule", @"Add a Rule menu item");
	NSMenuItem *manageRulesMenuItem = [NSMenuItem menuItemWithTitle:title action:@selector(manageRules)];
	manageRulesMenuItem.target = self;
	manageRulesMenuItem.tag = ManageRulesMenuItemTag;
	[menu addItem:manageRulesMenuItem];

	// Rules and alerts
	NSInteger ruleTag = 0;
	for (BPRule *rule in [[BPAlertRulesController sharedInstance] allRules]) {
		NSMenuItem *ruleItem = [NSMenuItem menuItemWithTitle:rule.humanReadableFormat];
		ruleItem.tag = ruleTag;
		ruleItem.state = [self stateForRule:rule];
		ruleItem.submenu = [self subMenuForRule:rule];
		[menu addItem:ruleItem];

		ruleTag++;
	}

	// Pause all rules
	if ([[BPAlertRulesController sharedInstance] numberOfRules]) {
		NSMenuItem *pauseMenuItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Pause All Rules", @"Pause All Rules menu title") action:@selector(enableOrDisableAllRules)];
		pauseMenuItem.tag = PauseRulesMenuItemTag;
		pauseMenuItem.target = self;
		[menu addItem:pauseMenuItem];
	}

	[menu addItem:[NSMenuItem separatorItem]];

	// Remove Apple's Battery menu item
	if ([self menubarContainsAppleDefaultBatteryStatusItemFromStatusBar]) {
		NSMenuItem *removeBuiltInMenuItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Remove Built-In Menu Item", @"Remove Built-In Menu Item") action:@selector(removeAppleDefaultBatteryStatusItemFromStatusBar)];
		removeBuiltInMenuItem.tag = RemoveBuiltInMenuItemTag;
		removeBuiltInMenuItem.target = self;
		[menu addItem:removeBuiltInMenuItem];
	}

	BPMenu *subMenu = [[BPMenu alloc] init];
	subMenu.tag = VoltageMenuTag;
	subMenu.delegate = self;
	subMenu.autoenablesItems = NO;
	
	// Preferences
	NSMenuItem *preferencesMenuItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Preferences", @"Preferences menu title") action:@selector(openPreferences) keyEquivalent:@","];
	preferencesMenuItem.tag = PreferencesMenuItemTag;
	preferencesMenuItem.target = self;
	preferencesMenuItem.keyEquivalentModifierMask = NSCommandKeyMask;
	[subMenu addItem:preferencesMenuItem];

	// Quit
	NSMenuItem *quitMenuItem = [NSMenuItem menuItemWithTitle:NSLocalizedString(@"Quit", @"Quit menu title") action:@selector(terminate:) keyEquivalent:@"q"];
	quitMenuItem.tag = QuitMenuItemTag;
	quitMenuItem.target = NSApp;
	quitMenuItem.keyEquivalentModifierMask = NSCommandKeyMask;
	[subMenu addItem:quitMenuItem];

	NSMenuItem *voltageMenuItem = [NSMenuItem menuItemWithTitle:[NSRunningApplication currentApplication].localizedName];
	voltageMenuItem.submenu = subMenu;
	voltageMenuItem.tag = VoltageMenuItemTag;
	[menu addItem:voltageMenuItem];

	_statusItem.menu = menu;

	return YES;
}

#pragma mark -

- (void) changeRuleState {
	[[BPAlertRulesController sharedInstance] enableOrDisableRuleAtIndex:_selectedItem];
}

- (void) enableOrDisableAllRules {
	_disabled ^= 1;

	[[BPAlertRulesController sharedInstance] enableOrDisableAllRules];

	[_statusItem.menu itemWithTag:PauseRulesMenuItemTag].title = _disabled ? NSLocalizedString(@"Resume All Rules", @"Resume All Rules menu title") : NSLocalizedString(@"Pause All Rules", @"Pause All Rules menu title");
}

- (void) openPreferences {
	if (_preferencesWindowController) {
		[_preferencesWindowController showWindow:nil];
		return;
	}

	_preferencesWindowController = [[NSWindowController alloc] initWithWindowNibName:@"Preferences" owner:self];

	if (!_preferencesWindowController)
		return;

	[_preferencesWindowController showWindow:nil];
}

- (void) modifyRule {
	BPRule *rule = [[BPAlertRulesController sharedInstance] ruleAtIndex:_selectedItem];	
	BPRulesCriterionWindowController *controller = [[BPRulesCriterionWindowController alloc] initWithRule:rule];
	[controller showWindow:nil];
}

- (void) manageRules {
	if (_rulesAndAlertsWindowController) {
		[_rulesAndAlertsWindowController showWindow:nil];
		return;
	}

	_rulesAndAlertsWindowController = [[BPAlertsRulesWindowController alloc] init];

	if (!_rulesAndAlertsWindowController)
		return;

	[_rulesAndAlertsWindowController window];

	[_rulesAndAlertsWindowController showWindow:nil];
	[_rulesAndAlertsWindowController.window makeKeyAndOrderFront:nil];
}

#pragma mark -

// This is required to be implemented for NSMenu delegates
- (NSInteger) numberOfItemsInMenu:(NSMenu *) menu {
	return menu.numberOfItems;
}

- (void) menuWillOpen:(NSMenu *) menu {
	[self createStatusBarMenuForDisplay];
}

- (void) menu:(NSMenu *) menu willHighlightItem:(NSMenuItem *) item {
	if (item.title.length && !menu.supermenu && item.tag < ManageRulesMenuItemTag)
		_selectedItem = item.tag;
}

- (void) updateStatusBarItemForDisplay {
	if ([self statusBarTitleNeedsRefreshing])
		[self performSelector:@selector(updateStatusBarItemForDisplay) withObject:nil afterDelay:.25];

	_statusItem.title = [self titleForStatusBarItem];
	_statusItem.image = [self currentImageForStatusItem];
}
@end
