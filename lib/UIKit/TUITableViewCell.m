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

#define TUITableViewCellTopEtchColor			[NSColor colorWithCalibratedWhite:1.00 alpha:1.0f]
#define TUITableViewCellBottomEtchColor			[NSColor colorWithCalibratedWhite:0.75 alpha:1.0f]
#define TUITableViewCellSelectedBlueTopColor	[NSColor colorWithCalibratedRed:0.33 green:0.68 blue:0.91 alpha:1.0f]
#define TUITableViewCellSelectedBlueBottomColor	[NSColor colorWithCalibratedRed:0.09 green:0.46 blue:0.78 alpha:1.0f]
#define TUITableViewCellSelectedGrayTopColor	[NSColor colorWithCalibratedWhite:0.60 alpha:1.0]
#define TUITableViewCellSelectedGrayBottomColor	[NSColor colorWithCalibratedWhite:0.45 alpha:1.0]

@implementation TUITableViewCell {
	CGPoint __mouseOffset;
	struct {
		unsigned int highlighted:1;
		unsigned int selected:1;
	} _tableViewCellFlags;
}

- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if((self = [super initWithFrame:CGRectZero])) {
		_style = style;
		_reuseIdentifier = [reuseIdentifier copy];
		
		self.indentationWidth = 10.0f;
		self.indentationLevel = 0;
		
		self.seperatorStyle = TUITableViewCellSeparatorStyleEtched;
		self.selectionStyle = TUITableViewCellSelectionStyleAutomatic;
		self.drawingStyle = TUITableViewCellDrawingStyleGradientUp;
		
		self.backgroundColor = [NSColor colorWithCalibratedWhite:0.95 alpha:1.0f];
		self.highlightColor = [NSColor colorWithCalibratedWhite:0.85 alpha:1.0f];
		self.alternateBackgroundColor = nil;
		self.animatesHighlightChanges = NO;
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

- (TUITableView *)tableView {
	return (TUITableView *)self.superview;
}

- (NSIndexPath *)indexPath {
	return [self.tableView indexPathForCell:self];
}

- (void)drawRect:(CGRect)rect {
	CGRect b = self.bounds;
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	
	if(self.highlighted) {
		[self.highlightColor set];
		CGContextFillRect(ctx, b);
	} else if(self.selected && self.selectionStyle != TUITableViewCellSelectionStyleNone) {
		
		NSColor *flatColor = nil;
		NSColor *gradientColor = nil;
		
		// Select the colors for the selection style.
		if(self.selectionStyle == TUITableViewCellSelectionStyleBlue) {
			flatColor = TUITableViewCellSelectedBlueTopColor;
			gradientColor = TUITableViewCellSelectedBlueBottomColor;
		} else if(self.selectionStyle == TUITableViewCellSelectionStyleGray) {
			flatColor = TUITableViewCellSelectedGrayTopColor;
			gradientColor = TUITableViewCellSelectedGrayBottomColor;
		} else {
			flatColor = self.backgroundColor;
			gradientColor = self.highlightColor;
		}
		
		// Draw the selection either flat or gradiented.
		if(self.drawingStyle != TUITableViewCellDrawingStyleFlat) {
			[[[NSGradient alloc] initWithColors:@[flatColor, gradientColor]] drawInRect:b angle:self.drawingStyle];
		} else {
			[flatColor set];
			CGContextFillRect(ctx, b);
		}
	} else {
		if(self.alternateBackgroundColor) {
			BOOL alternated = self.indexPath.row % 2;
			[(alternated ? self.alternateBackgroundColor : self.backgroundColor) set];
		} else {
			[self.backgroundColor set];
		}
		
		CGContextFillRect(ctx, b);
	}
	
	if(self.seperatorStyle != TUITableViewCellSeparatorStyleNone) {
		if(self.seperatorStyle != TUITableViewCellSeparatorStyleLine) {
			[TUITableViewCellTopEtchColor set];
			CGContextFillRect(ctx, CGRectMake(0, b.size.height-1, b.size.width, 1));
		}
		
		// Default for TUITableViewCellSeparatorStyleEtched.
		[TUITableViewCellBottomEtchColor set];
		CGContextFillRect(ctx, CGRectMake(0, 0, b.size.width, 1));
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

@end
