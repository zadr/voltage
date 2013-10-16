@class BPRulesCriterionWindowController;

@interface BPAlertsRulesWindowController : NSWindowController <NSOutlineViewDataSource, NSOutlineViewDelegate, NSToolbarDelegate> {
@private
	IBOutlet NSOutlineView *_outlineView;

	uint8_t _validatedCount;

	BPRulesCriterionWindowController *newRuleController;
	BPRulesCriterionWindowController *editRuleController;
}

- (IBAction) createItem:(id) sender;
- (IBAction) modifyItem:(id) sender;
- (IBAction) deleteItem:(id) sender;
- (IBAction) pauseItem:(id) sender;
@end
