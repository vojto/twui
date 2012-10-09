/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TUITableViewCell.h"
#import "TUINSWindow.h"
#import "TUITableView+Cell.h"
#import "TUICGAdditions.h"

#define TUI_CELL_IS_ALTERNATE (self.indexPath.row % 2)
#define TUI_CELL_ALTERNATE_BACKGROUND (self.alternateBackgroundColor && TUI_CELL_IS_ALTERNATE)
#define TUI_CELL_ALTERNATE_HIGHLIGHT (self.alternateHighlightColor && TUI_CELL_IS_ALTERNATE)
#define TUI_CELL_ALTERNATE_SELECTION (self.alternateSelectionColor && TUI_CELL_IS_ALTERNATE)

#define TUITableViewCellTopEtchColor			[NSColor colorWithCalibratedWhite:1.00 alpha:0.5f]
#define TUITableViewCellBottomEtchColor			[NSColor colorWithCalibratedWhite:0.75 alpha:0.5f]

#define TUITableViewCellDefaultBackgroundColor	[NSColor colorWithCalibratedWhite:0.95 alpha:1.0f]
#define TUITableViewCellDefaultHighlightedColor	[NSColor colorWithCalibratedWhite:0.85 alpha:1.0f]
#define TUITableViewCellDefaultSelectedColor	[NSColor colorWithCalibratedWhite:0.75 alpha:1.0f]

#define TUITableViewCellSelectedBlueTopColor	[NSColor colorWithCalibratedRed:0.33 green:0.68 blue:0.91 alpha:1.0f]
#define TUITableViewCellSelectedBlueBottomColor	[NSColor colorWithCalibratedRed:0.09 green:0.46 blue:0.78 alpha:1.0f]
#define TUITableViewCellSelectedGrayTopColor	[NSColor colorWithCalibratedWhite:0.60 alpha:1.0]
#define TUITableViewCellSelectedGrayBottomColor	[NSColor colorWithCalibratedWhite:0.45 alpha:1.0]

@implementation TUITableViewCell {
	CGPoint __mouseOffset;
	struct {
		unsigned int floating:1;
		unsigned int highlighted:1;
		unsigned int selected:1;
	} _tableViewCellFlags;
}

- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if((self = [super initWithFrame:CGRectZero])) {
		_style = style;
		_reuseIdentifier = [reuseIdentifier copy];
		
		self.indentationLevel = 0;
		self.indentationWidth = 10.0f;
		self.animatesHighlightChanges = NO;
		self.separatorStyle = TUITableViewCellSeparatorStyleEtched;
		
		self.backgroundColor = TUITableViewCellDefaultBackgroundColor;
		self.highlightColor = TUITableViewCellDefaultHighlightedColor;
		self.selectionColor = TUITableViewCellDefaultSelectedColor;
		
		self.alternateBackgroundColor = nil;
		self.alternateHighlightColor = nil;
		self.alternateSelectionColor = nil;
		
		self.backgroundStyle = TUITableViewCellColorStyleCustom;
		self.highlightStyle = TUITableViewCellColorStyleGray;
		self.selectionStyle = TUITableViewCellColorStyleBlue;
		
		self.backgroundCoalescenceAngle = TUITableViewCellCoalesceseAngleGradientUp;
		self.highlightCoalescenceAngle = TUITableViewCellCoalesceseAngleGradientUp;
		self.selectionCoalescenceAngle = TUITableViewCellCoalesceseAngleGradientUp;
		
		self.drawBackground = nil;
		self.drawHighlightedBackground = nil;
		self.drawSelectedBackground = nil;
		self.drawSeparators = nil;
	}
	
	return self;
}

- (void)prepareForReuse {
	[self removeAllAnimations];
	[self.textRenderers makeObjectsPerformSelector:@selector(resetSelection)];
	[self setNeedsDisplay];
}

- (void)prepareForDisplay {
	[self removeAllAnimations];
}

- (TUIView *)derepeaterView {
	return nil;
}

- (id)derepeaterIdentifier {
	return nil;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event {
	return NO;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (TUITableView *)tableView {
	return (TUITableView *)self.superview;
}

- (NSIndexPath *)indexPath {
	return [self.tableView indexPathForCell:self];
}

- (void)drawBackground:(CGRect)rect {
	if(self.backgroundStyle == TUITableViewCellColorStyleCustom)
		[TUI_CELL_ALTERNATE_BACKGROUND ? self.alternateBackgroundColor : self.backgroundColor set];
	else if(self.backgroundStyle == TUITableViewCellColorStyleBlue)
		[TUITableViewCellSelectedBlueTopColor set];
	else if(self.backgroundStyle == TUITableViewCellColorStyleGray)
		[TUITableViewCellSelectedGrayTopColor set];
	
	CGContextFillRect(TUIGraphicsGetCurrentContext(), rect);
}

- (void)drawHighlightedBackground:(CGRect)rect {
	if(self.highlightStyle == TUITableViewCellColorStyleCustom)
	[TUI_CELL_ALTERNATE_HIGHLIGHT ? self.alternateHighlightColor : self.highlightColor set];
	else if(self.highlightStyle == TUITableViewCellColorStyleBlue)
		[TUITableViewCellSelectedBlueTopColor set];
	else if(self.highlightStyle == TUITableViewCellColorStyleGray)
		[TUITableViewCellSelectedGrayTopColor set];
	
	CGContextFillRect(TUIGraphicsGetCurrentContext(), rect);
}

- (void)drawSelectedBackground:(CGRect)rect {
	if(self.selectionStyle == TUITableViewCellColorStyleCustom)
	[TUI_CELL_ALTERNATE_SELECTION ? self.alternateSelectionColor : self.selectionColor set];
	else if(self.selectionStyle == TUITableViewCellColorStyleBlue)
		[TUITableViewCellSelectedBlueTopColor set];
	else if(self.selectionStyle == TUITableViewCellColorStyleGray)
		[TUITableViewCellSelectedGrayTopColor set];
	
	CGContextFillRect(TUIGraphicsGetCurrentContext(), rect);
}

- (void)drawSeparators:(CGRect)rect {
	BOOL flipped = self.separatorStyle == TUITableViewCellSeparatorStyleEtchedReversed;
	
	if(self.separatorStyle != TUITableViewCellSeparatorStyleLine) {
		[flipped ? TUITableViewCellBottomEtchColor : TUITableViewCellTopEtchColor set];
		CGContextFillRect(TUIGraphicsGetCurrentContext(),
						  CGRectMake(0, rect.size.height-1, rect.size.width, 1));
	}
	
	// Default for TUITableViewCellSeparatorStyleEtched.
	[flipped ? TUITableViewCellTopEtchColor : TUITableViewCellBottomEtchColor set];
	CGContextFillRect(TUIGraphicsGetCurrentContext(),
					  CGRectMake(0, 0, rect.size.width, 1));
}

- (void)drawRect:(CGRect)rect {
	BOOL drawHighlighted = (self.highlightColor && self.highlightStyle != TUITableViewCellColorStyleNone);
	BOOL drawSelected = (self.selectionColor && self.selectionStyle != TUITableViewCellColorStyleNone);
	
	// Draw the appropriate background for the state of the cell.
	// If a block exists, then use the block instead of the method.
	if(self.highlighted && drawHighlighted) {
		if(self.drawHighlightedBackground)
			self.drawHighlightedBackground(self, self.bounds);
		else
			[self drawHighlightedBackground:self.bounds];
	} else if(self.selected && drawSelected) {
		if(self.drawSelectedBackground)
			self.drawSelectedBackground(self, self.bounds);
		else
			[self drawSelectedBackground:self.bounds];
	} else {
		if(self.drawBackground)
			self.drawBackground(self, self.bounds);
		else
			[self drawBackground:self.bounds];
	}
	
	// Draw the separators if the style dictates we are to draw them.
	// If a block exists, then use the block instead of the method.
	if(self.separatorStyle != TUITableViewCellSeparatorStyleNone) {
		if(self.drawSeparators)
			self.drawSeparators(self, self.bounds);
		else
			[self drawSeparators:self.bounds];
	}
}

- (void)mouseDown:(NSEvent *)event {
	// note the initial mouse location for dragging
	__mouseOffset = [self localPointForLocationInWindow:[event locationInWindow]];
	
	// notify our table view of the event
	[self.tableView __mouseDownInCell:self offset:__mouseOffset event:event];
	
	// may make the text renderer first responder, so we want to do the selection before this
	[super mouseDown:event];
	
	if(![self.tableView.delegate respondsToSelector:@selector(tableView:shouldSelectRowAtIndexPath:forEvent:)] ||
	   [self.tableView.delegate tableView:self.tableView shouldSelectRowAtIndexPath:self.indexPath forEvent:event]) {
		
		[self.tableView selectRowAtIndexPath:self.indexPath
									animated:self.tableView.animateSelectionChanges
							  scrollPosition:TUITableViewScrollPositionNone];
		
		[self setHighlighted:YES animated:self.animatesHighlightChanges];
	}
	
	if([self acceptsFirstResponder]) {
		[self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:self];
	}
}

// The table cell was dragged
- (void)mouseDragged:(NSEvent *)event {
	// propagate the event
	[super mouseDragged:event];
	// notify our table view of the event
	[self.tableView __mouseDraggedCell:self offset:__mouseOffset event:event];
}

- (void)mouseUp:(NSEvent *)event {
	[super mouseUp:event];
	// notify our table view of the event
	[self.tableView __mouseUpInCell:self offset:__mouseOffset event:event];
	
	[self setHighlighted:NO animated:self.animatesHighlightChanges];
	
	if([self eventInside:event]) {
		TUITableView *tableView = self.tableView;
		if([tableView.delegate respondsToSelector:@selector(tableView:didClickRowAtIndexPath:withEvent:)]){
			[tableView.delegate tableView:tableView didClickRowAtIndexPath:self.indexPath withEvent:event];
		}
	}
}

- (void)rightMouseDown:(NSEvent *)event{
	[super rightMouseDown:event];
	
	TUITableView *tableView = self.tableView;
	if(![tableView.delegate respondsToSelector:@selector(tableView:shouldSelectRowAtIndexPath:forEvent:)] ||
	   [tableView.delegate tableView:tableView shouldSelectRowAtIndexPath:self.indexPath forEvent:event]) {
		
		[tableView selectRowAtIndexPath:self.indexPath
							   animated:tableView.animateSelectionChanges
						 scrollPosition:TUITableViewScrollPositionNone];
		
		[self setHighlighted:YES animated:self.animatesHighlightChanges];
	}
}

- (void)rightMouseUp:(NSEvent *)event{
	[super rightMouseUp:event];
	[self setHighlighted:NO animated:self.animatesHighlightChanges];
	
	if([self eventInside:event]) {
		TUITableView *tableView = self.tableView;
		if([tableView.delegate respondsToSelector:@selector(tableView:didClickRowAtIndexPath:withEvent:)]){
			[tableView.delegate tableView:tableView didClickRowAtIndexPath:self.indexPath withEvent:event];
		}
	}	
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
	if([self.tableView.delegate respondsToSelector:@selector(tableView:menuForRowAtIndexPath:withEvent:)]) {
		return [self.tableView.delegate tableView:self.tableView menuForRowAtIndexPath:self.indexPath withEvent:event];
	} else {
		return [super menuForEvent:event];
	}
}

- (BOOL)isFloating {
	return _tableViewCellFlags.floating;
}

- (void)setFloating:(BOOL)f animated:(BOOL)animated display:(BOOL)display {
	if(animated) {
		[TUIView beginAnimations:NSStringFromSelector(_cmd) context:nil];
	}
	
	_tableViewCellFlags.floating = f;
	
	if(animated) {
		[self redraw];
		[TUIView commitAnimations];
	} else if(display) {
		[self setNeedsDisplay];
	}
}

- (BOOL)isHighlighted {
	return _tableViewCellFlags.highlighted;
}

- (void)setHighlighted:(BOOL)h {
	[self setHighlighted:h animated:NO];
}

- (void)setHighlighted:(BOOL)h animated:(BOOL)animated {
	if(animated) {
		[TUIView beginAnimations:NSStringFromSelector(_cmd) context:nil];
	}
	
	_tableViewCellFlags.highlighted = h;
	
	if(animated) {
		[self redraw];
		[TUIView commitAnimations];
	} else {
		[self setNeedsDisplay];
	}
}

- (BOOL)isSelected {
	return _tableViewCellFlags.selected;
}

- (void)setSelected:(BOOL)s {
	[self setSelected:s animated:NO];
}

- (void)setSelected:(BOOL)s animated:(BOOL)animated {
	if(animated) {
		[TUIView beginAnimations:NSStringFromSelector(_cmd) context:nil];
	}
	
	_tableViewCellFlags.selected = s;
	
	if(animated) {
		[self redraw];
		[TUIView commitAnimations];
	} else {
		[self setNeedsDisplay];
	}
}

- (void)setSeparatorStyle:(TUITableViewCellSeparatorStyle)separatorStyle {
	_separatorStyle = separatorStyle;
	[self setNeedsDisplay];
}

- (void)setBackgroundStyle:(TUITableViewCellColorStyle)style {
	_backgroundStyle = style;
	[self setNeedsDisplay];
}

- (void)setHighlightStyle:(TUITableViewCellColorStyle)style {
	_highlightStyle = style;
	[self setNeedsDisplay];
}

- (void)setSelectionStyle:(TUITableViewCellColorStyle)style {
	_selectionStyle = style;
	[self setNeedsDisplay];
}

- (void)setBackgroundCoalescenceAngle:(CGFloat)coalescenceAngle {
	_backgroundCoalescenceAngle = coalescenceAngle;
	[self setNeedsDisplay];
}

- (void)setHighlightCoalescenceAngle:(CGFloat)coalescenceAngle {
	_highlightCoalescenceAngle = coalescenceAngle;
	[self setNeedsDisplay];
}

- (void)setSelectionCoalescenceAngle:(CGFloat)coalescenceAngle {
	_selectionCoalescenceAngle = coalescenceAngle;
	[self setNeedsDisplay];
}

- (void)setHighlightColor:(NSColor *)highlightColor {
	_highlightColor = highlightColor;
	[self setNeedsDisplay];
}

- (void)setSelectionColor:(NSColor *)selectionColor {
	_selectionColor = selectionColor;
	[self setNeedsDisplay];
}

- (void)setAlternateBackgroundColor:(NSColor *)alternateColor {
	_alternateBackgroundColor = alternateColor;
	[self setNeedsDisplay];
}

- (void)setAlternateHighlightColor:(NSColor *)alternateColor {
	_alternateHighlightColor = alternateColor;
	[self setNeedsDisplay];
}

- (void)setAlternateSelectionColor:(NSColor *)alternateColor {
	_alternateSelectionColor = alternateColor;
	[self setNeedsDisplay];
}

@end
