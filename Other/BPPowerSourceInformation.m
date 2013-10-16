// Only works for the first power source. How common are UPS's on Laptops?
// Does any of this work on an iMac/Mac Mini/Mac Pro with a UPS?

#import "BPPowerSourceInformation.h"
#import "BPTimeIntervalFormatter.h"

#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>

#import <IOKit/pwr_mgt/IOPM.h>
#import <IOKit/pwr_mgt/IOPMLib.h>

#define MinimumUpdateTime 1

@implementation BPPowerSourceInformation
+ (BPPowerSourceInformation *) sharedInstance {
	static BPPowerSourceInformation *sharedInstance = nil;
	static dispatch_once_t once_t;

	dispatch_once(&once_t, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

#pragma mark -

- (void) setOnACPower:(BOOL) onACPower {
	_onACPower = onACPower;
}

- (void) setPreviousNumberOfPowerSources:(NSInteger) previousNumberOfPowerSources {
	_previousNumberOfPowerSources = previousNumberOfPowerSources;
}

- (void) setTimeSincePowerSourceChanged:(NSTimeInterval) newTimeSincePowerSourceChanged {
	_timeSincePowerSourceChanged = newTimeSincePowerSourceChanged;
}

#pragma mark -

- (NSTimeInterval) _previousNumberOfPowerSources {
	return _previousNumberOfPowerSources;
}

- (volatile __strong BPDevicePowerSources *) devicePowerSourcesContainer {
	return _container;
}

- (NSTimeInterval) _timeSincePowerSourcesWereUpdated {
	return _timeSincePowerSourcesWereUpdated;
}

- (BOOL) _canUpdate {
	return _canUpdate;
}

static void updatePowerSources (void *context) {
	BPPowerSourceInformation *self = (__bridge BPPowerSourceInformation *)context;

	if (![self _canUpdate]) // Add a method to call updatePowerSources automatically after a minute or so
		return;

	@synchronized(self) {
		if (([NSDate timeIntervalSinceReferenceDate] - [self _timeSincePowerSourcesWereUpdated]) < 1.) // Only update once a second
			return;

		CFTypeRef devicePowerSources = IOPSCopyPowerSourcesInfo();
		CFArrayRef powerSourceList = IOPSCopyPowerSourcesList(devicePowerSources);

		[self devicePowerSourcesContainer].devicePowerSources = devicePowerSources;
		[self devicePowerSourcesContainer].powerSourceList = powerSourceList;

		CFRelease(devicePowerSources);
		CFRelease(powerSourceList);

		if ([self _previousNumberOfPowerSources] > self.numberOfPowerSources)
			[[NSNotificationCenter defaultCenter] postNotificationName:BPPowerSourceLostNotification object:nil userInfo:nil];
		else if ([self _previousNumberOfPowerSources] < self.numberOfPowerSources)
			[[NSNotificationCenter defaultCenter] postNotificationName:BPPowerSourceFoundNotification object:nil userInfo:nil];

		// Changed from AC to battery power
		if (self.onACPower && self.powerSourceState != BPOnACPowerIdentifier) {
			self.onACPower = NO;
			self.timeSincePowerSourceChanged = [NSDate timeIntervalSinceReferenceDate];
		}

		// Changed from battery power to AC
		if (!self.onACPower && self.powerSourceState != BPOnBatteryPowerIdentifier) {
			self.onACPower = YES;
			self.timeSincePowerSourceChanged = [NSDate timeIntervalSinceReferenceDate];
		}

		[self setPreviousNumberOfPowerSources:self.numberOfPowerSources];

		[[NSNotificationCenter defaultCenter] postNotificationName:BPPowerSourceUpdateNotification object:nil userInfo:nil];
	}
}

- (id) init {
	if (!(self = [super init]))
		return nil;

	CFRunLoopSourceRef runLoop = IOPSNotificationCreateRunLoopSource(updatePowerSources, (__bridge void *)(self));

	if (runLoop)
		CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoop, kCFRunLoopDefaultMode);
	else return nil;

	_canUpdate = YES;

	CFTypeRef devicePowerSources = IOPSCopyPowerSourcesInfo();
	CFArrayRef powerSourceList = IOPSCopyPowerSourcesList(devicePowerSources);

	_container = [[BPDevicePowerSources alloc] init];
	_container.devicePowerSources = devicePowerSources;
	_container.powerSourceList = powerSourceList;

	CFRelease(devicePowerSources);
	CFRelease(powerSourceList);

	_previousNumberOfPowerSources = self.numberOfPowerSources;

	_timeRemainingLastUpdate = [NSDate timeIntervalSinceReferenceDate];
	_timeSincePowerSourceChanged = _timeRemainingLastUpdate;

	_onACPower = (self.powerSourceState == BPOnACPowerIdentifier) ? YES : NO;

	return self;
}

#pragma mark -

- (NSInteger) numberOfPowerSources {
	return [((NSArray *)_container.powerSourceList) count];
}

#pragma mark -

- (CFTypeRef) powerSourceDetailForKey:(CFTypeRef) eventRef {
	CFTypeRef detail = NULL;
	_canUpdate = NO;

	@synchronized(self) {
		CFDictionaryRef batteryRef = IOPSGetPowerSourceDescription(_container.devicePowerSources, CFArrayGetValueAtIndex(_container.powerSourceList, 0));

		if (batteryRef)
			detail = CFDictionaryGetValue(batteryRef, eventRef);

		// Failed to get the info needed from the "safe" IOPS* functions, so lets try the unsupported IOPM* functions instead
		// Don't cache this information, since it changes much more frequently than IOPS* does; it gives access to info such as current voltage or amps
		if (!detail) {
			mach_port_t devicePort;
			CFArrayRef allBatteries;

			if (IOMasterPort(bootstrap_port, &devicePort) != kIOReturnSuccess)
				return NULL;

			if (IOPMCopyBatteryInfo(devicePort, &allBatteries))
				return NULL;

			batteryRef = CFArrayGetValueAtIndex(allBatteries, 0);

			if (!batteryRef)
				return NULL;

			detail = CFDictionaryGetValue(batteryRef, eventRef);
		}
	}

	_canUpdate = YES;

	return detail;
}

#pragma mark -

- (NSInteger) integerForCFNumberRef:(CFNumberRef) numberRef {
	if (numberRef)
		return [(__bridge NSNumber *)numberRef integerValue];
	return 0;
}

- (BOOL) boolForCFBooleanRef:(CFBooleanRef) booleanRef {
	if (booleanRef)
		return (BOOL)CFBooleanGetValue(booleanRef);
	return NO;
}

#pragma mark -

- (BOOL) isCharging {
	if (!_onACPower)
		return NO;
	return [self boolForCFBooleanRef:[self powerSourceDetailForKey:CFSTR(kIOPSIsChargingKey)]];
}

// Apparently not all of the keys in IOPSKeys.h are actually implemented by Apple-supplied power sources. This key is one of the ones that isn't implemented, even though the information is given from `ioreg`..
- (BOOL) isCharged {
	if (!self.isCharging && _onACPower)
		return YES;
	return NO;
	//	return CFBooleanGetValue([self powerSourceDetailForKey:CFSTR(kIOPSIsChargedKey)]);
}

- (BOOL) isFinishingCharge {
	if (!_onACPower)
		return NO;
	return [self boolForCFBooleanRef:[self powerSourceDetailForKey:CFSTR(kIOPSIsFinishingChargeKey)]];
}

- (NSInteger) timeToFullCharge {
	if (self.isCharging)
		return [self integerForCFNumberRef:[self powerSourceDetailForKey:CFSTR(kIOPSTimeToFullChargeKey)]];
	return -2; // -1 is returned by kIOPSTimeToFullChargeKey to indicte "Still Calculating the Time"
}

#pragma mark -

- (NSInteger) powerSourceState {
	CFStringRef status = [self powerSourceDetailForKey:CFSTR(kIOPSPowerSourceStateKey)];

	if (!status)
		return BPNoPowerIdentifier; // We couldn't get an identifier for the power source
	if (status && !CFStringCompare(status, CFSTR(kIOPSBatteryPowerValue), 0))
		return BPOnBatteryPowerIdentifier;
	if (status && !CFStringCompare(status, CFSTR(kIOPSACPowerValue), 0))
		return BPOnACPowerIdentifier;
	return BPNoPowerIdentifier; // Offline, kIOPSOffLineValue or unknown.
}

#pragma mark -

// Apparently not all of the keys in IOPSKeys.h are actually implemented by Apple-supplied power sources. This key is one of the ones that isn't implemented, even though the information is given from `ioreg`..
- (NSString *) batteryHealthStatus {
	CFStringRef statusRef = [self powerSourceDetailForKey:CFSTR(kIOPSBatteryHealthConditionKey)];

	if (!statusRef)
		statusRef = [self powerSourceDetailForKey:CFSTR(kIOPSBatteryHealthKey)];

	NSString *status = nil;

	if (!CFStringCompare(statusRef, CFSTR(kIOPSPoorValue), 0))
		status = NSLocalizedString(@"Poor", @"Poor battery health");
	else if (!CFStringCompare(statusRef, CFSTR(kIOPSFairValue), 0))
		status = NSLocalizedString(@"Fair", @"Fair battery health");
	else if (!CFStringCompare(statusRef, CFSTR(kIOPSGoodValue), 0))
		status = NSLocalizedString(@"Good", @"Good battery health");
	else if (!CFStringCompare(statusRef, CFSTR(kIOPSCheckBatteryValue), 0)) {
		_unhealthy = YES;

		status = NSLocalizedString(@"Check Battery", @"Check Battery battery health");
	} else if (!CFStringCompare(statusRef, CFSTR(kIOPSPermanentFailureValue), 0)) {
		_unhealthy = YES;

		status = NSLocalizedString(@"Permanent Battery Failure: ", @"Permanent Battery failure: reason to follow battery health");
		statusRef = [self powerSourceDetailForKey:CFSTR(kIOPSBatteryFailureModesKey)];

		if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureExternalInput), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Externally Indicated status", @"Externally Indicated status battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureSafetyOverVoltage), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Safety Over-Voltage", @"Safety Over-Voltage battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureChargeOverTemp), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Charge Over-Temperature", @"Charge Over-Temperature battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureDischargeOverTemp), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Discharge Over-Temperature", @"Discharge Over-Temperature battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureCellImbalance), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Cell Imbalance", @"Cell Imbalance battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureChargeFET), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Charge FET", @"Charge FET battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureDischargeFET), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Discharge FET", @"Discharge FET battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureDataFlushFault), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Data Flush Fault", @"Data Flush Fault battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailurePermanentAFEComms), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Permanent AFE Comms", @"Permanent AFE Comms battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailurePeriodicAFEComms), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Periodic AFE Comms", @"Periodic AFE Comms battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureChargeOverCurrent), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Charge Over-Current", @"Charge Over-Current battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureDischargeOverCurrent), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Discharge Over-Current", @"Discharge Over-Current battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureOpenThermistor), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Open Thermistor", @"Open Thermistor battery failure")];
		else if (!CFStringCompare(statusRef, CFSTR(kIOPSFailureFuseBlown), 0))
			status = [status stringByAppendingString:NSLocalizedString(@"Fuse Blown", @"Fuse Blown battery failure")];
	} else status = NSLocalizedString(@"Not Found", @"Not Found battery string");

	return status;
}

#pragma mark -

// This key is documented to return the current capacity of the battery. However, in practice, it returns the current percentage remaining on the battery.
- (NSInteger) percentRemaining {
	return [self integerForCFNumberRef:[self powerSourceDetailForKey:CFSTR(kIOPSCurrentCapacityKey)]];
}

- (NSInteger) timeRemaining {
	if (!_timeRemainingLastUpdate)
		_timeRemainingLastUpdate = [NSDate timeIntervalSinceReferenceDate];

	if (([NSDate timeIntervalSinceReferenceDate] - _timeRemainingLastUpdate) < MinimumUpdateTime)
		return _timeRemaining;

	CFStringRef timeToRef = self.isCharging ? CFSTR(kIOPSTimeToFullChargeKey) : CFSTR(kIOPSTimeToEmptyKey);
	_timeRemaining = [self integerForCFNumberRef:[self powerSourceDetailForKey:timeToRef]];

	return _timeRemaining;
}

- (BOOL) updating {
	CFStringRef timeToRef = self.isCharging ? CFSTR(kIOPSTimeToFullChargeKey) : CFSTR(kIOPSTimeToEmptyKey);
	CFNumberRef timeRemainingRef = [self powerSourceDetailForKey:timeToRef];
	static CFNumberRef negativeOneRef = NULL;

	if (!negativeOneRef) {
		NSInteger negativeOne = -1;
		negativeOneRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberNSIntegerType, &negativeOne);
	}

	return !CFNumberCompare(timeRemainingRef, negativeOneRef, NULL);
}

#pragma mark -

- (NSInteger) currentCapacity {
	return [self integerForCFNumberRef:[self powerSourceDetailForKey:CFSTR(kIOPMPSCurrentCapacityKey)]];
}

- (NSInteger) maxCapacity {
	return [self integerForCFNumberRef:[self powerSourceDetailForKey:CFSTR(kIOPMPSMaxCapacityKey)]];
}

- (NSInteger) designCapacity {
	return [self integerForCFNumberRef:[self powerSourceDetailForKey:CFSTR(kIOPMPSDesignCapacityKey)]];
}

#pragma mark -

- (NSInteger) chargeCount {
	return [self integerForCFNumberRef:[self powerSourceDetailForKey:CFSTR(kIOBatteryCycleCountKey)]];
}

#pragma mark -

- (NSString *) hardwareSerialNumber {
	NSString *hardwareSerialNumber = [self powerSourceDetailForKey:CFSTR(kIOPSHardwareSerialNumberKey)];
	if (hardwareSerialNumber.length)
		return hardwareSerialNumber;
	return nil;
}

- (NSString *) name {
	NSString *name = [self powerSourceDetailForKey:CFSTR(kIOPSNameKey)];
	if (name.length)
		return name;
	return nil;
}

- (BOOL) batteryIsUnhealthy {
	return _unhealthy;
}

#pragma mark -

- (NSString *) abbreviatedFormattedTimeRemaining {
	return [BPTimeIntervalFormatter abbreviatedFormattedInterval:(self.timeRemaining * 60)];
}
@end
