#import "TUIScrollView.h"
#import "TUIScroller.h"

@interface TUIScrollView ()

+ (BOOL)requiresLegacyScrollers;
+ (BOOL)requiresSlimScrollers;
+ (BOOL)requiresExpandingScrollers;

+ (BOOL)requiresElasticSrolling;

- (void)_updateScrollers;
- (void)_updateScrollersAnimated:(BOOL)animated;

@end

@interface TUIScroller ()

- (CGFloat)updatedScrollerWidth;
- (CGFloat)updatedScrollerCornerRadius;

@end