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
		self.animatesStyleChanges = YES;
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
		
		self.backgroundAngle = TUITableViewCellAngleNone;
		self.highlightAngle = TUITableViewCellAngleNone;
		self.selectionAngle = TUITableViewCellAngleUp;
		
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
	
	// Resolve gradient angle first, even if drawing flat.
	// We can still check the original against no angle cases.
	TUITableViewCellAngle angle = self.backgroundAngle;
	if(angle > 360.0f)
		angle = 360.0f;
	else if(angle < -360.0f)
		angle = -360.0f;
	
	// Resolve drawing in order: preset flat, preset coalesced,
	// coalesced, coalesced alternates, custom/none.
	if(TUI_CELL_IS_PRESET_COLOR(self.backgroundStyle)) {
		if(self.backgroundAngle == TUITableViewCellAngleNone) {
			
			// Preset color drawn flat.
			[[self flatColorForStyle:self.backgroundStyle] set];
			CGContextFillRect(TUIGraphicsGetCurrentContext(), rect);
		} else {
			
			// Preset color drawn coalesced.
			NSColor *flatColor = [self flatColorForStyle:self.backgroundStyle];
			NSColor *coalescedColor = [self coalescedColorForStyle:self.backgroundStyle];
			[[[NSGradient alloc] initWithColors:@[flatColor, coalescedColor]] drawInRect:rect angle:angle];
		}
	} else if(TUI_CELL_IS_COALESCED_COLOR(self.backgroundStyle)) {
		
		// Coalesced state colors drawn coalesced.
		NSColor *flatColor = [self flatColorForStyle:self.backgroundStyle];
		NSColor *coalescedColor = [self coalescedColorForStyle:self.backgroundStyle];
		[[[NSGradient alloc] initWithColors:@[flatColor, coalescedColor]] drawInRect:rect angle:angle];
	} else if(self.backgroundStyle == TUITableViewCellColorStyleCoalescedWithAlternates && self.alternateBackgroundColor) {
		
		// Coalesced alternative colors drawn coalesced.
		NSColor *flatColor = self.backgroundColor;
		NSColor *coalescedColor = self.alternateBackgroundColor;
		[[[NSGradient alloc] initWithColors:@[flatColor, coalescedColor]] drawInRect:rect angle:angle];
	} else {
		
		// TUITableViewCellColorStyleNone defaulted.
		BOOL alternated = (self.alternateBackgroundColor && (self.indexPath.row % 2));
		[alternated ? self.alternateBackgroundColor : self.backgroundColor set];
		CGContextFillRect(TUIGraphicsGetCurrentContext(), rect);
	}
}

- (void)drawHighlightedBackground:(CGRect)rect {
	if(!self.canDrawHighlighted)
		return;
	
	// Resolve gradient angle first, even if drawing flat.
	// We can still check the original against no angle cases.
	TUITableViewCellAngle angle = self.highlightAngle;
	if(angle > 360.0f)
		angle = 360.0f;
	else if(angle < -360.0f)
		angle = -360.0f;
	
	// Resolve drawing in order: preset flat, preset coalesced,
	// coalesced, coalesced alternates, custom/none.
	if(TUI_CELL_IS_PRESET_COLOR(self.highlightStyle)) {
		if(self.highlightAngle == TUITableViewCellAngleNone) {
			
			// Preset color drawn flat.
			[[self flatColorForStyle:self.highlightStyle] set];
			CGContextFillRect(TUIGraphicsGetCurrentContext(), rect);
		} else {
			
			// Preset color drawn coalesced.
			NSColor *flatColor = [self flatColorForStyle:self.highlightStyle];
			NSColor *coalescedColor = [self coalescedColorForStyle:self.highlightStyle];
			[[[NSGradient alloc] initWithColors:@[flatColor, coalescedColor]] drawInRect:rect angle:angle];
		}
	} else if(TUI_CELL_IS_COALESCED_COLOR(self.highlightStyle)) {
		
		// Coalesced state colors drawn coalesced.
		NSColor *flatColor = [self flatColorForStyle:self.highlightStyle];
		NSColor *coalescedColor = [self coalescedColorForStyle:self.highlightStyle];
		[[[NSGradient alloc] initWithColors:@[flatColor, coalescedColor]] drawInRect:rect angle:angle];
	} else if(self.highlightStyle == TUITableViewCellColorStyleCoalescedWithAlternates && self.alternateHighlightColor) {
		
		// Coalesced alternative colors drawn coalesced.
		NSColor *flatColor = self.highlightColor;
		NSColor *coalescedColor = self.alternateHighlightColor;
		[[[NSGradient alloc] initWithColors:@[flatColor, coalescedColor]] drawInRect:rect angle:angle];
	} else {
		
		// TUITableViewCellColorStyleNone defaulted.
		BOOL alternated = (self.alternateHighlightColor && (self.indexPath.row % 2));
		[alternated ? self.alternateHighlightColor : self.highlightColor set];
		CGContextFillRect(TUIGraphicsGetCurrentContext(), rect);
	}
}

- (void)drawSelectedBackground:(CGRect)rect {
	if(!self.canDrawSelected)
		return;
	
	// Resolve gradient angle first, even if drawing flat.
	// We can still check the original against no angle cases.
	TUITableViewCellAngle angle = self.selectionAngle;
	if(angle > 360.0f)
		angle = 360.0f;
	else if(angle < -360.0f)
		angle = -360.0f;
	
	// Resolve drawing in order: preset flat, preset coalesced,
	// coalesced, coalesced alternates, custom/none.
	if(TUI_CELL_IS_PRESET_COLOR(self.selectionStyle)) {
		if(self.selectionAngle == TUITableViewCellAngleNone) {
			
			// Preset color drawn flat.
			[[self flatColorForStyle:self.selectionStyle] set];
			CGContextFillRect(TUIGraphicsGetCurrentContext(), rect);
		} else {
			
			// Preset color drawn coalesced.
			NSColor *flatColor = [self flatColorForStyle:self.selectionStyle];
			NSColor *coalescedColor = [self coalescedColorForStyle:self.selectionStyle];
			[[[NSGradient alloc] initWithColors:@[flatColor, coalescedColor]] drawInRect:rect angle:angle];
		}
	} else if(TUI_CELL_IS_COALESCED_COLOR(self.selectionStyle)) {
		
		// Coalesced state colors drawn coalesced.
		NSColor *flatColor = [self flatColorForStyle:self.selectionStyle];
		NSColor *coalescedColor = [self coalescedColorForStyle:self.selectionStyle];
		[[[NSGradient alloc] initWithColors:@[flatColor, coalescedColor]] drawInRect:rect angle:angle];
	} else if(self.selectionStyle == TUITableViewCellColorStyleCoalescedWithAlternates && self.alternateSelectionColor) {
		
		// Coalesced alternative colors drawn coalesced.
		NSColor *flatColor = self.selectionColor;
		NSColor *coalescedColor = self.alternateSelectionColor;
		[[[NSGradient alloc] initWithColors:@[flatColor, coalescedColor]] drawInRect:rect angle:angle];
	} else {
		
		// TUITableViewCellColorStyleNone defaulted.
		BOOL alternated = (self.alternateSelectionColor && (self.indexPath.row % 2));
		[alternated ? self.alternateSelectionColor : self.selectionColor set];
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

- (void)drawRect:(CGRect)rect {
	
	// Draw the appropriate background for the state of the cell.
	// If a block exists, then use the block instead of the method.
	if(self.highlighted) {
		if(self.drawHighlightedBackground)
			self.drawHighlightedBackground(self, self.bounds);
		else 	[self drawHighlightedBackground:self.bounds];
	} else if(self.selected) {
		if(self.drawSelectedBackground)
			self.drawSelectedBackground(self, self.bounds);
		else 	[self drawSelectedBackground:self.bounds];
	} else {
		if(self.drawBackground)
			self.drawBackground(self, self.bounds);
		else 	[self drawBackground:self.bounds];
	}
	
	// Draw the separators if the style dictates we are to draw them.
	// If a block exists, then use the block instead of the method.
	if(self.separatorStyle != TUITableViewCellSeparatorStyleNone) {
		if(self.drawSeparators)
			self.drawSeparators(self, self.bounds);
		else 	[self drawSeparators:self.bounds];
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
		
		[self setHighlighted:YES animated:self.animatesStyleChanges];
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
	
	[self setHighlighted:NO animated:self.animatesStyleChanges];
	
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
		
		[self setHighlighted:YES animated:self.animatesStyleChanges];
	}
}

- (void)rightMouseUp:(NSEvent *)event{
	[super rightMouseUp:event];
	[self setHighlighted:NO animated:self.animatesStyleChanges];
	
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
	_tableViewCellFlags.floating = f;
	
	if(animated)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (BOOL)isHighlighted {
	return _tableViewCellFlags.highlighted;
}

- (void)setHighlighted:(BOOL)h {
	[self setHighlighted:h animated:NO];
}

- (void)setHighlighted:(BOOL)h animated:(BOOL)animated {
	_tableViewCellFlags.highlighted = h;
	
	if(animated)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (BOOL)isSelected {
	return _tableViewCellFlags.selected;
}

- (void)setSelected:(BOOL)s {
	[self setSelected:s animated:NO];
}

- (void)setSelected:(BOOL)s animated:(BOOL)animated {
	_tableViewCellFlags.selected = s;
	
	if(animated)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setSeparatorStyle:(TUITableViewCellSeparatorStyle)separatorStyle {
	_separatorStyle = separatorStyle;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setBackgroundStyle:(TUITableViewCellColorStyle)style {
	_backgroundStyle = style;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setHighlightStyle:(TUITableViewCellColorStyle)style {
	_highlightStyle = style;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setSelectionStyle:(TUITableViewCellColorStyle)style {
	_selectionStyle = style;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setBackgroundAngle:(TUITableViewCellAngle)angle {
	_backgroundAngle = angle;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setHighlightAngle:(TUITableViewCellAngle)angle {
	_highlightAngle = angle;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setSelectionAngle:(TUITableViewCellAngle)angle {
	_selectionAngle = angle;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setHighlightColor:(NSColor *)highlightColor {
	_highlightColor = highlightColor;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setSelectionColor:(NSColor *)selectionColor {
	_selectionColor = selectionColor;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setAlternateBackgroundColor:(NSColor *)alternateColor {
	_alternateBackgroundColor = alternateColor;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setAlternateHighlightColor:(NSColor *)alternateColor {
	_alternateHighlightColor = alternateColor;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

- (void)setAlternateSelectionColor:(NSColor *)alternateColor {
	_alternateSelectionColor = alternateColor;
	
	if(self.animatesStyleChanges)
		[TUIView animateWithDuration:0.25 animations:^{
			[self redraw];
		}];
	else [self setNeedsDisplay];
}

@end
