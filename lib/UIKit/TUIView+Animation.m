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

#import "TUIView.h"
#import "TUICAAction.h"

@interface TUIViewAnimation : NSObject <CAAction>

@property (nonatomic, assign) void *context;
@property (nonatomic, copy) NSString *animationID;

@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, assign) SEL animationWillStartSelector;
@property (nonatomic, assign) SEL animationDidStopSelector;
@property (nonatomic, copy) void (^animationCompletionBlock)(BOOL finished);

@property (nonatomic, strong, readonly) CABasicAnimation *basicAnimation;

@end

@implementation TUIViewAnimation

- (id)init {
	self = [super init];
	if (self == nil) return nil;

	_basicAnimation = [CABasicAnimation animation];
	return self;
}

- (void)dealloc {
	if (self.animationCompletionBlock != nil) {
		self.animationCompletionBlock(NO);
		NSLog(@"Error: animation completion block didn't complete!");
	}
}

- (void)runActionForKey:(NSString *)event object:(id)anObject arguments:(NSDictionary *)dict {
	CAAnimation *animation = [self.basicAnimation copyWithZone:nil];
	animation.delegate = self;
	[animation runActionForKey:event object:anObject arguments:dict];
}

- (void)animationDidStart:(CAAnimation *)anim {
	if (self.delegate == nil || self.animationWillStartSelector == NULL) return;

	void (*animationWillStartIMP)(id, SEL, NSString *, void *) = (__typeof__(animationWillStartIMP))[(id)self.delegate methodForSelector:self.animationWillStartSelector];
	animationWillStartIMP(self.delegate, self.animationWillStartSelector, self.animationID, self.context);

	// only fire this once
	self.animationWillStartSelector = NULL;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	if (self.delegate != nil && self.animationDidStopSelector != NULL) {
		void (*animationDidStopIMP)(id, SEL, NSString *, NSNumber *, void *) = (__typeof__(animationDidStopIMP))[(id)self.delegate methodForSelector:self.animationDidStopSelector];
		animationDidStopIMP(self.delegate, self.animationDidStopSelector, self.animationID, @(flag), self.context);

		// only fire this once
		self.animationDidStopSelector = NULL;
	} else if (self.animationCompletionBlock) {
		self.animationCompletionBlock(flag);

		// only fire this once
		self.animationCompletionBlock = nil;
	}
}

@end

@implementation TUIView (TUIViewAnimation)

static NSMutableArray *AnimationStack = nil;

+ (NSMutableArray *)_animationStack {
	if(!AnimationStack) AnimationStack = [[NSMutableArray alloc] init];
	return AnimationStack;
}

+ (TUIViewAnimation *)_currentAnimation {
	return [AnimationStack lastObject];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations {
	[self animateWithDuration:duration animations:animations completion:NULL];
}

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
	[self beginAnimations:nil context:NULL];
	self.animationDuration = duration;
	[self _currentAnimation].animationCompletionBlock = completion;

	animations();

	[self commitAnimations];
}

+ (void)beginAnimations:(NSString *)animationID context:(void *)context {
	[NSAnimationContext beginGrouping];

	TUIViewAnimation *animation = [[TUIViewAnimation alloc] init];
	animation.context = context;
	animation.animationID = animationID;
	[[self _animationStack] addObject:animation];
	
	// setup defaults
	self.animationDuration = 0.25;
	self.animationCurve = TUIViewAnimationCurveEaseInOut;
}

+ (void)commitAnimations {
	[[self _animationStack] removeLastObject];
	[NSAnimationContext endGrouping];
}

+ (void)setAnimationDelegate:(id)delegate {
	[self _currentAnimation].delegate = delegate;
}

+ (void)setAnimationWillStartSelector:(SEL)selector {
	[self _currentAnimation].animationWillStartSelector = selector;
}

+ (void)setAnimationDidStopSelector:(SEL)selector {
	[self _currentAnimation].animationDidStopSelector = selector;
}

static CGFloat SlomoTime() {
	if (([NSEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSShiftKeyMask) {
		return 5.0;
	} else {
		return 1.0;
	}
}

+ (void)setAnimationDuration:(NSTimeInterval)duration {
	duration *= SlomoTime();
	[self _currentAnimation].basicAnimation.duration = duration;
	[NSAnimationContext currentContext].duration = duration;
}

+ (void)setAnimationDelay:(NSTimeInterval)delay {
	[self _currentAnimation].basicAnimation.beginTime = CACurrentMediaTime() + delay * SlomoTime();
	[self _currentAnimation].basicAnimation.fillMode = kCAFillModeBoth;
}

+ (void)setAnimationStartDate:(NSDate *)startDate {
	NSAssert(NO, @"%s is not yet implemented", __func__);
}

+ (void)setAnimationCurve:(TUIViewAnimationCurve)curve {
	NSString *functionName = kCAMediaTimingFunctionEaseInEaseOut;

	switch (curve) {
		case TUIViewAnimationCurveLinear:
			functionName = kCAMediaTimingFunctionLinear;
			break;
		case TUIViewAnimationCurveEaseIn:
			functionName = kCAMediaTimingFunctionEaseIn;
			break;
		case TUIViewAnimationCurveEaseOut:
			functionName = kCAMediaTimingFunctionEaseOut;
			break;
		case TUIViewAnimationCurveEaseInOut:
			functionName = kCAMediaTimingFunctionEaseInEaseOut;
			break;
		default:
			NSAssert(NO, @"Unrecognized animation curve: %i", (int)curve);
	}

	[self _currentAnimation].basicAnimation.timingFunction = [CAMediaTimingFunction functionWithName:functionName];
}

+ (void)setAnimationRepeatCount:(float)repeatCount {
	[self _currentAnimation].basicAnimation.repeatCount = repeatCount;
}

+ (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses {
	[self _currentAnimation].basicAnimation.autoreverses = repeatAutoreverses;
}

+ (void)setAnimationIsAdditive:(BOOL)additive {
	[self _currentAnimation].basicAnimation.additive = additive;
}

+ (void)setAnimationBeginsFromCurrentState:(BOOL)fromCurrentState {
	NSAssert(NO, @"%s is not yet implemented", __func__);
}

+ (void)setAnimationTransition:(TUIViewAnimationTransition)transition forView:(TUIView *)view cache:(BOOL)cache {
	NSAssert(NO, @"%s is not yet implemented", __func__);
}

static BOOL disableAnimations = NO;

+ (void)setAnimationsEnabled:(BOOL)enabled block:(void(^)(void))block {
	BOOL save = disableAnimations;
	disableAnimations = !enabled;
	block();
	disableAnimations = save;
}

+ (void)setAnimationsEnabled:(BOOL)enabled {
	disableAnimations = !enabled;
}

+ (BOOL)areAnimationsEnabled {
	return !disableAnimations;
}

static BOOL animateContents = NO;

+ (void)setAnimateContents:(BOOL)enabled {
	animateContents = enabled;
}

+ (BOOL)willAnimateContents {
	return animateContents;
}

- (void)removeAllAnimations {
	[self.layer removeAllAnimations];
	[self.subviews makeObjectsPerformSelector:@selector(removeAllAnimations)];
}

- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
	id defaultAction = [NSNull null];
	if (disableAnimations) return defaultAction;

	// default - don't animate contents
	if (!animateContents && [event isEqualToString:@"contents"]) return defaultAction;

	id animation = [TUIView _currentAnimation];
	if (animation == nil) return defaultAction;

	if ([TUICAAction interceptsActionForKey:event]) {
		return [TUICAAction actionWithAction:animation];
	} else {
		return animation;
	}
}

@end
