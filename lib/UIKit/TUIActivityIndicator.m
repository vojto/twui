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

#import "TUIActivityIndicator.h"
#import "TUICGAdditions.h"

#define TUIActivityIndicatorDefaultFrame		CGRectMake(0, 0, 32, 32)
#define TUIActivityIndicatorDefaultStyle		TUIActivityIndicatorStyleWhite
#define TUIActivityIndicatorDefaultToothCount	12.0f
#define TUIActivityIndicatorDefaultToothWidth	2.0f

@interface TUIActivityIndicator ()

@property (nonatomic, strong) TUIView *indicator;

- (id)initWithFrame:(CGRect)frame andActivityIndicatorStyle:(TUIActivityIndicatorStyle)style;
- (CAAnimationGroup *)packagedAnimations;

@end

@implementation TUIActivityIndicator

- (id)initWithFrame:(CGRect)frame andActivityIndicatorStyle:(TUIActivityIndicatorStyle)style {
	if((self = [super initWithFrame:frame])) {
		self.indicator = [[TUIView alloc] initWithFrame:self.bounds];
		self.indicator.backgroundColor = [NSColor clearColor];
		self.indicator.userInteractionEnabled = NO;
		self.indicator.hidden = YES;
		[self addSubview:self.indicator];
		
		_activityIndicatorStyle = style;
		_animationSpeed = 1.0f;
		
		if(style != TUIActivityIndicatorStyleCustom) {
			NSColor *selectedColor = style == TUIActivityIndicatorStyleGray ? [NSColor grayColor] : [NSColor whiteColor];
			
			_animations = [TUIActivityIndicatorGearAnimations(TUIActivityIndicatorDefaultToothCount) mutableCopy];
			self.indicator.drawRect = TUIActivityIndicatorGearFrame(TUIActivityIndicatorDefaultToothCount,
																	TUIActivityIndicatorDefaultToothWidth,
																	selectedColor);
		}
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	return [self initWithFrame:frame andActivityIndicatorStyle:TUIActivityIndicatorDefaultStyle];
}

- (id)initWithActivityIndicatorStyle:(TUIActivityIndicatorStyle)style {
	return [self initWithFrame:TUIActivityIndicatorDefaultFrame andActivityIndicatorStyle:style];
}

// Animates the indicator through its started and stopped phases.
- (void)startAnimating {
	if(!self.animating) {
		self.indicator.hidden = NO;
		[self.indicator.layer addAnimation:self.packagedAnimations forKey:nil];
		_animating = YES;
	}
}

- (void)refreshAnimations {
	if(self.animating) {
		[self.indicator.layer removeAllAnimations];
		[self.indicator.layer addAnimation:self.packagedAnimations forKey:nil];
	}
}

- (void)stopAnimating {
	if(self.animating) {
		self.indicator.hidden = YES;
		[self.indicator.layer removeAllAnimations];
		_animating = NO;
	}
}

// Apply fixes to animations in the animations array and then
// package them in a group with a common duration, repeat count,
// fill mode, and timing function. This will be applied to the
// indicator layer for consistent animations.
- (CAAnimationGroup *)packagedAnimations {
	for(CAAnimation *animation in self.animations) {
		animation.fillMode = kCAFillModeForwards;
		animation.duration = self.animationSpeed;
		animation.repeatCount = INT_MAX;
	}
	
	CAAnimationGroup *animationGroup = [[CAAnimationGroup alloc] init];
	animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	animationGroup.fillMode = kCAFillModeForwards;
	animationGroup.duration = self.animationSpeed;
	animationGroup.repeatCount = INT_MAX;
	animationGroup.animations = self.animations;
	
	return animationGroup;
}

// The layer proxy is an effective way to forward the spinner's
// to the reciever for property customization.
- (CALayer *)indicatorLayerProxy {
	return self.indicator.layer;
}

// Prevent custom animations if the style is not custom.
- (void)setAnimations:(NSMutableArray *)animations {
	if(self.activityIndicatorStyle == TUIActivityIndicatorStyleCustom)
		_animations = animations;
}

// Pass the indicator frame through to the spinner view, which will
// actually use it to draw itself through the animations.
- (void)setIndicatorFrame:(TUIViewDrawRect)indicatorFrame {
	if(self.activityIndicatorStyle == TUIActivityIndicatorStyleCustom)
		self.indicator.drawRect = indicatorFrame;
}

- (TUIViewDrawRect)indicatorFrame {
	return self.indicator.drawRect;
}

// Animation glitch fixes-- don't let the view lose its animations
// because we take charge of that. When the view is moved on or
// off a window or superview, refresh the animation, so it doesn't freeze.
- (void)removeAllAnimations {
	// Don't remove any animations.
}

- (void)willMoveToSuperview:(TUIView *)newSuperview {
	[self refreshAnimations];
}

- (void)willMoveToWindow:(TUINSWindow *)newWindow {
	[self refreshAnimations];
}

@end

// Custom indicator frames.
TUIViewDrawRect TUIActivityIndicatorCircleFrame() {
	return [^(TUIActivityIndicator *indicator, CGRect rect) {
		CGContextRef ctx = TUIGraphicsGetCurrentContext();
		CGContextClearRect(ctx, rect);
		
		[[NSColor colorWithCalibratedWhite:1.0f alpha:0.5f] set];
		CGContextFillEllipseInRect(ctx, rect);
	} copy];
}

TUIViewDrawRect TUIActivityIndicatorGearFrame(CGFloat toothCount, CGFloat toothWidth, NSColor *toothColor) {
	return [^(TUIActivityIndicator *indicator, CGRect rect) {
		CGFloat radius = rect.size.width / 2.0f;
		
		CGContextRef ctx = TUIGraphicsGetCurrentContext();
		CGContextTranslateCTM(ctx, radius, radius);
		CGContextClearRect(ctx, rect);
		
		for(int toothNumber = 0; toothNumber < toothCount; toothNumber++) {
			CGFloat alpha = 0.3 + ((toothNumber / toothCount) * 0.7);
			[[toothColor colorWithAlphaComponent:alpha] setFill];
			
			CGContextRotateCTM(ctx, 1 / toothCount * (M_PI * 2.0f));
			CGRect toothRect = CGRectMake(-toothWidth / 2.0f, -radius, toothWidth, ceilf(radius * 0.54f));
			CGContextFillRoundRect(ctx, toothRect, toothWidth / 2.0f);
		}
	} copy];
}

// Custom indicator animations.
NSArray * TUIActivityIndicatorPulseAnimations(CGFloat peakOpacity) {
	CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	scale.fromValue = @0.1f;
	scale.toValue = @1.0f;
	
	CAKeyframeAnimation *alpha = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
	alpha.values = @[@0.0, @(peakOpacity), @0.0];
	
	return @[scale, alpha];
}

NSArray * TUIActivityIndicatorGearAnimations(CGFloat frameCount) {
	NSMutableArray *values = [NSMutableArray array];
	for(int i = 0; i < frameCount + 1; i++) {
		[values addObject:@(2.0 * (i / frameCount) * M_PI)];
	}
	
	NSMutableArray *times = [NSMutableArray array];
	for(int i = 0; i < frameCount + 1; i++) {
		[times addObject:@(1.0 * (i / frameCount))];
	}
	
	CAKeyframeAnimation *rotate = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
	rotate.calculationMode = kCAAnimationDiscrete;
	rotate.values = values;
	rotate.keyTimes = times;
	rotate.cumulative = YES;
	
	return @[rotate];
}

NSArray * TUIActivityIndicatorWheelAnimations() {
	CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	rotate.toValue = @(2.0 * M_PI);
	rotate.cumulative = YES;
	
	return @[rotate];
}
