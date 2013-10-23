#import "BPAlertsRulesWindowController.h"
#import "BPAlertCreationWindowController.h"
#import "BPRulesCriterionWindowController.h"

#import "BPAlertRulesController.h"

#import "BPRule.h"
#import "BPAlert.h"

#import "BPCell.h"

#import "BPTimeIntervalFormatter.h"

#define BPAlertRulesWindowToolbarFlexibleSpaceItem -1
#define BPAlertRulesWindowToolbarAddItem 0
#define BPAlertRulesWindowToolbarRemoveItem 1
#define BPAlertRulesWindowToolbarModifyItem 2
#define BPAlertRulesWindowToolbarPauseItem 3

@implementation BPAlertsRulesWindowController
- (id) init {
	if (!(self = [super initWithWindowNibName:@"ManageAlertsAndRules" owner:self]))
		return nil;

	self.window.minSize = CGSizeMake(235, 275);

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload:) name:BPRulesChangedNotification object:nil];

	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BPRulesChangedNotification object:nil];

}

#pragma mark -

- (IBAction) reload:(id) sender {
	[_outlineView reloadData];
}

#pragma mark -

- (NSInteger) outlineView:(NSOutlineView *) outlineView numberOfChildrenOfItem:(id) item {
	if (!item)
		return [[BPAlertRulesController sharedInstance] numberOfRules];

	NSUInteger count = ((BPRule *)item).alerts.count;
	return (count > INT_MAX) ? 0 : (NSInteger)count;
}

- (BOOL) outlineView:(NSOutlineView *) outlineView isItemExpandable:(id) item {
	return [item isKindOfClass:[BPRule class]];
}

- (id) outlineView:(NSOutlineView *) outlineView child:(NSInteger) index ofItem:(id) item {
	if (!item)
		return [[BPAlertRulesController sharedInstance] ruleAtIndex:index];
	if (index <= INT_MAX)
		return (((BPRule *)item).alerts)[(NSUInteger)index];
	return nil;
}

- (NSCell *) outlineView:(NSOutlineView *) outlineView dataCellForTableColumn:(NSTableColumn *) tableColumn item:(id) item {
	BPCell *cell = [[BPCell alloc] initTextCell:((BPModel *)item).humanReadableFormat];

	cell.enabled = YES;
	cell.wraps = YES;

	return cell;
}

- (NSString *) outlineView:(NSOutlineView *) outlineView toolTipForCell:(NSCell *) cell rect:(NSRectPointer) rect tableColumn:(NSTableColumn *) tableColumn item:(id) item mouseLocation:(NSPoint) mouseLocation {
	return ((BPModel *)item).humanReadableFormat;
}

- (id) outlineView:(NSOutlineView *) outlineView objectValueForTableColumn:(NSTableColumn *) tableColumn byItem:(id) item {
	return ((BPModel *)item).humanReadableFormat;
}

- (CGFloat) outlineView:(NSOutlineView *) outlineView heightOfRowByItem:(id) item {
	return ([item isKindOfClass:[BPRule class]]) ? 25. : 20.;
}

#pragma mark -

- (BOOL) outlineView:(NSOutlineView *) outlineView shouldEditTableColumn:(NSTableColumn *) tableColumn item:(id) item {
	return NO;
}

- (BOOL) outlineView:(NSOutlineView *) outlineView shouldSelectItem:(id) item {
	_validatedCount = 0;

	return YES;
}

#pragma mark -

- (BOOL) validateToolbarItem:(NSToolbarItem *) item {
	if (_validatedCount > 2)
		return YES;

	_validatedCount++;

	return YES;
}

#pragma mark -

- (BOOL) deleteConfirmation:(BOOL) isAlert {
	if (![[NSUserDefaults standardUserDefaults] boolForKey:BPWarnBeforeAlertRuleRemoval]) {
		BOOL delete = NO;
		NSString *substitution = (isAlert) ? NSLocalizedString(@"an alert", @"an alert text substitution") : NSLocalizedString(@"a rule", @"a rule text substitution");

		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Delete rule?", @"Delete rule message text") defaultButton:NSLocalizedString(@"OK", @"OK button title") alternateButton:NSLocalizedString(@"Cancel", @"Cancel button title") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Are you sure you want to delete %@?", @"Are you sure you want to delete %@? informative text"), substitution];
		alert.alertStyle = NSWarningAlertStyle;
		alert.showsSuppressionButton = YES;

		((NSCell *)alert.suppressionButton.cell).controlSize = NSSmallControlSize;
		((NSCell *)alert.suppressionButton.cell).font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];

		if ([alert runModal]) {
			delete = YES;
			if (alert.suppressionButton.state == NSOnState)
				[[NSUserDefaults standardUserDefaults] setBool:YES forKey:BPWarnBeforeAlertRuleRemoval];
		}

		return delete;
	}

	return YES;
}

#pragma mark -

- (void) createRule {
	if (newRuleController) {
		[[newRuleController window] orderFront:nil];

		return;
	}

	newRuleController = [[BPRulesCriterionWindowController alloc] initWithRule:nil];
	[newRuleController showWindow:nil];
}

- (void) modifyRule:(BPRule *) rule {
	if (editRuleController) {
		[[editRuleController window] orderFront:nil];

		return;
	}

	editRuleController = [[BPRulesCriterionWindowController alloc] initWithRule:rule];
	[editRuleController showWindow:nil];
}

- (void) deleteRule:(BPRule *) rule {
	if ([self deleteConfirmation:NO]) {
		[[BPAlertRulesController sharedInstance] removeRule:rule];

		[self reload:nil];
	}
}

#pragma mark -

- (void) createAlertForRule:(BPRule *) rule {
	BPAlertCreationWindowController *alertCreationViewController = [[BPAlertCreationWindowController alloc] initWithAlert:nil forRule:rule];
	[alertCreationViewController showWindow:nil];
}

- (void) modifyAlert:(BPAlert *) alert forRule:(BPRule *) rule {
	BPAlertCreationWindowController *alertCreationViewController = [[BPAlertCreationWindowController alloc] initWithAlert:alert forRule:rule];
	[alertCreationViewController showWindow:nil];
}

- (void) deleteAlert:(BPAlert *) alert forRule:(BPRule *) rule {
	if ([self deleteConfirmation:YES]) {
		[rule removeAlert:alert];

		[self reload:nil];
	}
}

#pragma mark -

- (BPRule *) _ruleForSelectedAlert {
	for (NSInteger row = [_outlineView selectedRow]; row >= 0; row--) {
		id item = [_outlineView itemAtRow:row];
		if ([item isKindOfClass:[BPRule class]])
			return item;
	}

	return nil;
}

#pragma mark -

- (IBAction) createItem:(id) sender {
	id item = [_outlineView itemAtRow:[_outlineView selectedRow]];

	if ([item isKindOfClass:[BPRule class]] || !item) {
		if (item && [_outlineView isItemExpanded:item])
			[self createAlertForRule:item];
		else [self createRule];

		return;
	}

	[self createAlertForRule:[self _ruleForSelectedAlert]];
}

- (IBAction) modifyItem:(id) sender {
	NSInteger selectedRow = [_outlineView selectedRow];
	if (selectedRow == -1)
		return;

	id item = [_outlineView itemAtRow:selectedRow];

	if ([item isKindOfClass:[BPRule class]]) {
		[self modifyRule:item];

		return;
	}

	[self modifyAlert:item forRule:[self _ruleForSelectedAlert]];
}

- (IBAction) deleteItem:(id) sender {
	NSInteger selectedRow = [_outlineView selectedRow];
	if (selectedRow == -1)
		return;

	id item = [_outlineView itemAtRow:selectedRow];

	if ([item isKindOfClass:[BPRule class]]) {
		[self deleteRule:item];

		return;
	}

	[self deleteAlert:item forRule:[self _ruleForSelectedAlert]];
}

- (IBAction) pauseItem:(id) sender {
	BPModel *model = [_outlineView itemAtRow:[_outlineView selectedRow]];
	model.enabled = !model.enabled;
}
@end
