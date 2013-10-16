@class BPAlert;
@class BPRule;

@interface BPAlertCreationWindowController : NSWindowController <NSWindowDelegate> {
@private
	IBOutlet NSPopUpButton *_alertTypePopUp;
	IBOutlet NSButton *_firstButton;
	IBOutlet NSButton *_secondButton;
	IBOutlet NSTextField *_pathField;
	IBOutlet NSTextFieldCell *_pathCell;
	IBOutlet NSButton *_pathSelectButton;
	IBOutlet NSButton *_okayButton;
	IBOutlet NSButton *_cancelButton;

	IBOutlet NSTextFieldCell *_cpuValueCell;
	IBOutlet NSTableView *_leftTableView;
	IBOutlet NSTableView *_rightTableView;

	NSString *_filePath;

	BPAlert *_initialAlert;
	BPRule *_attachedRule;
}

- (id) initWithAlert:(BPAlert *) alert forRule:(BPRule *) rule;

- (IBAction) updateWindowForSelection:(id) sender;

- (IBAction) createOrModifyAlert:(id) sender;
@end
