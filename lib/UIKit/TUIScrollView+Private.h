#import "TUIScrollView.h"
#import "TUIScroller.h"

@interface TUIScrollView ()

+ (BOOL)requiresLegacyScrollers;
+ (BOOL)requiresSlimScrollers;
+ (BOOL)requiresExpandingScrollers;

+ (BOOL)requiresElasticSrolling;

@end

@interface TUIScroller ()

- (CGFloat)updatedScrollerWidth;

@end