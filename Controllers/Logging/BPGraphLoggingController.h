@interface BPGraphLoggingController : NSObject
#if GENERATE_GRAPHS
{
	@private
		BOOL _updatedHourlyInformation;
}

- (void) logPowerSourceInformation;
#endif
@end
