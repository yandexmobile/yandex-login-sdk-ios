#import "YXLSpinnerView.h"
#import "YXLSpinnerLayerBuilder.h"

@interface YXLSpinnerView ()

@property (nonatomic, strong) CALayer *spinnerLayer;

@end

@implementation YXLSpinnerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.5f];
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    return self;
}

- (void)runSpinner
{
    [self.spinnerLayer removeFromSuperlayer];
    self.spinnerLayer = [YXLSpinnerLayerBuilder spinnerLayerWithSize:self.frame.size];
    [self.layer addSublayer:self.spinnerLayer];

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.duration = 1.0;
    animation.fromValue = @0.f;
    animation.toValue = @(M_PI * 2);
    animation.repeatCount = HUGE_VALF;
    [self.spinnerLayer addAnimation:animation forKey:@"rotation"];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.spinnerLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
}

@end
