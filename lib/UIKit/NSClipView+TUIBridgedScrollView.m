//
//  NSClipView+TUIExtensions.m
//  TwUI
//
//  Created by Justin Spahr-Summers on 17.07.12.
//
//  Portions of this code were taken from Velvet,
//  which is copyright (c) 2012 Bitswift, Inc.
//  See LICENSE.txt for more information.
//

#import "NSClipView+TUIExtensions.h"
#import "EXTSafeCategory.h"
#import <objc/runtime.h>

@safecategory (NSClipView, TUIExtensions)

#pragma mark Category initialization

+ (void)load {
    class_addProtocol([NSClipView class], @protocol(TUIBridgedScrollView));
}

#pragma mark TUIBridgedScrollView

- (void)scrollToIncludeRect:(CGRect)rect; {
    CGRect visibleRect = self.documentVisibleRect;
    CGSize visibleSize = visibleRect.size;

    CGPoint newScrollPoint = visibleRect.origin;

    if (CGRectGetMinX(rect) < CGRectGetMinX(visibleRect)) {
        newScrollPoint.x = CGRectGetMinX(rect);
    } else if (CGRectGetMaxX(rect) > CGRectGetMaxX(visibleRect)) {
        newScrollPoint.x = fmax(0, CGRectGetMaxX(rect) - visibleSize.width);
    }

    if (CGRectGetMinY(rect) < CGRectGetMinY(visibleRect)) {
        newScrollPoint.y = CGRectGetMinY(rect);
    } else if (CGRectGetMaxY(rect) > CGRectGetMaxY(visibleRect)) {
        newScrollPoint.y = fmax(0, CGRectGetMaxY(rect) - visibleSize.width);
    }

    [self scrollToPoint:newScrollPoint];
}

@end
