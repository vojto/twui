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

@property (nonatomic, strong) TUIView *spinner;

- (id)initWithFrame:(CGRect)frame andActivityIndicatorStyle:(TUIActivityIndicatorStyle)style;
- (CAAnimationGroup *)packagedAnimations;

@end

@implementation TUIActivityIndicator

- (id)initWithFrame:(CGRect)frame andActivityIndicatorStyle:(TUIActivityIndicatorStyle)style {
	if((self = [super initWithFrame:frame])) {
		self.spinner = [[TUIView alloc] initWithFrame:self.bounds];
		self.spinner.backgroundColor = [NSColor clearColor];
		self.spinner.userInteractionEnabled = NO;
		self.spinner.hidden = YES;
		[self addSubview:self.spinner];
		
		self.activityIndicatorStyle = style;
		self.animations = [TUIActivityIndicatorGearAnimations(TUIActivityIndicatorDefaultToothCount) mutableCopy];
		self.animationSpeed = 1.0f;
		
		NSColor *selectedColor = [NSColor whiteColor];
		if(style == TUIActivityIndicatorStyleGray)
			selectedColor = [NSColor grayColor];
		self.indicatorFrame = TUIActivityIndicatorGearFrame(TUIActivityIndicatorDefaultToothCount,
															TUIActivityIndicatorDefaultToothWidth,
															selectedColor);
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	return [self initWithFrame:frame andActivityIndicatorStyle:TUIActivityIndicatorDefaultStyle];
}

- (id)initWithActivityIndicatorStyle:(TUIActivityIndicatorStyle)style {
	return [self initWithFrame:TUIActivityIndicatorDefaultFrame andActivityIndicatorStyle:style];
}

- (void)startAnimating {
	if(!self.animating) {
		self.spinner.hidden = NO;
		[self.spinner.layer addAnimation:self.packagedAnimations forKey:nil];
		_animating = YES;
	}
}

- (void)refreshAnimations {
	if(self.animating) {
		[self.spinner.layer removeAllAnimations];
		[self.spinner.layer addAnimation:self.packagedAnimations forKey:nil];
	}
}

- (void)stopAnimating {
	if(self.animating) {
		[self.spinner.layer removeAllAnimations];
		
		self.spinner.hidden = YES;
		_animating = NO;
	}
}

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

// Pass the indicator frame through to the spinner view, which will
// actually use it to draw itself through the animations.
- (void)setIndicatorFrame:(TUIViewDrawRect)indicatorFrame {
	self.spinner.drawRect = indicatorFrame;
}

- (TUIViewDrawRect)indicatorFrame {
	return self.spinner.drawRect;
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
