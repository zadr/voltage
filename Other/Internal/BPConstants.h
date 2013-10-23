#define GENERATE_GRAPHS 0

// Preference Keys
extern NSString *const BPHasLaunchedBeforeKey;				// Defined by Sparkle as SUHasLaunchedBeforeKey, used to see if the app has been launched or not
extern NSString *const BPIgnoreAccidentalStateChanges;		// Time to wait for power source to be plugged in / unplugged before firing alerts
extern NSString *const BPAskedToAllowAnalytics;				// Have we asked to send analytics?
extern NSString *const BPAllowAnalytics;					// Has the user let us send analytics?
extern NSString *const BPLogPath;							// Where should we log to? (hidden, default ~/Library/Application Support/Voltage/*.log)
extern NSString *const BPLoggingLevel;						// How much information should be logged
extern NSString *const BPKeepTenMinuteRule;					// Should we keep a pseudorule for the built-in 10 minute alert? (hidden, default on)
extern NSString *const BPLongFormatting;					// HH:MM (PP%) or X Hours and Y Minutes\nZZ Percent
extern NSString *const BPFullyChargedTitle;					// What should the status item title be when fully charged? (plugged in and not charging) (Hidden, default blank and values hardcoded for l10n)
extern NSString *const BPFullyDrainedTitle;					// What should the status item be when fully drained? (not plugged in and at 0%) (Hidden, default blank and values hardcoded for l10n)
extern NSString *const BPUniqueMachineIdentifier;			// Anonymous unique machine identifier (hidden, shouldn't be touched)
extern NSString *const BPSendCrashReports;					// Should we always send crash reports, ask before sending, or never send reports
extern NSString *const BPLastSentCrashReportDate;			// When was the last time we sent crash reports?
extern NSString *const BPWarnBeforeAlertRuleRemoval;		// Should we ask before deleting an alert or rule?
extern NSString *const BPWarnBeforeCancelingModification;	// Should we ask before closing a window when editing a rule or alert?
extern NSString *const BPDaysInMonthlyGraph;				// How many days are in a "month"? (Hidden, default 30)
extern NSString *const BPPreviousDailyGraphUpdateDate;		// When was the last day we updated the graph? (hidden, shouldn't be touched)
extern NSString *const BPDailyUpdateHour;					// When was the last hour we updated the daily graph (hidden, shouldn't be touched)
extern NSString *const BPDisplayErrors;						// Tell the user about errors?
extern NSString *const BPWaitAfterWakeInterval;				// How long to wait after waking up before firing alerts (hidden, in seconds)
extern NSString *const BPShowStatusBarIcon;					// Does the statusbar have an icon?
extern NSString *const BPShowPercentInStatusBar;			// Should we show the percent remaining in the status bar?
extern NSString *const BPShowTimeInStatusBar;				// Should we show the time remaining in the status bar?
extern NSString *const BPLaunchInBackground;				// Should applications be launched in the background? (hidden, defaults to yes)
extern NSString *const BPTimeBetweenSameRule;				// How long to wait between firing a rule again

// Alerts
extern NSString *const BPAlertChangedNotification;			// Notification fired when an alert is changed
extern NSString *const BPNSAlert;							// Key for NSAlert popups
extern NSString *const BPAudioAlert;						// Key for Audio alerts
extern NSString *const BPScriptAlert;						// Key for scripts run after a rule is matched

// Alert Keys
extern NSString *const BPNSAlertAlwaysOnTop;				// Should the NSAlert window always be on top?
extern NSString *const BPAudioRepeats;						// Should the sound repeat until halted?
extern NSString *const BPMaximumVolume;						// Should we play the sound at maximum volume?
extern NSString *const BPAudioPath;							// Where is the sound located?
extern NSString *const BPScriptPath;						// Where is the script located?

// Rules
extern NSString *const BPRulesChangedNotification;			// Notification fired when a rule is changed
extern NSString *const BPPowerTimeRemainingRule;			// Key for time remaining rules
extern NSString *const BPPowerPercentRule;					// Key for percent remaining rules
extern NSString *const BPPowermAhRule;						// Key for mAh remaining rules
extern NSString *const BPPowerSourceLostRule;				// Key for power source lost
extern NSString *const BPPowerSourceFoundRule;				// Key for power source found

