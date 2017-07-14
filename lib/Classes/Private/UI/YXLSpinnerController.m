#import "YXLSpinnerController.h"
#import "YXLSpinnerView.h"

static const NSTimeInterval kYXLSpinnerAppearDuration = 0.5f;

@interface YXLSpinnerController ()

@property (nonatomic, strong) YXLSpinnerView *view;
@property (nonatomic, weak) UIView *targetView;
@property (nonatomic, assign) BOOL shouldHide;

@end

@implementation YXLSpinnerController

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _view = [[YXLSpinnerView alloc] init];
    }
    return self;
}

- (void)showInViewController:(UIViewController *)viewController
{
    NSAssert(viewController.viewLoaded, @"View of the view controller must be loaded");
    UIView *targetView = viewController.view;

    self.shouldHide = NO;
    self.view.frame = targetView.bounds;
    self.view.alpha = 0.f;

    [targetView addSubview:self.view];
    if (self.targetView != targetView) {
        self.targetView = targetView;
        [self.view runSpinner];
    }
    [UIView animateWithDuration:kYXLSpinnerAppearDuration animations:^{
        self.view.alpha = 1.f;
    } completion:NULL];
}

- (void)hide
{
    self.shouldHide = YES;
    [UIView animateWithDuration:kYXLSpinnerAppearDuration animations:^{
        self.view.alpha = 0.f;
    } completion:^(BOOL finished) {
        if (self.shouldHide) {
            [self.view removeFromSuperview];
        }
    }];
}

@end
