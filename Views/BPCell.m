#import "BPCell.h"

@implementation BPCell
- (void) drawInteriorWithFrame:(NSRect) cellFrame inView:(NSView *) controlView {
	cellFrame.origin.x += 6.;
    cellFrame.origin.y += (cellFrame.size.height - self.cellSize.height) / 2.;
    cellFrame.size.height = self.cellSize.height;

	NSAttributedString *drawString = self.attributedStringValue;

	NSDictionary *attributes = [drawString attributesAtIndex:0 effectiveRange:NULL];

	if (cellFrame.size.width < drawString.size.width)
		for (NSUInteger i = 0; i <= drawString.length; i++)
			if ([drawString attributedSubstringFromRange:NSMakeRange(0, i)].size.width >= cellFrame.size.width)
				 drawString = [[NSMutableAttributedString alloc] initWithString:[[drawString attributedSubstringFromRange:NSMakeRange(0, i - 3)].string stringByAppendingString:@"..."] attributes:attributes];

	[drawString drawInRect:cellFrame];
}
@end
