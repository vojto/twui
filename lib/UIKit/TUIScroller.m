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

#import "TUIScroller.h"
#import "TUICGAdditions.h"

static CGFloat const TUIScrollerMinimumKnobSize = 25.0f;
static CGFloat const TUIScrollerDefaultCornerRadius = 3.5f;
static CGFloat const TUIScrollerExpandedCornerRadius = 5.5f;

static CGFloat const TUIScrollerDefaultWidth = 11.0f;
static CGFloat const TUIScrollerExpandedWidth = 15.0f;
static NSTimeInterval const TUIScrollerDisplayPeriod = 1.0f;

static CGFloat const TUIScrollerHiddenAlpha = 0.0f;
static CGFloat const TUIScrollerHoverAlpha = 0.6f;
static CGFloat const TUIScrollerIdleAlpha = 0.5f;

static NSTimeInterval const TUIScrollerStateChangeSpeed = 0.2f;
static NSTimeInterval const TUIScrollerStateRefreshSpeed = 0.01f;

@interface TUIScroller () {
	struct {
		unsigned int hover:1;
		unsigned int active:1;
		unsigned int trackingInsideKnob:1;
		unsigned int scrollIndicatorStyle:2;
		unsigned int flashing:1;
	} _scrollerFlags;
}

@property (nonatomic, assign) BOOL knobHidden;
@property (nonatomic, strong) NSTimer *hideKnobTimer;

@property (nonatomic, assign) CGPoint mouseDown;
@property (nonatomic, assign) CGRect knobStartFrame;

@property (nonatomic, readonly, getter = isVertical) BOOL vertical;

- (void)_hideKnob;
- (void)_updateKnob;
- (void)_refreshKnobTimer;
- (void)_updateKnobAlphaWithSpeed:(CGFloat)duration;
- (void)_endFlashing;

@end

@implementation TUIScroller

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		_knob = [[TUIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
		self.knob.layer.cornerRadius = TUIScrollerDefaultCornerRadius;
		self.knob.userInteractionEnabled = NO;
		self.knob.backgroundColor = [NSColor blackColor];
		
		[self addSubview:self.knob];
		[self _updateKnob];
		[self _updateKnobAlphaWithSpeed:0.0];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(preferredScrollerStyleChanged:)
													 name:NSPreferredScrollerStyleDidChangeNotification
												   object:nil];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_refreshKnobTimer {
	if([NSScroller preferredScrollerStyle] == NSScrollerStyleOverlay) {
		TUIScrollViewIndicatorVisibility visibility;
		if(self.vertical)
			visibility = self.scrollView.verticalScrollIndicatorVisibility;
		else
			visibility = self.scrollView.horizontalScrollIndicatorVisibility;
		
		if(visibility != TUIScrollViewIndicatorVisibleNever) {
			self.hideKnobTimer = nil;
			self.hideKnobTimer = [NSTimer scheduledTimerWithTimeInterval:TUIScrollerDisplayPeriod
																  target:self
																selector:@selector(_hideKnob)
																userInfo:nil
																 repeats:NO];
			
			self.knobHidden = NO;
			[self _updateKnobAlphaWithSpeed:TUIScrollerStateRefreshSpeed];
		} else {
			self.knobHidden = YES;
			[self _updateKnobAlphaWithSpeed:TUIScrollerStateRefreshSpeed];
		}
	}
}

- (void)setHideKnobTimer:(NSTimer *)hideKnobTimer {
	if(!hideKnobTimer && _hideKnobTimer) {
		[_hideKnobTimer invalidate];
		_hideKnobTimer = nil;
	} else {
		_hideKnobTimer = hideKnobTimer;
	}
}

- (void)preferredScrollerStyleChanged:(NSNotification *)notification {
	self.hideKnobTimer = nil;
	
	if([NSScroller preferredScrollerStyle] == NSScrollerStyleOverlay) {
		[self _hideKnob];
	} else {
		self.knobHidden = NO;
		[self _updateKnobAlphaWithSpeed:TUIScrollerStateChangeSpeed];
	}
}

- (BOOL)isVertical {
	return self.bounds.size.height > self.bounds.size.width;
}

#define TUIScrollerCalculations(OFFSET, LENGTH, MIN_KNOB_SIZE) \
float proportion = visible.size.LENGTH / contentSize.LENGTH; \
float knobLength = trackBounds.size.LENGTH * proportion; \
if(knobLength < MIN_KNOB_SIZE) \
	knobLength = MIN_KNOB_SIZE; \
float rangeOfMotion = trackBounds.size.LENGTH - knobLength; \
float maxOffset = contentSize.LENGTH - visible.size.LENGTH; \
float currentOffset = visible.origin.OFFSET; \
float offsetProportion = 1.0 - (maxOffset - currentOffset) / maxOffset; \
float knobOffset = offsetProportion * rangeOfMotion; \
if(isnan(knobOffset)) \
	knobOffset = 0.0; \
if(isnan(knobLength)) \
	knobLength = 0.0;

- (void)_updateKnob {
	CGRect trackBounds = self.bounds;
	CGRect visible = self.scrollView.visibleRect;
	CGSize contentSize = self.scrollView.contentSize;
	
	if(self.vertical) {
		TUIScrollerCalculations(y, height, TUIScrollerMinimumKnobSize);
		
		CGRect frame;
		frame.origin.x = 0.0;
		frame.origin.y = knobOffset;
		frame.size.height = MIN(2000, knobLength);
		frame.size.width = self.expanded ? TUIScrollerExpandedWidth : TUIScrollerDefaultWidth;
		frame = ABRectRoundOrigin(CGRectInset(frame, 2, 4));
		
		[self _refreshKnobTimer];
		self.knob.frame = frame;
		self.knob.layer.cornerRadius = self.expanded ? TUIScrollerExpandedCornerRadius : TUIScrollerDefaultCornerRadius;
	} else {
		TUIScrollerCalculations(x, width, TUIScrollerMinimumKnobSize);
		
		CGRect frame;
		frame.origin.x = knobOffset;
		frame.origin.y = 0.0;
		frame.size.width = MIN(2000, knobLength);
		frame.size.height = self.expanded ? TUIScrollerExpandedWidth : TUIScrollerDefaultWidth;
		frame = ABRectRoundOrigin(CGRectInset(frame, 4, 2));
		
		[self _refreshKnobTimer];
		self.knob.frame = frame;
		self.knob.layer.cornerRadius = self.expanded ? TUIScrollerExpandedCornerRadius : TUIScrollerDefaultCornerRadius;
	}
}

- (void)_hideKnob {
	if(self.expanded) {
		[self _refreshKnobTimer];
		return;
	}
	
	self.hideKnobTimer = nil;
	self.knobHidden = YES;
	[self _updateKnobAlphaWithSpeed:TUIScrollerStateChangeSpeed];
}

- (void)layoutSubviews {
	[self _updateKnob];
}

- (void)drawRect:(CGRect)rect {
	if(!self.expanded)
		return;
	
	[[[NSGradient alloc] initWithColors:@[[NSColor colorWithCalibratedWhite:0.90 alpha:0.80],
										  [NSColor colorWithCalibratedWhite:0.95 alpha:0.80],
										  [NSColor colorWithCalibratedWhite:0.90 alpha:0.80]]] drawInRect:rect angle:0];
	[[NSColor colorWithCalibratedWhite:0.75 alpha:0.80] set];
	NSRectFill(CGRectMake(0, 0, 1, rect.size.height));
}

- (void)flash {
	_scrollerFlags.flashing = 1;
	
	static const CFTimeInterval duration = 0.6f;
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
	animation.duration = duration;
	animation.keyPath = @"opacity";
	animation.values = @[@0.5f, @0.2f, @0.0f];
	[self.knob.layer addAnimation:animation forKey:@"opacity"];
	
	[self performSelector:@selector(_endFlashing) withObject:nil afterDelay:(duration - 0.01)];
}

- (void)_endFlashing {
	_scrollerFlags.flashing = 0;
	
	[self.scrollView setNeedsLayout];
}

- (TUIScrollViewIndicatorStyle)scrollIndicatorStyle {
	return _scrollerFlags.scrollIndicatorStyle;
}

- (void)setScrollIndicatorStyle:(TUIScrollViewIndicatorStyle)style {
	_scrollerFlags.scrollIndicatorStyle = style;
	
	switch(style) {
		case TUIScrollViewIndicatorStyleLight:
			self.knob.backgroundColor = [NSColor whiteColor];
			break;
		case TUIScrollViewIndicatorStyleDark:
		default:
			self.knob.backgroundColor = [NSColor blackColor];
			break;
	}
}

- (void)_updateKnobAlphaWithSpeed:(CGFloat)duration {
	[TUIView animateWithDuration:duration animations:^{
		if(self.knobHidden)
			self.knob.alpha = TUIScrollerHiddenAlpha;
		else if(_scrollerFlags.hover)
			self.knob.alpha = TUIScrollerHoverAlpha;
		else
			self.knob.alpha = TUIScrollerIdleAlpha;
	}];
}

- (BOOL)isExpanded {
	return _scrollerFlags.hover || _scrollerFlags.active || _scrollerFlags.trackingInsideKnob;
}

- (BOOL)isFlashing {
	return _scrollerFlags.flashing;
}

- (void)mouseEntered:(NSEvent *)event {
	_scrollerFlags.hover = 1;
	[self _updateKnobAlphaWithSpeed:0.08];
	
	// Propogate mouse events.
	[super mouseEntered:event];
}

- (void)mouseExited:(NSEvent *)event {
	_scrollerFlags.hover = 0;
	[self _updateKnobAlphaWithSpeed:0.25];
	
	// Propogate mouse events.
	[super mouseExited:event];
}

- (void)mouseDown:(NSEvent *)event {
	_mouseDown = [self localPointForEvent:event];
	_knobStartFrame = self.knob.frame;
	_scrollerFlags.active = 1;
	[self _updateKnobAlphaWithSpeed:0.08];
	
	// Normal knob dragging scroll.
	// We can't use hitTest because userInteractionEnabled = NO.
	if([self.knob pointInside:[self convertPoint:_mouseDown toView:self.knob] withEvent:event]) {
		_scrollerFlags.trackingInsideKnob = 1;
	} else {
		
		// Paged scroll.
		_scrollerFlags.trackingInsideKnob = 0;
		
		CGRect visible = self.scrollView.visibleRect;
		CGPoint contentOffset = self.scrollView.contentOffset;
		
		if(self.vertical) {
			if(_mouseDown.y < _knobStartFrame.origin.y)
				contentOffset.y += visible.size.height;
			else
				contentOffset.y -= visible.size.height;
		} else {
			if(_mouseDown.x < _knobStartFrame.origin.x)
				contentOffset.x += visible.size.width;
			else
				contentOffset.x -= visible.size.width;
		}
		
		[self.scrollView setContentOffset:contentOffset animated:YES];
	}
	
	// Propogate mouse events.
	[super mouseDown:event];
}

- (void)mouseUp:(NSEvent *)event {
	_scrollerFlags.active = 0;
	[self _updateKnobAlphaWithSpeed:0.08];
	
	// Propogate mouse events.
	[super mouseUp:event];
}

#define TUIScrollerCalculationsReverse(OFFSET, LENGTH) \
CGRect knobFrame = _knobStartFrame; \
knobFrame.origin.OFFSET += diff.LENGTH; \
CGFloat knobOffset = knobFrame.origin.OFFSET; \
CGFloat minKnobOffset = 0.0; \
CGFloat maxKnobOffset = trackBounds.size.LENGTH - knobFrame.size.LENGTH; \
CGFloat proportion = (knobOffset - 1.0) / (maxKnobOffset - minKnobOffset); \
CGFloat maxContentOffset = contentSize.LENGTH - visible.size.LENGTH;

- (void)mouseDragged:(NSEvent *)event {
	// Normal knob dragging.
	if(_scrollerFlags.trackingInsideKnob) {
		CGPoint p = [self localPointForEvent:event];
		CGSize diff = CGSizeMake(p.x - _mouseDown.x, p.y - _mouseDown.y);
		
		CGRect trackBounds = self.bounds;
		CGRect visible = self.scrollView.visibleRect;
		CGSize contentSize = self.scrollView.contentSize;
		
		if(self.vertical) {
			TUIScrollerCalculationsReverse(y, height);
			CGPoint scrollOffset = self.scrollView.contentOffset;
			scrollOffset.y = roundf(-proportion * maxContentOffset);
			self.scrollView.contentOffset = scrollOffset;
		} else {
			TUIScrollerCalculationsReverse(x, width);
			CGPoint scrollOffset = self.scrollView.contentOffset;
			scrollOffset.x = roundf(-proportion * maxContentOffset);
			self.scrollView.contentOffset = scrollOffset;
		}
	}
	// Otherwise, dragged in the knob tracking area. Ignore this.
	
	// Propogate mouse events.
	[super mouseDragged:event];
}

@end
