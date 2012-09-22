#import "TUITextRenderer.h"

@interface TUITextRenderer ()

- (CTFramesetterRef)ctFramesetter;
- (CTFrameRef)ctFrame;
- (CGPathRef)ctPath;
- (CFRange)_selectedRange;

@end
