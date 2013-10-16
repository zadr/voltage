//
// BPAudioMetadataReader supports limited metadata reading for the following UTI types: (tl;dr anything in [NSSound soundUnfilteredTypes]; is supported):
// "public.aiff-audio", "public.aifc-audio", "com.microsoft.waveform-audio", "public.ulaw-audio", "public.mp3", "com.apple.protected-mpeg-4-audio", "public.mpeg-4-audio", "dyn.agk8ycxcbn6", "com.apple.cocoa.pasteboard.sound"
// See: http://developer.apple.com/Mac/library/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html for what filetype the UTI maps to
//

#import "BPAudioMetadataReader.h"

typedef enum {
	BPAudioMetadataID3V1Type, // v1
	BPAudioMetadataID3V11Type, // v1.1
	BPAudioMetadataID3V1EType, // v1, Enhanced tag
	BPAudioMetadataID3V2CType, // v2, Chapter
	BPAudioMetadataID3V2EIType, // v2, Embedded Image
	BPAudioMetadataID3V23Type, // v2.3, Frame Specification
	BPAudioMetadataID3V231Type, // v2.3.1, Multiple Value Frame Specification
	BPAudioMetadataID3V24Type, // v2.4, Frame specification
	BPAudioMetadataID3V241Type, // v2.4.1, Multiple Value Frame Specification
	BPAudioMetadataBWVType, // Broadcast Wave Format, in a RIFF chunk, for wav
	BPAudioMetadataTypeNone // no metadata found
} BPAudioMetadataType;

#pragma mark -

@implementation BPAudioMetadataReader

- (BPAudioMetadataType) audioMetadataTypeForFileAtPath:(NSString *) path {
	return BPAudioMetadataTypeNone;
}

#pragma mark -

+ (NSString *) artistForFileAtPath:(NSString *) path {
	return nil;
}

+ (NSString *) songForFileAtPath:(NSString *) path {
	return nil;
}

+ (NSString *) albumForFileAtPath:(NSString *) path {
	return nil;
}

+ (NSTimeInterval) durationForFileAtPath:(NSString *) path {
	return 0.;
}
@end
