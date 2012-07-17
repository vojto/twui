//
//  NSScrollView+TUIExtensions.m
//  TwUI
//
//  Created by Justin Spahr-Summers on 17.07.12.
//
//  Portions of this code were taken from Velvet,
//  which is copyright (c) 2012 Bitswift, Inc.
//  See LICENSE.txt for more information.
//

#import "NSScrollView+TUIExtensions.h"
#import "EXTSafeCategory.h"
#import "NSClipView+TUIExtensions.h"
#import <objc/runtime.h>

@safecategory (NSScrollView, TUIExtensions)

#pragma mark Category initialization

+ (void)load {
    class_addProtocol([NSScrollView class], @protocol(TUIBridgedScrollView));
}

#pragma mark TUIBridgedScrollView

- (void)scrollToPoint:(CGPoint)point; {
    [self.contentView scrollToPoint:point];
}

- (void)scrollToIncludeRect:(CGRect)rect; {
    [self.contentView scrollToIncludeRect:rect];
}

@end
