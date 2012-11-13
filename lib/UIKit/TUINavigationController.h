//
//  TUINavigationController.h
//  TwUI
//
//  Created by Max Goedjen on 11/12/12.
//
//

#import <Foundation/Foundation.h>
#import "TUIViewController.h"

@interface TUINavigationController : TUIViewController

- (id)initWithRootViewController:(TUIViewController *)viewController;

@property (nonatomic, readonly) TUIViewController *topViewController;

@property (nonatomic, readonly) NSArray *viewControllers;

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated;

- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated;
- (void)popViewControlerAnimated:(BOOL)animated;
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;
- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated;


@end
