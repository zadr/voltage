#import "BPApplicationDelegate.h"
#import "BPStatusBarController.h"

#import "BPPowerSourceInformation.h"

#import "BPAlertRulesController.h"

#import "BPStatusItemStylesManager.h"

#import "BPStatusItemStyle.h"
#import "BPRule.h"
#import "BPAlert.h"

@implementation BPApplicationDelegate
- (void) alertAndTerminateWithMessageText:(NSString *) messageText informativeText:(NSString *) informativeText {
	NSAlert *alert = [NSAlert alertWithMessageText:messageText defaultButton:NSLocalizedString(@"OK", @"OK button title") alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", informativeText];
	alert.alertStyle = NSWarningAlertStyle;
	[alert runModal];

	[NSApp terminate:nil];
}

#pragma mark -

- (void) applicationWillFinishLaunching:(NSNotification *) notification {
	// If we can't get power source information, we shouldn't bother running
	if (![BPPowerSourceInformation sharedInstance])
		[self alertAndTerminateWithMessageText:NSLocalizedString(@"Failed to obtain power source information", @"Failed to obtain power source message text") informativeText:NSLocalizedString(@"Failed to obtain power source information. Voltage will exit now.", @"Failed to obtain power source information. Voltage will exit now informative text.")];

	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[[NSBundle mainBundle] bundleIdentifier] ofType:@"plist"]]];

	NSString *alertsAndRulesPath = [[[NSFileManager defaultManager] userApplicationSupportPath] stringByAppendingString:@"/Voltage/Rules and Alerts.plist"];

	if ([[NSFileManager defaultManager] fileExistsAtPath:alertsAndRulesPath]) {
		NSArray *rulesAndAlerts = [NSArray arrayWithContentsOfFile:alertsAndRulesPath];
		BPRule *rule = nil;
		BPAlert *alert = nil;
		NSDictionary *ruleDictionary = nil;
		NSArray *alertsArray = nil;

		for (NSDictionary *ruleAndAlert in rulesAndAlerts) {
			ruleDictionary = ruleAndAlert[@"rule"];
			alertsArray = ruleAndAlert[@"alerts"];
			rule = [BPRule ruleWithRule:ruleDictionary[@"rule-string"] type:ruleDictionary[@"rule-type"]];

			if (![ruleDictionary[@"rule-enabled"] boolValue])
				rule.enabled = NO;

			for (NSDictionary *alertDictionary in alertsArray) {
				alert = [BPAlert alertWithAlert:alertDictionary[@"alert-type"] values:alertDictionary[@"alert-values"]];

				if (![alertDictionary[@"alert-enabled"] boolValue])
					alert.enabled = NO;

				[rule addAlert:alert];
			}

			[[BPAlertRulesController sharedInstance] addRule:rule];
		}
	}

	if (![[BPStatusBarController sharedInstance] createStatusBarMenuForDisplay])
		[self alertAndTerminateWithMessageText:NSLocalizedString(@"Unable to create menubar item.", @"Unable to create menubar item. message text.") informativeText:NSLocalizedString(@"Unable to create menubar item. Voltage can't run without a menubar item. Exiting.", @"Unable to create menubar item. Voltage can't run without a menubar item. Exiting. message text")];
}

- (void) applicationDidFinishLaunching:(NSNotification *) notification {
	if (![[NSUserDefaults standardUserDefaults] boolForKey:BPAskedToAllowAnalytics] && [[NSUserDefaults standardUserDefaults] boolForKey:BPHasLaunchedBeforeKey]) {
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Allow analytics to be sent?", @"Allow analytics to be sent? message text.") defaultButton:NSLocalizedString(@"Send", @"Send button title") alternateButton:NSLocalizedString(@"Don't send", @"Don't send button title") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"To help us know what to improve on, Voltage can send back information about your current configuration. The data sent back will not contain will not contain any identifiable information. ", @"To help us know what to improve on, Voltage can send back information about your current configuration. The data sent back will not contain will not contain any identifiable information message text")];
		alert.alertStyle = NSInformationalAlertStyle;

		if ([alert runModal])
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:BPAllowAnalytics];

		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:BPAskedToAllowAnalytics];
	}

	if (![[NSUserDefaults standardUserDefaults] stringForKey:BPLogPath].length) {
		NSString *logPath = [[[NSFileManager defaultManager] userApplicationSupportPath] stringByAppendingPathComponent:@"voltage.log"];

		[[NSUserDefaults standardUserDefaults] setObject:logPath forKey:BPLogPath];
	}
}

- (void) applicationWillTerminate {
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:BPHasLaunchedBeforeKey];
}

- (BOOL) application:(NSApplication *) sender openFile:(NSString *) file {
	if ([[file pathExtension] caseInsensitiveCompare:@"voltageStyle"])
		return NO;

	BPStatusItemStyle *style = [BPStatusItemStyle styleFromPath:file];

	if (![style isValid])
		return NO;

	if ([[BPStatusItemStylesManager sharedInstance] containsStatusItemStyle:style]) {
		NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Voltage style already exists", @"Voltage style already exists alert title") defaultButton:NSLocalizedString(@"Replace", @"Replace button title") alternateButton:NSLocalizedString(@"Don't Replace", @"Don't Replace button title") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"%@ already exists. Would you like to replace it?", @"%@ already exists. Would you like to replace it? alert message"), file];
		if ([alert runModal]) {
			// TODO: replace style
		} else return NO;
	}

	NSError *error = nil;
	NSString *newFilePath = [[[NSFileManager defaultManager] userApplicationSupportPath] stringByAppendingString:[NSString stringWithFormat:@"/Voltage/Styles/%@", [file lastPathComponent]]];

	return ![[NSFileManager defaultManager] moveItemAtPath:file toPath:newFilePath error:&error];
}

#pragma mark -

- (NSImage *) applicationIconForGrowl {
	return nil;

	NSInteger percentRemaining = [BPPowerSourceInformation sharedInstance].percentRemaining;
	percentRemaining = percentRemaining > 0 ? ((percentRemaining / 10) * 10) : 0; // TODO: fix for 1-9%

	NSString *imageName = [NSString stringWithFormat:@"battery-%ld.png", percentRemaining];
	NSURL *imageURL = [[NSRunningApplication currentApplication].bundleURL URLByAppendingPathExtension:[NSString stringWithFormat:@"Contents/Resources/%@", imageName]];

	return [[NSImage alloc] initWithContentsOfURL:imageURL];
}
@end
