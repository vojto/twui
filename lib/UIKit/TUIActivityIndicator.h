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

typedef enum {
	
	// The standard white style of indicator.
	TUIActivityIndicatorStyleWhite,
	
	// The standard gray style of indicator.
	TUIActivityIndicatorStyleGray,
	
	// The classic pulsing style of indicator without gears.
	TUIActivityIndicatorStyleClassic,
	
	// A custom indicator style that allows you to set a custom drawing block
	// and animation block to use as an indicator.
	TUIActivityIndicatorStyleCustom,
} TUIActivityIndicatorStyle;

@interface TUIActivityIndicator : TUIView

// The basic appearance of the activity indicator.
// The default value is TUIActivityIndicatorStyleWhite.
@property (nonatomic, assign) TUIActivityIndicatorStyle activityIndicatorStyle;

// Controls whether the receiver is hidden when the animation is stopped.
// If the value of this property is YES (default), the indicator sets
// the indicator layer's hidden property to YES when is not animating.
// If the hidesWhenStopped property is NO, the indicator layer is not hidden
// when animation stops.
@property (nonatomic, assign) BOOL hidesWhenStopped;

// Returns YES if the indicator is currently animating, otherwise NO.
@property (nonatomic, readonly, getter = isAnimating) BOOL animating;

// Changes the speed of the indicator animation. Defaults to 1.0 seconds.
@property (nonatomic, assign) CGFloat animationSpeed;

// Returns the array of all acting animations on the indicator, and
// sets the animations that the indicator will perform while animating.
// Any duration, timing, fill mode, or repeat count information will be
// discarded to ensure consistent indicator animations. Due to the
// mutable nature of the animations, you may combine several unrelated
// animations to achieve a single complex animation. IMPORTANT: You
// must call -refreshAnimations if you modify this array while the
// indicator is animating.
@property (nonatomic, readonly) NSMutableArray *animations;

// The proxyIndicator allows you to modify properties on the indicator
// as it rotates as well, while using the basic .layer property allows you
// to modify stationary layer properties - those that are not affected by
// the animations on the indicator. Its drawRect can be used to apply
// drawing, and a combination of this and the animations array,
// a completely custom look can be applied. At its most basic, it is a
// link to the actual indicator view that is handled by the TUIActivityIndicator.
@property (nonatomic, strong) TUIView *proxyIndicator;

// Initializes the activity indicator with the style of the indicator.
// You can set and retrieve the style of a activity indicator through
// the activityIndicatorViewStyle property. See TUIActivityIndicatorStyle
// for descriptions of the style constants. 
- (id)initWithActivityIndicatorStyle:(TUIActivityIndicatorStyle)style;

// Initializes the activity indicator with both style and frame.
- (id)initWithFrame:(CGRect)frame andActivityIndicatorStyle:(TUIActivityIndicatorStyle)style;

// Starts the animation of the indicator. It is animated to indicate
// indeterminate progress. It is animated until stopAnimating is called.
- (void)startAnimating;

// Stops the animation of the indicator. When animation is stopped, the
// indicator is hidden if hidesWhenStopped is YES.
- (void)stopAnimating;

// Restarts the animation of the indicator quietly, without triggering an
// animation start or stop. This method is best used when drawing or
// animation code is updated.
- (void)refreshAnimations;

@end

// Returns an indicator frame with a basic centered gray circle.
extern TUIViewDrawRect TUIActivityIndicatorCircleFrame();

// Returns an indicator frame designed like a gear with a set number of
// teeth with a set tooth width, drawn with a custom tooth color.
// The default is 12 teeth with a 2.0 pixel width. The color is decided
// by the preset activityIndicatorStyle.
extern TUIViewDrawRect TUIActivityIndicatorGearFrame(CGFloat toothCount,
													 CGFloat toothWidth,
													 NSColor *toothColor);

// Returns an array of animations designed to pulse the indicator. Consists
// of a scaling transformation paired with an opacity blend for pulsing.
// Pass a CGFloat for the peak opacity of the pulse animation.
extern NSArray * TUIActivityIndicatorPulseAnimations(CGFloat);

// Returns an array of animations tailored to gears. Consists of a number
// of discrete steps that rotate the indicator around its center.
// Pass a CGFloat of the number of steps you wish to animate. For example,
// for a standard gear with 12 teeth, pass 12.0f as the value.
extern NSArray * TUIActivityIndicatorGearAnimations(CGFloat);

// Returns an array of animations that rotate the indicator smoothly.
extern NSArray * TUIActivityIndicatorWheelAnimations();
