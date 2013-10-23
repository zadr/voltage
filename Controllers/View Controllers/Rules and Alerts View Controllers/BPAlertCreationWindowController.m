/*
	NSAlert:
		1. Checkbox: Always on top?
	Audio Alert:
		1. Path of audio file to play
		2. Checkbox: Should the sound repeat?
		3. Checkbox: Should the sound play at max volume?
	Growl:
		1. Checkbox: Stay on screen until clicked?
	Script:
		1. Path of script to run
 
	Halt Processes:
		1. TableView: List of applications to halt.
		2. TableView: List of applications to never halt.
		3. Textfield: Minimum CPU to be using before halting application
	Unhalt Processes:
		No values. Fully internal. It just gets created and attached to a rule.
	Quit Processes:
		1. TableView: List of applications to quit.
		2. TableView: List of applications to never quit.
		3. Textfield: Minimum CPU to be using before halting application
	Open Process:
		1. TableView: List of applications to open.
 */

#import "BPAlertCreationWindowController.h"
#import "BPAlertRulesController.h"

#import "BPRule.h"
#import "BPAlert.h"

#define PopupAlertTag 10
#define AudioAlertTag 11
#define GrowlAlertTag 12
#define ScriptAlertTag 13

#pragma mark -

@implementation BPAlertCreationWindowController
- (id) initWithAlert:(BPAlert *) alert forRule:(BPRule *) rule {
	if (!(self = [super initWithWindowNibName:@"alerts" owner:self]))
		return nil;

	_initialAlert = alert;
	_attachedRule = rule;

	return self;
}

#pragma mark -

- (NSString *) alertTypeForSelection {
	NSInteger selectedAlertTag = _alertTypePopUp.selectedItem.tag;

	if (selectedAlertTag == PopupAlertTag)
		return BPNSAlert;
	else if (selectedAlertTag == AudioAlertTag)
		return BPAudioAlert;
	else if (selectedAlertTag == GrowlAlertTag)
		return BPGrowlAlert;
	else if (selectedAlertTag == ScriptAlertTag)
		return BPScriptAlert;
	return nil;
}

- (NSDictionary *) valuesForSelection {
	NSInteger selectedAlertTag = _alertTypePopUp.selectedItem.tag;
	NSMutableDictionary *values = [NSMutableDictionary dictionary];

	if (selectedAlertTag == PopupAlertTag) {
		values[BPNSAlertAlwaysOnTop] = @(_firstButton.state);
	} else if (selectedAlertTag == AudioAlertTag) {
		values[BPAudioRepeats] = @(_firstButton.state);
		values[BPMaximumVolume] = @(_secondButton.state);

		if (!_filePath.length)
			return nil;

		values[BPAudioPath] = _filePath;
	} else if (selectedAlertTag == GrowlAlertTag) {
		values[BPGrowlIsSticky] = @(_firstButton.state);
	} else if (selectedAlertTag == ScriptAlertTag) {
		if (!_filePath.length)
			return nil;

		values[BPScriptPath] = _filePath;
	}

	return values;
}

#pragma mark -

- (void) windowDidLoad {
	[self updateWindowForSelection:nil];

	[super windowDidLoad];

	_okayButton.target = self;
	_okayButton.action = @selector(createOrModifyAlert:);

	_cancelButton.target = self;
	_cancelButton.action = @selector(close);

	self.window.delegate = self;

	NSString *type = [self alertTypeForSelection];

	if ([type isEqualToString:BPNSAlert]) {
		[_alertTypePopUp selectItemWithTag:PopupAlertTag];
	} else if ([type isEqualToString:BPAudioAlert]) {
		[_alertTypePopUp selectItemWithTag:AudioAlertTag];
	} else if ([type isEqualToString:BPGrowlAlert]) {
		[_alertTypePopUp selectItemWithTag:GrowlAlertTag];
	} else if ([type isEqualToString:BPScriptAlert]) {
		[_alertTypePopUp selectItemWithTag:ScriptAlertTag];
	} 
}

- (IBAction) updateWindowForSelection:(id) sender {
	NSString *type = [self alertTypeForSelection];
	NSWindow *window = self.window;

	if ([type isEqualToString:BPNSAlert]) {
		[window setFrame:NSMakeRect(window.frame.origin.x, window.frame.origin.y, window.frame.size.width, 154) display:YES animate:YES];

		_firstButton.title = NSLocalizedString(@"On top of all windows on screen", @"On top of all windows on screen checkbox");
		_firstButton.frame = NSMakeRect(_firstButton.frame.origin.x, 56, _firstButton.frame.size.width, _firstButton.frame.size.height);
		_firstButton.hidden = NO;
		_secondButton.hidden = YES;

		_pathField.hidden = YES;
		_pathSelectButton.hidden = YES;
		_leftTableView.hidden = YES;
		_rightTableView.hidden = YES;
	} else if ([type isEqualToString:BPAudioAlert]) { // NSOpenPanel
		[window setFrame:NSMakeRect(window.frame.origin.x, window.frame.origin.y, 392, 190) display:YES animate:YES];

		_firstButton.title = NSLocalizedString(@"Play on repeat", @"Play on repeat checkbox");
		_firstButton.frame = NSMakeRect(_firstButton.frame.origin.x, 102, _firstButton.frame.size.width, _firstButton.frame.size.height);
		_firstButton.hidden = NO;

		_secondButton.title = NSLocalizedString(@"Play at maximum volume", @"Play at maximum volume checkbox");
		_secondButton.frame = NSMakeRect(_secondButton.frame.origin.x, 82, _secondButton.frame.size.width, _secondButton.frame.size.height);
		_secondButton.hidden = NO;

		_pathCell.placeholderString = [[_filePath lastPathComponent] substringToIndex:[_filePath lastPathComponent].length - ([_filePath pathExtension].length + 1)];
		_pathField.frame = NSMakeRect(20, 53, 247, 22);
		_pathField.hidden = NO;

		_pathSelectButton.frame = NSMakeRect(269, 47, 96, 32);
		_pathSelectButton.target = self;
		_pathSelectButton.action = @selector(selectFile);
		_pathSelectButton.hidden = NO;

		_leftTableView.hidden = YES;
		_rightTableView.hidden = YES;
	} else if ([type isEqualToString:BPGrowlAlert]) {
		[window setFrame:NSMakeRect(window.frame.origin.x, window.frame.origin.y, window.frame.size.width, 154) display:YES animate:YES];

		_firstButton.title = NSLocalizedString(@"Stay until clicked", @"Stay until clicked checkbox");
		_firstButton.frame = NSMakeRect(_firstButton.frame.origin.x, 56, _firstButton.frame.size.width, _firstButton.frame.size.height);
		_firstButton.hidden = NO;

		_secondButton.hidden = YES;
		_pathField.hidden = YES;
		_pathSelectButton.hidden = YES;
		_leftTableView.hidden = YES;
		_rightTableView.hidden = YES;
	} else if ([type isEqualToString:BPScriptAlert]) { // NSOpenPanel
		[window setFrame:NSMakeRect(window.frame.origin.x, window.frame.origin.y, window.frame.size.width, 154) display:YES animate:YES];

		_firstButton.hidden = YES;
		_secondButton.hidden = YES;

		_pathCell.placeholderString = [_filePath lastPathComponent];
		_pathField.frame = NSMakeRect(20, 56, 247, 22);
		_pathField.hidden = NO;
		
		_pathSelectButton.frame = NSMakeRect(269, 50, 96, 32);
		_pathSelectButton.target = self;
		_pathSelectButton.action = @selector(selectFile);
		_pathSelectButton.hidden = NO;

		_leftTableView.hidden = YES;
		_rightTableView.hidden = YES;
	}

	_okayButton.frame = NSMakeRect(_okayButton.frame.origin.x, 12, _okayButton.frame.size.width, _okayButton.frame.size.height);
	_cancelButton.frame = NSMakeRect(_cancelButton.frame.origin.x, 12, _cancelButton.frame.size.width, _cancelButton.frame.size.height);

	self.window = window;
}

#pragma mark -

- (void) showWindow:(id) sender {
	self.window.title = _initialAlert.type.length ? NSLocalizedString(@"Modify Alert", @"Modify Alert") : NSLocalizedString(@"Create Alert", @"Create Alert");

	[super showWindow:sender];
	
}

#pragma mark -

- (IBAction) createOrModifyAlert:(id) sender {
	BPAlert *alert = [BPAlert alertWithAlert:[self alertTypeForSelection] values:[self valuesForSelection]];

	if ([_attachedRule containsAlert:alert]) {
		NSAlert *alertView = [NSAlert alertWithMessageText:NSLocalizedString(@"Alert Already Exists", @"Alert Already Exists sheet title") defaultButton:NSLocalizedString(@"Ok", @"Ok button title") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"An alert identical to \"%@\" already exists.", @"An alert identical to \"%@\" already exists message text."), alert.humanReadableFormat];
		[alertView beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];

		return;
	}

	if ([alert isSingleInstance] && [_attachedRule containsAlertType:alert.type]) {
		NSAlert *alertView = [NSAlert alertWithMessageText:NSLocalizedString(@"Alert Type Already Exists", @"Alert Type Already Exists sheet title") defaultButton:NSLocalizedString(@"Ok", @"Ok button title") alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Only one type of %@ alert is allowed.", @"Only one type of %@ alert is allowed."), alert.type];
		[alertView beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];

		return;
	}

	[_attachedRule addAlert:alert];

	[[BPAlertRulesController sharedInstance] saveAlert:alert forRule:_attachedRule];

	[[NSNotificationCenter defaultCenter] postNotificationName:BPAlertChangedNotification object:nil];

	[self close];
}

- (BOOL) windowShouldClose:(id) sender {
	if (!_initialAlert)
		return YES;

	BOOL close = YES;
	BPAlert *alert = [BPAlert alertWithAlert:[self alertTypeForSelection] values:[self valuesForSelection]];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:BPWarnBeforeCancelingModification] && ![alert isEqualToAlert:_initialAlert]) {
		NSAlert *alertView = [NSAlert alertWithMessageText:NSLocalizedString(@"Rule changed", @"Rule changed message text.") defaultButton:NSLocalizedString(@"Close window", @"Save modification button title") alternateButton:NSLocalizedString(@"Don't close window", @"Don't save changes button title") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"The rule changed, are you sure you want to cancel editing it? ", @"The rule changed, are you sure you want to cancel editing it? informative text")];
		alertView.alertStyle = NSInformationalAlertStyle;
		alertView.showsSuppressionButton = YES;

		((NSCell *)alertView.suppressionButton.cell).controlSize = NSSmallControlSize;
		((NSCell *)alertView.suppressionButton.cell).font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];

		if (![alertView runModal])
			close = NO;

		if (alertView.suppressionButton.state == NSOnState)
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:BPWarnBeforeCancelingModification];
	}

	return close;
}
@end
