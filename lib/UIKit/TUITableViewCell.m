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

#import "TUITableViewCell+Private.h"
#import "TUINSWindow.h"
#import "TUITableView+Cell.h"
#import "TUICGAdditions.h"

#define TUI_CELL_IS_PRESET_COLOR(s)	\
((s == TUITableViewCellColorStyleBlue) || \
(s == TUITableViewCellColorStyleGraphite) || \
(s == TUITableViewCellColorStyleGray))

#define TUI_CELL_IS_COALESCED_COLOR(s) \
((!TUI_CELL_IS_PRESET_COLOR(s)) && \
(s != TUITableViewCellColorStyleNone) && \
(s != TUITableViewCellColorStyleCoalescedWithAlternates))

#define TUITableViewCellEtchTopColor		[NSColor colorWithCalibratedWhite:1.00f alpha:0.80f]
#define TUITableViewCellEtchBottomColor		[NSColor colorWithCalibratedWhite:0.00f alpha:0.20f]
#define TUITableViewCellBlueTopColor		[NSColor colorWithCalibratedRed:0.33 green:0.68 blue:0.91 alpha:1.00]
#define TUITableViewCellBlueBottomColor		[NSColor colorWithCalibratedRed:0.09 green:0.46 blue:0.78 alpha:1.00]
#define TUITableViewCellGraphiteTopColor	[NSColor colorWithCalibratedRed:0.68 green:0.74 blue:0.85 alpha:1.00]
#define TUITableViewCellGraphiteBottomColor	[NSColor colorWithCalibratedRed:0.50 green:0.58 blue:0.73 alpha:1.00]
#define TUITableViewCellGrayTopColor		[NSColor colorWithCalibratedWhite:0.60 alpha:1.00]
#define TUITableViewCellGrayBottomColor		[NSColor colorWithCalibratedWhite:0.45 alpha:1.00]

#define TUI_CELL_REFRESH_DRAWING			tui_viewAnimateRedrawConditionally(self, self.animatesAppearanceChanges)
static inline void tui_viewAnimateRedrawConditionally(TUIView *view, BOOL condition) {
	if(condition) {
		[TUIView animateWithDuration:0.25 animations:^{
			[view redraw];
		}];
	} else [view setNeedsDisplay];
}

@implementation TUITableViewCell {
	CGPoint _mouseOffset;
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
		
		self.animatesAppearanceChanges = YES;
		self.separatorStyle = TUITableViewCellSeparatorStyleEtched;
		
		self.backgroundColor = [NSColor colorWithCalibratedWhite:0.95 alpha:1.0f];
		self.highlightColor = [NSColor colorWithCalibratedWhite:0.85 alpha:1.0f];
		self.selectionColor = [NSColor colorWithCalibratedWhite:0.75 alpha:1.0f];
		
		self.alternateBackgroundColor = nil;
		self.alternateHighlightColor = nil;
		self.alternateSelectionColor = nil;
		
		self.backgroundStyle = TUITableViewCellColorStyleNone;
		self.highlightStyle = TUITableViewCellColorStyleNone;
		self.selectionStyle = TUITableViewCellColorStyleCoalescedBackgroundToHighlight;
		
		self.backgroundAngle = CGFLOAT_UNDEFINED;
		self.highlightAngle = CGFLOAT_UNDEFINED;
		self.selectionAngle = 90.0f;
		
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

- (void)drawBackgroundWithStyle:(TUITableViewCellColorStyle)style
						  angle:(CGFloat)styleAngle
						  color:(NSColor *)color
				 alternateColor:(NSColor *)alternateColor
						 inRect:(CGRect)rect {
	
	// Resolve gradient angle first, even if drawing flat.
	// We can still check the original against no angle cases.
	CGFloat angle = (styleAngle > 360.0f ? 360 : (styleAngle < -360.0f ? - 360.0f : styleAngle));
	
	// Resolve drawing in order: preset flat, preset coalesced,
	// coalesced, coalesced alternates, custom/none.
	if(TUI_CELL_IS_PRESET_COLOR(style)) {
		if(styleAngle == CGFLOAT_UNDEFINED) {
			
			// Preset color drawn flat.
			[[self flatColorForStyle:style] set];
			CGContextFillRect(TUIGraphicsGetCurrentContext(), rect);
		} else {
			
			// Preset color drawn coalesced.
			NSColor *flatColor = [self flatColorForStyle:style];
			NSColor *coalescedColor = [self coalescedColorForStyle:style];
			[[[NSGradient alloc] initWithColors:@[flatColor, coalescedColor]] drawInRect:rect angle:angle];
		}
	} else if(TUI_CELL_IS_COALESCED_COLOR(style)) {
		
		// Coalesced state colors drawn coalesced.
		NSColor *flatColor = [self flatColorForStyle:style];
		NSColor *coalescedColor = [self coalescedColorForStyle:style];
		[[[NSGradient alloc] initWithColors:@[flatColor, coalescedColor]] drawInRect:rect angle:angle];
	} else if(style == TUITableViewCellColorStyleCoalescedWithAlternates && alternateColor) {
		
		// Coalesced alternative colors drawn coalesced.
		[[[NSGradient alloc] initWithColors:@[color, alternateColor]] drawInRect:rect angle:angle];
	} else {
		
		// TUITableViewCellColorStyleNone defaulted.
		BOOL alternated = (alternateColor && (self.indexPath.row % 2));
		[alternated ? alternateColor : color set];
		CGContextFillRect(TUIGraphicsGetCurrentContext(), rect);
	}
}

- (void)drawSeparators:(CGRect)rect {
	BOOL flipped = self.separatorStyle == TUITableViewCellSeparatorStyleEtchedReversed;
	
	if(self.separatorStyle != TUITableViewCellSeparatorStyleLine) {
		[flipped ? TUITableViewCellEtchBottomColor : TUITableViewCellEtchTopColor set];
		CGContextFillRect(TUIGraphicsGetCurrentContext(),
						  CGRectMake(0, rect.size.height-1, rect.size.width, 1));
	}
	
	// Default for TUITableViewCellSeparatorStyleEtched.
	[flipped ? TUITableViewCellEtchTopColor : TUITableViewCellEtchBottomColor set];
	CGContextFillRect(TUIGraphicsGetCurrentContext(),
					  CGRectMake(0, 0, rect.size.width, 1));
}

- (void)drawBackground:(CGRect)rect {
	
	[self drawBackgroundWithStyle:self.backgroundStyle
							angle:self.backgroundAngle
							color:self.backgroundColor
				   alternateColor:self.alternateBackgroundColor
						   inRect:rect];
}

- (void)drawHighlightedBackground:(CGRect)rect {
	if(!self.canDrawHighlighted)
		return;
	
	[self drawBackgroundWithStyle:self.highlightStyle
							angle:self.highlightAngle
							color:self.highlightColor
				   alternateColor:self.alternateHighlightColor
						   inRect:rect];
}

- (void)drawSelectedBackground:(CGRect)rect {
	if(!self.canDrawSelected)
		return;
	
	[self drawBackgroundWithStyle:self.selectionStyle
							angle:self.selectionAngle
							color:self.selectionColor
				   alternateColor:self.alternateSelectionColor
						   inRect:rect];
}

- (void)drawRect:(CGRect)rect {
	
	// Draw the appropriate background for the state of the cell.
	// If a block exists, then use the block instead of the method.
	if(self.highlighted) {
		if(self.drawHighlightedBackground)
			self.drawHighlightedBackground(self, self.bounds);
		else
			[self drawHighlightedBackground:self.bounds];
	} else if(self.selected) {
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

- (BOOL)canDrawHighlighted {
	if(self.highlightStyle == TUITableViewCellColorStyleNone ||
	   self.highlightStyle == TUITableViewCellColorStyleCoalescedBackgroundToHighlight ||
	   self.highlightStyle == TUITableViewCellColorStyleCoalescedHighlightToSelection) {
		return (self.highlightColor != nil);
	} else if(self.highlightStyle == TUITableViewCellColorStyleCoalescedWithAlternates) {
		return (self.highlightColor != nil && self.alternateHighlightColor != nil);
	} else return NO;
}

- (BOOL)canDrawSelected {
	if(self.selectionStyle == TUITableViewCellColorStyleNone ||
	   self.selectionStyle == TUITableViewCellColorStyleCoalescedBackgroundToHighlight ||
	   self.selectionStyle == TUITableViewCellColorStyleCoalescedHighlightToSelection) {
		return (self.selectionColor != nil);
	} else if(self.selectionStyle == TUITableViewCellColorStyleCoalescedWithAlternates) {
		return (self.selectionColor != nil && self.alternateSelectionColor != nil);
	} else return NO;
}

- (NSColor *)flatColorForStyle:(TUITableViewCellColorStyle)style {
	if(style == TUITableViewCellColorStyleBlue)
		return TUITableViewCellBlueTopColor;
	else if(style == TUITableViewCellColorStyleGraphite)
		return TUITableViewCellGraphiteTopColor;
	else if(style == TUITableViewCellColorStyleGray)
		return TUITableViewCellGrayTopColor;
	else if(style == TUITableViewCellColorStyleCoalescedBackgroundToHighlight)
		return self.backgroundColor;
	else if(style == TUITableViewCellColorStyleCoalescedHighlightToSelection)
		return self.highlightColor;
	else if(style == TUITableViewCellColorStyleCoalescedSelectionToBackground)
		return self.selectionColor;
	else return nil;
}

- (NSColor *)coalescedColorForStyle:(TUITableViewCellColorStyle)style {
	if(style == TUITableViewCellColorStyleBlue)
		return TUITableViewCellBlueBottomColor;
	else if(style == TUITableViewCellColorStyleGraphite)
		return TUITableViewCellGraphiteBottomColor;
	else if(style == TUITableViewCellColorStyleGray)
		return TUITableViewCellGrayBottomColor;
	else if(style == TUITableViewCellColorStyleCoalescedBackgroundToHighlight)
		return self.highlightColor;
	else if(style == TUITableViewCellColorStyleCoalescedHighlightToSelection)
		return self.selectionColor;
	else if(style == TUITableViewCellColorStyleCoalescedSelectionToBackground)
		return self.backgroundColor;
	else return nil;
}

- (void)mouseDown:(NSEvent *)event {
	
	// Note the initial mouse location to determine dragging,
	// and notify the table view we were dragged.
	_mouseOffset = [self localPointForLocationInWindow:[event locationInWindow]];
	[self.tableView __mouseDownInCell:self offset:_mouseOffset event:event];
	
	// May make text renderers become first responder so we
	// notify the table view earlier to avoid this.
	[super mouseDown:event];
	
	// We were pressed down, and are still tracking, so we are highlighted.
	[self setHighlighted:YES animated:self.animatesAppearanceChanges];
	
	if([self acceptsFirstResponder]) {
		[self.nsWindow makeFirstResponderIfNotAlreadyInResponderChain:self];
	}
}

- (void)mouseDragged:(NSEvent *)event {
	[super mouseDragged:event];
	
	// Notify the table view of the drag event.
	[self.tableView __mouseDraggedCell:self offset:_mouseOffset event:event];
}

- (void)mouseUp:(NSEvent *)event {
	[super mouseUp:event];
	
	// Notify the table view of the mouse up event.
	[self.tableView __mouseUpInCell:self offset:_mouseOffset event:event];
	
	// We were selected, so we are no longer highlighted.
	[self setHighlighted:NO animated:self.animatesAppearanceChanges];
	
	// If the table view delegate supports it, we will be selected.
	if(![self.tableView.delegate respondsToSelector:@selector(tableView:shouldSelectRowAtIndexPath:forEvent:)] ||
	   [self.tableView.delegate tableView:self.tableView shouldSelectRowAtIndexPath:self.indexPath forEvent:event]) {
		
		[self.tableView selectRowAtIndexPath:self.indexPath
									animated:self.animatesAppearanceChanges
							  scrollPosition:TUITableViewScrollPositionNone];
	}
	
	// Notify the delegate of the table view we were clicked.
	if([self eventInside:event]) {
		TUITableView *tableView = self.tableView;
		if([tableView.delegate respondsToSelector:@selector(tableView:didClickRowAtIndexPath:withEvent:)]){
			[tableView.delegate tableView:tableView didClickRowAtIndexPath:self.indexPath withEvent:event];
		}
	}
}

- (void)rightMouseDown:(NSEvent *)event{
	[super rightMouseDown:event];
	
	// We were pressed down, and are still tracking, so we are highlighted.
	[self setHighlighted:YES animated:self.animatesAppearanceChanges];
}

- (void)rightMouseUp:(NSEvent *)event{
	[super rightMouseUp:event];
	
	// We were selected, so we are no longer highlighted.
	[self setHighlighted:NO animated:self.animatesAppearanceChanges];
	
	// If the table view delegate supports it, we will be selected.
	TUITableView *tableView = self.tableView;
	if(![tableView.delegate respondsToSelector:@selector(tableView:shouldSelectRowAtIndexPath:forEvent:)] ||
	   [tableView.delegate tableView:tableView shouldSelectRowAtIndexPath:self.indexPath forEvent:event]) {
		
		[tableView selectRowAtIndexPath:self.indexPath
							   animated:self.animatesAppearanceChanges
						 scrollPosition:TUITableViewScrollPositionNone];
	}
	
	// Notify the delegate of the table view we were clicked.
	if([self eventInside:event]) {
		TUITableView *tableView = self.tableView;
		if([tableView.delegate respondsToSelector:@selector(tableView:didClickRowAtIndexPath:withEvent:)]){
			[tableView.delegate tableView:tableView didClickRowAtIndexPath:self.indexPath withEvent:event];
		}
	}	
}

// Retrieve the delegate's menu for an event if there is one.
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
	_tableViewCellFlags.floating = f;
	
	if(display) {
		tui_viewAnimateRedrawConditionally(self, animated);
	}
}

- (BOOL)isHighlighted {
	return _tableViewCellFlags.highlighted;
}

- (void)setHighlighted:(BOOL)h {
	[self setHighlighted:h animated:self.animatesAppearanceChanges];
}

- (void)setHighlighted:(BOOL)h animated:(BOOL)animated {
	_tableViewCellFlags.highlighted = h;
	tui_viewAnimateRedrawConditionally(self, animated);
}

- (BOOL)isSelected {
	return _tableViewCellFlags.selected;
}

- (void)setSelected:(BOOL)s {
	[self setSelected:s animated:self.animatesAppearanceChanges];
}

- (void)setSelected:(BOOL)s animated:(BOOL)animated {
	_tableViewCellFlags.selected = s;
	tui_viewAnimateRedrawConditionally(self, animated);
}

- (void)setSeparatorStyle:(TUITableViewCellSeparatorStyle)separatorStyle {
	_separatorStyle = separatorStyle;
	TUI_CELL_REFRESH_DRAWING;
}

- (void)setBackgroundStyle:(TUITableViewCellColorStyle)style {
	_backgroundStyle = style;
	TUI_CELL_REFRESH_DRAWING;
}

- (void)setHighlightStyle:(TUITableViewCellColorStyle)style {
	_highlightStyle = style;
	TUI_CELL_REFRESH_DRAWING;
}

- (void)setSelectionStyle:(TUITableViewCellColorStyle)style {
	_selectionStyle = style;
	TUI_CELL_REFRESH_DRAWING;
}

- (void)setBackgroundAngle:(CGFloat)angle {
	_backgroundAngle = angle;
	TUI_CELL_REFRESH_DRAWING;
}

- (void)setHighlightAngle:(CGFloat)angle {
	_highlightAngle = angle;
	TUI_CELL_REFRESH_DRAWING;
}

- (void)setSelectionAngle:(CGFloat)angle {
	_selectionAngle = angle;
	TUI_CELL_REFRESH_DRAWING;
}

- (void)setHighlightColor:(NSColor *)highlightColor {
	_highlightColor = highlightColor;
	TUI_CELL_REFRESH_DRAWING;
}

- (void)setSelectionColor:(NSColor *)selectionColor {
	_selectionColor = selectionColor;
	TUI_CELL_REFRESH_DRAWING;
}

- (void)setAlternateBackgroundColor:(NSColor *)alternateColor {
	_alternateBackgroundColor = alternateColor;
	TUI_CELL_REFRESH_DRAWING;
}

- (void)setAlternateHighlightColor:(NSColor *)alternateColor {
	_alternateHighlightColor = alternateColor;
	TUI_CELL_REFRESH_DRAWING;
}

- (void)setAlternateSelectionColor:(NSColor *)alternateColor {
	_alternateSelectionColor = alternateColor;
	TUI_CELL_REFRESH_DRAWING;
}

@end
