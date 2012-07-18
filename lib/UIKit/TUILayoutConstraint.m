#import "TUILayoutConstraint.h"
#import "TUILayoutManager.h"

@interface TUILayoutValueTransformer : NSValueTransformer {
	CGFloat offset;
	CGFloat scale;
}

+ (id)transformerWithOffset:(CGFloat)anOffset scale:(CGFloat)aScale;
- (id)initWithOffset:(CGFloat)anOffset scale:(CGFloat)aScale;

@end

@implementation TUILayoutValueTransformer

+ (id)transformerWithOffset:(CGFloat)anOffset scale:(CGFloat)aScale {
	return [[self alloc] initWithOffset:anOffset scale:aScale];
}

- (id)initWithOffset:(CGFloat)anOffset scale:(CGFloat)aScale {
	if((self = [super init])) {
		offset = anOffset;
		scale = aScale;
	} return self;
}

- (id)transformedValue:(id)value {
	CGFloat source = [value floatValue];
	CGFloat transformed = (source * scale) + offset;
	return [NSNumber numberWithFloat:transformed];
}

@end

@interface TUILayoutBlockValueTransformer : NSValueTransformer {
	TUILayoutTransformer transformer;
}

+ (id)transformerWithBlock:(TUILayoutTransformer)block;
- (id)initWithBlock:(TUILayoutTransformer)block;

@end

@implementation TUILayoutBlockValueTransformer

+ (id)transformerWithBlock:(TUILayoutTransformer)block {
	return [[self alloc] initWithBlock:block];
}

- (id)initWithBlock:(TUILayoutTransformer)block {
	if((self = [super init])) {
		transformer = [block copy];
	} return self;
}

- (id) transformedValue:(id)value {
	CGFloat source = [value floatValue];
	CGFloat transformed = transformer(source);
	return [NSNumber numberWithFloat:transformed];
}

@end

@implementation TUILayoutConstraint {
	NSValueTransformer *valueTransformer;
}

@synthesize attribute, sourceAttribute, sourceName;

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)srcLayer
                    attribute:(TUILayoutConstraintAttribute)srcAttr {
	return [self constraintWithAttribute:attr relativeTo:srcLayer attribute:srcAttr scale:1.0 offset:0.0];
}

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)srcLayer
                    attribute:(TUILayoutConstraintAttribute)srcAttr
                       offset:(CGFloat)offset {
	return [self constraintWithAttribute:attr relativeTo:srcLayer attribute:srcAttr scale:1.0 offset:offset];
}

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)srcLayer
                    attribute:(TUILayoutConstraintAttribute)srcAttr
                        scale:(CGFloat)scale
                       offset:(CGFloat)offset {
	TUILayoutValueTransformer *t = [TUILayoutValueTransformer transformerWithOffset:offset scale:scale];
	return [self constraintWithAttribute:attr relativeTo:srcLayer attribute:srcAttr valueTransformer:t];
}

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                    relativeTo:(NSString *)srcLayer
                    attribute:(TUILayoutConstraintAttribute)srcAttr
             blockTransformer:(TUILayoutTransformer)transformer {
	TUILayoutBlockValueTransformer *t = [TUILayoutBlockValueTransformer transformerWithBlock:transformer];
	return [self constraintWithAttribute:attr relativeTo:srcLayer attribute:srcAttr valueTransformer:t];
}

+ (id)constraintWithAttribute:(TUILayoutConstraintAttribute)attr
                   relativeTo:(NSString *)srcLayer
                    attribute:(TUILayoutConstraintAttribute)srcAttr
             valueTransformer:(NSValueTransformer *)transformer {
	return [[self alloc] initWithAttribute:attr relativeTo:srcLayer attribute:srcAttr valueTransformer:transformer];
}

- (id)initWithAttribute:(TUILayoutConstraintAttribute)attr
             relativeTo:(NSString *)srcLayer
              attribute:(TUILayoutConstraintAttribute)srcAttr
       valueTransformer:(NSValueTransformer *)transformer {
    
	double attributeRange = floor(log10(attr));
	double sourceAttributeRange = floor(log10(srcAttr));
	if(attributeRange != sourceAttributeRange) {
		[NSException raise:NSInvalidArgumentException format:@"Invalid source and target attributes"];
		return nil;
	}
	
	if((self = [super init])) {
		attribute = attr;
		sourceAttribute = srcAttr;
				
		sourceName = [srcLayer copy];
		valueTransformer = transformer;
	} return self;
}

- (CGFloat)transformValue:(CGFloat)original {
	id transformed = [valueTransformer transformedValue:[NSNumber numberWithFloat:original]];
	return [transformed floatValue];
}

- (void)applyToTargetView:(TUIView *)target {
	TUIView *source = [target relativeViewForName:[self sourceName]];
	[self applyToTargetView:target sourceView:source];
}

- (void)applyToTargetView:(TUIView *)target sourceView:(TUIView *)source {
	if(source == target) return;
	if(source == nil) return;
	if([self sourceAttribute] == 0) return;
	
	NSRect sourceValue = [source valueForLayoutAttribute:[self sourceAttribute]];
	NSRect targetValue = sourceValue;
    
	if(attribute >= TUILayoutConstraintAttributeMinY && attribute <= TUILayoutConstraintAttributeMidX)
		targetValue.origin.x = [self transformValue:sourceValue.origin.x];
	
	[target setValue:targetValue forLayoutAttribute:[self attribute]];
}

@end
