#import <objc/runtime.h>
#import "TUILayoutManager.h"
#import "TUIView+Layout.h"

@interface TUILayoutContainer : NSObject

@property (nonatomic, copy) NSString *layoutName;
@property (readonly) NSMutableArray *layoutConstraints;

@end

@implementation TUILayoutContainer

@synthesize layoutName;
@synthesize layoutConstraints;

+ (id)container {
	return [[self alloc] init];
}

- (id)init {
	if((self = [super init])) {
		layoutConstraints = [[NSMutableArray alloc] init];
	} return self;
}

@end

static TUILayoutManager *_sharedLayoutManager = nil;

@implementation TUILayoutManager {
	BOOL hasRegistered;
	BOOL isProcessingChanges;
	
	NSMapTable *constraints;
	NSMutableArray *viewsToProcess;
	NSMutableSet *processedViews;
}

+ (id)sharedLayoutManager {
	return _sharedLayoutManager;
}

+ (id)allocWithZone:(NSZone *)zone {
	if(_sharedLayoutManager)
		 return _sharedLayoutManager;
	else return [super allocWithZone:zone];
}

- (id)init {
	if(!_sharedLayoutManager) {
		if((self = [super init])) {
			isProcessingChanges = NO;
			viewsToProcess = [[NSMutableArray alloc] init];
			processedViews = [[NSMutableSet alloc] init];
			
			constraints = [NSMapTable mapTableWithWeakToStrongObjects];
			hasRegistered = NO;
		}
	} else if (self != _sharedLayoutManager) {
		self = _sharedLayoutManager;
	} return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self removeAllLayoutConstraints];
}

- (void)removeAllLayoutConstraints {
	[constraints removeAllObjects];
}

- (void)processView:(TUIView *)aView {
	if(hasRegistered == NO) {
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(frameChanged:)
                                                     name:TUIViewFrameDidChangeNotification
                                                   object:nil];
		hasRegistered = YES;
	}
    
	[processedViews addObject:aView];
	
	NSArray *viewConstraints = [self layoutConstraintsOnView:aView];
	for(TUILayoutConstraint * constraint in viewConstraints)
		[constraint applyToTargetView:aView];
	
    // Order of Operations:
    // 1.  Siblings with constraints to this view.
    // 2.  Children with constraints to superview.
	
	if([self layoutNameForView:aView] != nil) {
		NSArray *superSubviews = [[aView superview] subviews];
		for(TUIView *subview in superSubviews) {
			if(subview == aView) continue;
			
			NSArray *subviewConstraints = [self layoutConstraintsOnView:subview];
			for(TUILayoutConstraint *subviewConstraint in subviewConstraints) {
				TUIView *sourceView = [subview relativeViewForName:[subviewConstraint sourceName]];
				if(sourceView == aView)
					[subviewConstraint applyToTargetView:subview sourceView:sourceView];
			}
		}
	}
	
	NSArray *subviews = [aView subviews];
	for(TUIView *subview in subviews) {
		NSArray *subviewConstraints = [self layoutConstraintsOnView:subview];
		for(TUILayoutConstraint *subviewConstraint in subviewConstraints) {
			TUIView *sourceView = [subview relativeViewForName:[subviewConstraint sourceName]];
			if(sourceView == aView)
				[subviewConstraint applyToTargetView:subview sourceView:sourceView];
		}
	}
}

- (void)beginProcessingView:(TUIView *)view {
	if(isProcessingChanges == NO) {
		isProcessingChanges = YES;
		
        @autoreleasepool {
            [viewsToProcess removeAllObjects];
            [processedViews removeAllObjects];
            [viewsToProcess addObject:view];
            
            while([viewsToProcess count] > 0) {
                TUIView *currentView = [viewsToProcess objectAtIndex:0];
                [viewsToProcess removeObjectAtIndex:0];			
                if([viewsToProcess containsObject:currentView] == NO)
                    [self processView:currentView];
            }
        }
        
		isProcessingChanges = NO;
	} else {
		if([processedViews containsObject:view] == NO)
			[viewsToProcess addObject:view];
	}
}

- (void)frameChanged:(NSNotification *)notification {
	TUIView *view = [notification object];
	[self beginProcessingView:view];
}

- (void)addLayoutConstraint:(TUILayoutConstraint *)constraint toView:(TUIView *)view {
	TUILayoutContainer *viewContainer = [constraints objectForKey:view];
	if(viewContainer == nil) {
		viewContainer = [TUILayoutContainer container];
		[constraints setObject:viewContainer forKey:view];
	}
	
	[[viewContainer layoutConstraints] addObject:constraint];
	[self beginProcessingView:view];
}

- (void)removeLayoutConstraintsFromView:(TUIView *)view {
	TUILayoutContainer *viewContainer = [constraints objectForKey:view];
	[[viewContainer layoutConstraints] removeAllObjects];
	
	if([[viewContainer layoutConstraints] count] == 0 && [viewContainer layoutName] == nil)
		[constraints removeObjectForKey:view];
}

- (NSArray *)layoutConstraintsOnView:(TUIView *)view {
	TUILayoutContainer *container = [constraints objectForKey:view];
	if (container == nil) return [NSArray array];
	return [[container layoutConstraints] copy];
}

- (NSString *)layoutNameForView:(TUIView *)view {
	TUILayoutContainer *container = [constraints objectForKey:view];
	return [container layoutName];
}

- (void)setLayoutName:(NSString *)name forView:(TUIView *)view {
	TUILayoutContainer *viewContainer = [constraints objectForKey:view];
	
	if(name == nil && [[viewContainer layoutConstraints] count] == 0)
		[constraints removeObjectForKey:view];
	else {
		if(viewContainer == nil) {
			viewContainer = [TUILayoutContainer container];
			[constraints setObject:viewContainer forKey:view];
		} [viewContainer setLayoutName:name];
	}
}

@end
