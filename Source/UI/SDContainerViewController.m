//
//  SDContainerViewController.m
//
//  Created by Brandon Sneed on 1/17/13.
//  Copyright (c) 2013 SetDirection. All rights reserved.
//

#import "SDContainerViewController.h"


@interface SDContainerViewControllerTransitioningContext : NSObject <UIViewControllerContextTransitioning>

@property (nonatomic, strong) UIViewController *parentController;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic) BOOL isAnimated;
@property (nonatomic) BOOL isInteractive;
@property (nonatomic) BOOL transitionWasCancelled;
@property (nonatomic) UIModalPresentationStyle presentationStyle;

@property (nonatomic, strong) UIViewController *fromController;
@property (nonatomic, strong) UIViewController *toController;

@property (nonatomic, copy) void(^completionBlock)();

@end

@implementation SDContainerViewControllerTransitioningContext

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
}
- (void)finishInteractiveTransition {
}
- (void)cancelInteractiveTransition {
}

- (void)completeTransition:(BOOL)didComplete {
    [_parentController addChildViewController:_toController];

    [_fromController.view removeFromSuperview];
    [_fromController removeFromParentViewController];
    [_toController didMoveToParentViewController:_parentController];
    _fromController.view.transform = CGAffineTransformIdentity;
    _containerView.userInteractionEnabled = YES;

    if (_completionBlock) {
        _completionBlock();
    }
}

- (UIViewController *)viewControllerForKey:(NSString *)key {
    if ([key isEqualToString:UITransitionContextToViewControllerKey]) {
        return _toController;
    }
    else if ([key isEqualToString:UITransitionContextFromViewControllerKey]) {
        return _fromController;
    }
    return nil;
}

- (CGRect)initialFrameForViewController:(UIViewController *)vc {
    return _containerView.bounds;
}

- (CGRect)finalFrameForViewController:(UIViewController *)vc {
    return _containerView.bounds;
}


@end


#pragma mark -


@interface SDContainerViewController ()
@property (nonatomic, strong) NSMutableArray *queuedTransitionOperations;
@property (nonatomic, strong) NSBlockOperation *currentTransitionOperation;
@end

@implementation SDContainerViewController

/**
 Designated initializer for ContainerViewController. Same as calling init and then setting the viewController array.
 */
- (instancetype)initWithViewControllers:(NSArray *)viewControllers
{
    self = [super initWithNibName:nil bundle:nil];
    if(self != nil)
    {
        _viewControllers = viewControllers;
    }

    return self;
}

- (instancetype)init
{
    return [super initWithNibName:nil bundle:nil];
}

// Leaving in for Legacy support. Use the designated initializer instead.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)loadView
{
    [super loadView];

    self.view.autoresizesSubviews = YES;
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (!_containerView)
        _containerView = self.view;
}

- (void) viewDidLoad {
    [super viewDidLoad];

    // Someone has set our selectedViewController, but it was before we had a view, make sure it's set up now
    if (_selectedViewController && nil == _selectedViewController.view.superview)
    {
        _selectedViewController.view.frame = self.containerView.bounds;
        [_selectedViewController.view setNeedsUpdateConstraints];

        [self.containerView addSubview:_selectedViewController.view];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.selectedViewController = _selectedViewController;
}

#pragma mark properties

- (void)setContainerView:(UIView *)containerView
{
    if (self.view == _containerView)
        self.view = containerView;
    else
        [self.view addSubview:containerView];
    
    _containerView = containerView;
}

- (void)setViewControllers:(NSArray *)viewControllers
{
    if (_viewControllers == viewControllers)
        return;

    // this will remove any current controller.
    if (_selectedViewController)
        self.selectedViewController = nil;
    
    _viewControllers = viewControllers;
    self.selectedViewController = [viewControllers objectAtIndex:0];
}

- (void)setSelectedIndex:(NSUInteger)index
{
    if (index < _viewControllers.count)
        self.selectedViewController = [_viewControllers objectAtIndex:index];
}

- (NSUInteger)selectedIndex
{
    return [_viewControllers indexOfObject:self.selectedViewController];
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController {
    NSAssert(_viewControllers.count > 0, @"SDContainerViewController must have view controllers set.");

    NSUInteger index = [_viewControllers indexOfObject:selectedViewController];
    if (index == NSNotFound)
        return;

    if (_selectedViewController != selectedViewController)
    {
        id<UIViewControllerAnimatedTransitioning> animator = [self.delegate containerController:self animationControllerForTransitionFromController:_selectedViewController toController:selectedViewController];
        if (_selectedViewController && animator) {

            UIViewController *fromController = _selectedViewController;
            UIViewController *toController = selectedViewController;
            _selectedViewController = selectedViewController;

            NSBlockOperation *op = [[NSBlockOperation alloc] init];
            @weakify(op,weakOp);
            [op addExecutionBlock:^{
                [fromController willMoveToParentViewController:nil];

                UINavigationController *nc = [toController isKindOfClass:[UINavigationController class]] ? (id) toController : nil;
                if (nc) {
                    [nc.delegate navigationController:nc willShowViewController:[nc topViewController] animated:YES];
                }

                SDContainerViewControllerTransitioningContext *transitionContext = [SDContainerViewControllerTransitioningContext new];
                transitionContext.parentController = self;
                transitionContext.containerView = self.view;
                transitionContext.fromController = fromController;
                transitionContext.toController = toController;

                transitionContext.completionBlock = ^{
                    @strongify(weakOp,strongOp);
                    [self _completeAnimatedTransitionOperation:strongOp];
                };

                [animator animateTransition:transitionContext];
                
            }];


            [self _queueAnimatedTransitionOperation:op];

        }
        else {
            // remove the existing one from the parent controller
            UIViewController *currentController = _selectedViewController;
            [currentController willMoveToParentViewController:nil];
            [currentController.view removeFromSuperview];
            [currentController removeFromParentViewController];

            _selectedViewController = selectedViewController;

            // add the new one to the parent controller (only set frame when not using autolayout)
            [self addChildViewController:_selectedViewController];

            _selectedViewController.view.frame = self.containerView.bounds;
            [_selectedViewController.view setNeedsUpdateConstraints];

            UINavigationController *nc = [_selectedViewController isKindOfClass:[UINavigationController class]] ? (id) _selectedViewController : nil;
            if (nc) {
                [nc.delegate navigationController:nc willShowViewController:_selectedViewController animated:YES];
            }
            [self.containerView addSubview:_selectedViewController.view];
            [_selectedViewController didMoveToParentViewController:self];
        }

    }
}

- (void) _queueAnimatedTransitionOperation:(NSBlockOperation *)op {
    if (nil == _queuedTransitionOperations) {
        _queuedTransitionOperations = [NSMutableArray new];
    }
    if (nil == _currentTransitionOperation) {
        [self _runAnimatedTransitionOperation:op];
    }
    else {
        [_queuedTransitionOperations addObject:op];
    }
}

- (void) _runAnimatedTransitionOperation:(NSBlockOperation *)op {
    _currentTransitionOperation = op;
    [op start];
}

- (void) _completeAnimatedTransitionOperation:(NSBlockOperation *)op {
    NSBlockOperation *nextOp = [_queuedTransitionOperations shift];
    if (nextOp) {
        [self _runAnimatedTransitionOperation:nextOp];
    }
    else {
        _currentTransitionOperation = nil;
    }
}

- (UIViewController *)currentVisibleViewController
{
    UIViewController *result = self.selectedViewController;
    
    if ([result isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navController = (UINavigationController *)result;
        result = navController.visibleViewController;
    }
    else
    if ([result isKindOfClass:[UITabBarController class]])
    {
        UITabBarController *tabController = (UITabBarController *)result;
        result = tabController.selectedViewController;
        
        if ([result isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navController = (UINavigationController *)result;
            result = navController.visibleViewController;
        }
    }
    else
    if ([result isKindOfClass:[SDContainerViewController class]])
    {
        SDContainerViewController *containerController = (SDContainerViewController *)result;
        result = containerController.currentVisibleViewController;
    }
    
    return result;
}

- (UINavigationController*)navigationControllerForViewController:(UIViewController*)viewController
{
    return [self navigationControllerForViewControllerClass: [viewController class]];
}

- (UINavigationController*)navigationControllerForViewControllerClass:(Class)viewControllerClass
{
    UINavigationController* foundNavController = nil;
    for(UINavigationController* navController in self.viewControllers)
    {
        for(UIViewController* viewController in navController.viewControllers)
        {
            if([viewController isKindOfClass:viewControllerClass])
            {
                foundNavController = navController;
                break;
            }
        }
        
        if(foundNavController)
            break;
    }
    
    return foundNavController;
}

@end


