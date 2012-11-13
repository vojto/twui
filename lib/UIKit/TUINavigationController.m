 //
//  TUINavigationController.m
//  TwUI
//
//  Created by Max Goedjen on 11/12/12.
//
//

#import "TUINavigationController.h"
#import "TUIView.h"

@interface TUINavigationController ()

@property (nonatomic) NSMutableArray *stack;

@end

#define kPushPopDuration .5
#define kPushDelay .1

@implementation TUINavigationController

- (id)initWithRootViewController:(TUIViewController *)viewController {
	self = [super init];
	if (self) {
		_stack = [@[] mutableCopy];
		[_stack addObject:viewController];
		self.view.clipsToBounds = YES;
	}
	return self;
}

- (void)loadView {
	self.view = [[TUIView alloc] initWithFrame:CGRectZero];
	self.view.backgroundColor = [NSColor lightGrayColor];
	
	TUIViewController *visible = [self topViewController];
	[visible viewWillAppear:NO];
	[self.view addSubview:visible.view];
	visible.view.frame = self.view.bounds;
	visible.view.autoresizingMask = TUIViewAutoresizingFlexibleHeight | TUIViewAutoresizingFlexibleWidth;
	[visible viewDidAppear:YES];

}

#pragma mark - Properties

- (NSArray *)viewControllers {
	return [NSArray arrayWithArray:_stack];
}

- (TUIViewController *)topViewController {
	return [_stack lastObject];
}

#pragma mark - Methods

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {	
	[_stack removeAllObjects];
	[_stack addObjectsFromArray:viewControllers];
}

- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated {

	TUIViewController *last = [self topViewController];
	[_stack addObject:viewController];
	CGFloat duration = animated ? kPushPopDuration : 0;
		
	[last viewWillDisappear:animated];
	[viewController viewWillAppear:animated];

	[self.view addSubview:viewController.view];
	
	[TUIView animateWithDuration:kPushDelay animations:^{
		//If we assign the frame manually, it 'pops' in
		viewController.view.frame = [self _offscreenRightFrame];
	} completion:^(BOOL finished) {
		[TUIView animateWithDuration:duration animations:^{
			last.view.frame = [self _offscreenLeftFrame];
			viewController.view.frame = self.view.bounds;
		} completion:^(BOOL finished) {
			[last.view removeFromSuperview];
			[viewController viewDidAppear:animated];
			[last viewDidDisappear:animated];
		}];
	}];
}

- (void)popViewControlerAnimated:(BOOL)animated {
	if ([_stack count] <= 1) {
		[NSException raise:NSInvalidArgumentException format:@"Stack has one or less view controllers"];
		return;
	}
	[self popToViewController:[_stack objectAtIndex:([_stack count] - 2)] animated:animated];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
	if ([[self topViewController] isEqual:[_stack objectAtIndex:0]] == YES) {
		return @[];
	}
	return [self popToViewController:[_stack objectAtIndex:0] animated:animated];
}

- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated {
	if ([_stack containsObject:viewController] == NO) {
		[NSException raise:NSInvalidArgumentException format:@"View controller %@ is not in stack", viewController];
		return @[];
	}
	
	TUIViewController *last = [_stack lastObject];
	
	NSMutableArray *popped = [@[] mutableCopy];
	while ([viewController isEqual:[_stack lastObject]] == NO) {
		[popped addObject:[_stack lastObject]];
		[_stack removeLastObject];
	}
	
	
	[self.view addSubview:viewController.view];
	viewController.view.frame = [self _offscreenLeftFrame];
	
	CGFloat duration = animated ? kPushPopDuration : 0;

	[last viewWillDisappear:animated];
	[viewController viewWillAppear:animated];
	
	[TUIView animateWithDuration:duration animations:^{
		last.view.frame = [self _offscreenRightFrame];
		viewController.view.frame = self.view.bounds;
	} completion:^(BOOL finished) {
		[last.view removeFromSuperview];
		[viewController viewDidAppear:animated];
		[last viewDidDisappear:animated];
	}];

	
	return popped;
}

#pragma mark - Private

- (CGRect)_offscreenLeftFrame {
	CGRect bounds = self.view.bounds;
	CGRect offscreenLeft = bounds;
	offscreenLeft.origin.x -= bounds.size.width;
	return offscreenLeft;
}

- (CGRect)_offscreenRightFrame {
	CGRect bounds = self.view.bounds;
	CGRect offscreenRight = bounds;
	offscreenRight.origin.x += bounds.size.width;
	return offscreenRight;
}

@end
