#import "ExampleSectionHeaderView.h"

@implementation ExampleSectionHeaderView

@synthesize labelRenderer = _labelRenderer;

/**
 * Clean up
 */

/**
 * Initialize
 */
-(id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		_labelRenderer = [[TUITextRenderer alloc] init];
		self.textRenderers = [NSArray arrayWithObjects:_labelRenderer, nil];
		self.opaque = TRUE;
	}
	return self;
}

/**
 * @brief The header will become pinned
 */
-(void)headerWillBecomePinned {
  self.opaque = FALSE;
  [super headerWillBecomePinned];
}

/**
 * @brief The header will become unpinned
 */
-(void)headerWillBecomeUnpinned {
  self.opaque = TRUE;
  [super headerWillBecomeUnpinned];
}

/**
 * Drawing
 */
-(void)drawRect:(CGRect)rect {
  
  CGContextRef g;
  if((g = TUIGraphicsGetCurrentContext()) != nil){
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:g flipped:FALSE]];
    
    if(!self.pinnedToViewport){
      [[NSColor whiteColor] set];
      NSRectFill(self.bounds);
    }
    
    NSColor *start = [NSColor colorWithCalibratedRed:0.1 green:0.1 blue:0.1 alpha:1.0];
    NSColor *end = [NSColor colorWithCalibratedRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    NSGradient *gradient = nil;
    
    gradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
    [gradient drawInRect:self.bounds angle:90];
    
    [[start shadowWithLevel:0.1] set];
    NSRectFill(NSMakeRect(0, 0, self.bounds.size.width, 1));
    
    CGFloat labelHeight = 18;
    self.labelRenderer.frame = CGRectMake(15, roundf((self.bounds.size.height - labelHeight) / 2.0), self.bounds.size.width - 30, labelHeight);
    [self.labelRenderer draw];
    
  }
  
}

@end
