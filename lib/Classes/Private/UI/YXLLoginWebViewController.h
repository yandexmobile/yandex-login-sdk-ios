#import <UIKit/UIKit.h>

@class YXLLoginWebViewController;

@protocol YXLLoginWebViewControllerDelegate <NSObject>

- (BOOL)loginWebViewController:(YXLLoginWebViewController *)controller shouldStartLoadURL:(NSURL *)URL;
- (void)loginWebViewControllerDidClose:(YXLLoginWebViewController *)controller;

@end

@interface YXLLoginWebViewController : UIViewController

@property (nonatomic, copy, readonly) NSString *state;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithURL:(NSURL *)URL state:(NSString *)state delegate:(id<YXLLoginWebViewControllerDelegate>)delegate;

@end
