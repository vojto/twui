#import "TUITableViewCell.h"

@interface TUITableViewCell ()

- (void)setFloating:(BOOL)f animated:(BOOL)animated display:(BOOL)display;

- (BOOL)canDrawHighlighted;
- (BOOL)canDrawSelected;

- (NSColor *)flatColorForStyle:(TUITableViewCellColorStyle)style;
- (NSColor *)coalescedColorForStyle:(TUITableViewCellColorStyle)style;

- (void)drawBackgroundWithStyle:(TUITableViewCellColorStyle)style
						  angle:(TUITableViewCellAngle)styleAngle
						  color:(NSColor *)color
				 alternateColor:(NSColor *)alternateColor
						 inRect:(CGRect)rect;

@end