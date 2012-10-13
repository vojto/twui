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

#define TUIActivityIndicatorDefaultFrame CGRectMake(0, 0, 32, 32)
#define TUIActivityIndicatorDefaultStyle TUIActivityIndicatorStyleWhite

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
		
		self.style = style;
		self.animations = [TUIActivityIndicatorPulseAnimations() mutableCopy];
		self.animationSpeed = 1.0f;
		self.indicatorFrame = TUIActivityIndicatorWhiteGearFrame();
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

TUIViewDrawRect TUIActivityIndicatorWhiteGearFrame() {
	return [^(TUIActivityIndicator *indicator, CGRect rect) {
		CGFloat radius = rect.size.width / 2.f;
		CGFloat numberOfTeeth = 12;
		CGFloat toothWidth = 2.0f;
		NSColor *toothColor = [NSColor whiteColor];
		
		CGContextRef ctx = TUIGraphicsGetCurrentContext();
		CGContextTranslateCTM(ctx, radius, radius);
		CGContextClearRect(ctx, rect);
		
		for(int toothNumber = 0; toothNumber < numberOfTeeth; toothNumber++) {
			CGFloat alpha = 0.3 + ((toothNumber / numberOfTeeth) * 0.7);
			[[toothColor colorWithAlphaComponent:alpha] setFill];
			
			CGContextRotateCTM(ctx, 1 / numberOfTeeth * (M_PI * 2.0f));
			CGRect toothRect = CGRectMake(-toothWidth / 2.0f, -radius, toothWidth, ceilf(radius * 0.54f));
			CGContextFillRoundRect(ctx, toothRect, toothWidth / 2.0f);
		}
	} copy];
}

NSArray * TUIActivityIndicatorPulseAnimations() {
	CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	scale.fromValue = @0.1f;
	scale.toValue = @1.0f;
	
	CAKeyframeAnimation *alpha = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
	alpha.values = @[@0.0, @0.3, @0.0];
	
	return @[scale, alpha];
}

NSArray * TUIActivityIndicatorWheelAnimations() {
	CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	scale.fromValue = @0.1f;
	scale.toValue = @1.0f;
	
	CAKeyframeAnimation *alpha = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
	alpha.values = @[@0.0, @0.3, @0.0];
	
	return @[scale, alpha];
}
