#import "BPDevicePowerSources.h"

#define BPNoPowerIdentifier 0
#define BPOnBatteryPowerIdentifier 1
#define BPOnACPowerIdentifier 2

static NSString *const BPPowerSourceUpdateNotification = @"BPPowerSourceUpdateNotification";
static NSString *const BPPowerSourceLostNotification = @"BPPowerSourceLostNotification";
static NSString *const BPPowerSourceFoundNotification = @"BPPowerSourceFoundNotification";

@interface BPPowerSourceInformation : NSObject {
@private
	BOOL _canUpdate;
	BOOL _unhealthy;
	BPDevicePowerSources *_container;
	NSInteger _timeRemaining;
	NSTimeInterval _timeRemainingLastUpdate;
	NSTimeInterval _timeSincePowerSourceChanged;
	NSTimeInterval _timeSincePowerSourcesWereUpdated;
	NSInteger _previousNumberOfPowerSources;
	BOOL _onACPower;
}
@property (readonly) BOOL onACPower;
@property (readonly) BOOL updating;
@property (readonly) NSTimeInterval timeSincePowerSourceChanged;
@property (readonly) NSInteger numberOfPowerSources;
@property (readonly) BOOL isCharging;
@property (readonly) BOOL isFinishingCharge;
@property (readonly) NSInteger timeToFullCharge;
@property (readonly) BOOL isCharged;
@property (readonly) NSInteger powerSourceState;
@property (copy, readonly) NSString *batteryHealthStatus;
@property (readonly) NSInteger percentRemaining;
@property (readonly) NSInteger timeRemaining;
@property (readonly) NSInteger currentCapacity;
@property (readonly) NSInteger maxCapacity;
@property (readonly) NSInteger designCapacity;
@property (readonly) NSInteger chargeCount;
@property (copy, readonly) NSString *hardwareSerialNumber;
@property (copy, readonly) NSString *name;
@property (readonly) BOOL batteryIsUnhealthy;

+ (BPPowerSourceInformation *) sharedInstance;

- (NSString *) abbreviatedFormattedTimeRemaining;
@end
