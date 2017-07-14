#import "YXLSpinnerLayerBuilder.h"

static const CGFloat kYXLSpinnerStrokeWidth = 2.f;
static const CGFloat kYXLSpinnerStrokeColorRed = 254.f;
static const CGFloat kYXLSpinnerStrokeColorGreen = 217.f;
static const CGFloat kYXLSpinnerStrokeColorBlue = 68.f;

@implementation YXLSpinnerLayerBuilder

+ (UIColor *)strokeColor
{
    return [UIColor colorWithRed:kYXLSpinnerStrokeColorRed / 255.f
                           green:kYXLSpinnerStrokeColorGreen / 255.f
                            blue:kYXLSpinnerStrokeColorBlue / 255.f
                           alpha:1.f];
}

+ (CGFloat)spinnerHeightForSize:(CGSize)size
{
    CGFloat minDimension = MIN(size.width, size.height);
    const CGFloat heights[] = { 22.f, 34.f, 52.f };

    NSUInteger index;
    for (index = 0; index < sizeof heights / sizeof *heights;) {
        if (heights[index] > minDimension) {
            break;
        }
        index++;
    }
    return heights[index];
}

+ (CALayer *)spinnerLayerWithSize:(CGSize)size;
{
    CGFloat radius = [self spinnerHeightForSize:size] / 2.f;
    return [self spinnerLayerWithRadius:radius strokeWidth:kYXLSpinnerStrokeWidth];
}

+ (CALayer *)spinnerLayerWithRadius:(CGFloat)radius strokeWidth:(CGFloat)strokeWidth
{
    CAShapeLayer *spinnerLayer = [CAShapeLayer layer];
    UIBezierPath *result = [UIBezierPath bezierPathWithArcCenter:CGPointZero
                                                          radius:radius
                                                      startAngle:0.0
                                                        endAngle:(CGFloat)M_PI
                                                       clockwise:NO];
    spinnerLayer.path = [result CGPath];
    spinnerLayer.strokeColor = [self.strokeColor CGColor];
    spinnerLayer.fillColor = [UIColor.clearColor CGColor];
    spinnerLayer.lineWidth = strokeWidth;
    spinnerLayer.anchorPoint = CGPointZero;
    return spinnerLayer;
}

@end
