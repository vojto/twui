#import <Cocoa/Cocoa.h>
#import "TUILayoutConstraint.h"

@interface TUIView (Layout)

@property (nonatomic, copy) NSString *layoutName;

- (void)addLayoutConstraint:(TUILayoutConstraint *)constraint;
- (NSArray *)layoutConstraints;
- (void)removeAllLayoutConstraints;

- (NSRect)valueForLayoutAttribute:(TUILayoutConstraintAttribute)attribute;
- (void)setValue:(NSRect)newValue forLayoutAttribute:(TUILayoutConstraintAttribute)attribute;

- (TUIView *)relativeViewForName:(NSString *)name;

@end