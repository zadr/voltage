@class BPAlertsRulesWindowController;

@interface BPStatusBarController : NSObject <NSMenuDelegate> {
@private
	NSStatusItem *_statusItem;
	NSInteger _selectedItem;
	BOOL _disabled;

	NSWindowController *_preferencesWindowController;
	BPAlertsRulesWindowController *_rulesAndAlertsWindowController;
}
+ (BPStatusBarController *) sharedInstance;

- (BOOL) createStatusBarMenuForDisplay;
@end
