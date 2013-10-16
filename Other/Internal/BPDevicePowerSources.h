@interface BPDevicePowerSources : NSObject {
@private
	CFTypeRef _devicePowerSources;
	CFArrayRef _powerSourceList;
}
@property (strong, readwrite) __attribute__((NSObject)) CFTypeRef devicePowerSources;
@property (strong, readwrite) __attribute__((NSObject)) CFArrayRef powerSourceList;
@end
