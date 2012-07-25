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

#import <Cocoa/Cocoa.h>

@class TUIColor;

@interface NSImage (TUIExtensions)

+ (NSImage *)imageWithCGImage:(CGImageRef)cgImage;
+ (NSImage *)imageWithSize:(CGSize)size drawing:(void (^)(CGContextRef))draw; // thread safe

/*
 * Returns a CGImageRef corresponding to the receiver.
 *
 * This should only be used with bitmaps. For vector images, use
 * -CGImageForProposedRect:context:hints instead.
 */
@property (nonatomic, readonly) CGImageRef CGImage;

/*
 * Similar to -CGImageForProposedRect:context:hints:, but accepts a CGContextRef
 * instead.
 */
- (CGImageRef)CGImageForProposedRect:(CGRect *)rectPtr CGContext:(CGContextRef)context;

- (NSImage *)crop:(CGRect)cropRect;
- (NSImage *)upsideDownCrop:(CGRect)cropRect;
- (NSImage *)scale:(CGSize)size;
- (NSImage *)thumbnail:(CGSize)size;
- (NSImage *)pad:(CGFloat)padding; // can be negative (to crop to center)
- (NSImage *)roundImage:(CGFloat)radius;
- (NSImage *)invertedMask;
- (NSImage *)embossMaskWithOffset:(CGSize)offset; // subtract reciever from itself offset by 'offset', use as a mask to draw emboss
- (NSImage *)innerShadowWithOffset:(CGSize)offset radius:(CGFloat)radius color:(TUIColor *)color backgroundColor:(TUIColor *)backgroundColor; // 'backgroundColor' is used as the color the shadow is drawn with, it is mostly masked out, but a halo will remain, leading to artifacts unless it is close enough to the background color

@end
