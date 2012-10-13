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
	
	// A custom indicator style that allows you
	// to set a custom drawing block and animation
	// block to use as an indicator.
	TUIActivityIndicatorStyleCustom,
} TUIActivityIndicatorStyle;

@interface TUIActivityIndicator : TUIView

// The basic appearance of the activity indicator.
// The default value is TUIActivityIndicatorStyleWhite.
@property (nonatomic, assign) TUIActivityIndicatorStyle style;

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

// Sets the animations that the indicator will perform while animating.
// Any duration, timing, fill mode, or repeat count information will be
// discarded to ensure consistent indicator animations.
@property (nonatomic, strong) NSMutableArray *animations;

@property (nonatomic, copy) TUIViewDrawRect indicatorFrame;

// Initializes the activity indicator with the style of the indicator.
// You can set and retrieve the style of a activity indicator through
// the activityIndicatorViewStyle property. See TUIActivityIndicatorStyle
// for descriptions of the style constants. 
- (id)initWithActivityIndicatorStyle:(TUIActivityIndicatorStyle)style;

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

extern TUIViewDrawRect TUIActivityIndicatorWhiteGearFrame();
extern NSArray * TUIActivityIndicatorPulseAnimations();
extern NSArray * TUIActivityIndicatorWheelAnimations();
