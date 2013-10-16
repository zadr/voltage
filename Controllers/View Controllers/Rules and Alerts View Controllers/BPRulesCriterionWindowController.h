@class BPRule;

@interface BPRulesCriterionWindowController : NSWindowController <NSWindowDelegate> {
@private
	IBOutlet NSPopUpButton *_ruleTypePopUp;
	IBOutlet NSPopUpButton *_ruleValuePopUp;
	IBOutlet NSTextFieldCell *_ruleValueTextFieldCell;
	IBOutlet NSPopUpButton *_timeIntervalPopUp;
	IBOutlet NSTextFieldCell *_informationLabel;

	BPRule *_initialRule;
}

- (id) initWithRule:(BPRule *) rule;

- (IBAction) updateWindowForSelection:(id) sender;

- (IBAction) createOrModifyRule:(id) sender;
@end
