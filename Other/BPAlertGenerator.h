@interface BPAlertGenerator : NSObject <NSSoundDelegate> {
@private
	NSSound *_sound;
}

+ (BPAlertGenerator *) sharedInstance;

- (BOOL) popupAlertWithInformation:(NSDictionary *) information;
- (BOOL) audioAlertWithInformation:(NSDictionary *) information;
- (BOOL) notificationAlertWithInformation:(NSDictionary *) information;
- (BOOL) scriptAlertWithInformation:(NSDictionary *) information;
- (BOOL) flashScreenAlertWithInformation:(NSDictionary *) information;
@end
