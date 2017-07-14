#import "YXLLoginWebViewController.h"

@interface YXLLoginWebViewController () <UIWebViewDelegate>

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, weak, readonly) id<YXLLoginWebViewControllerDelegate> delegate;
@property (nonatomic, strong, readonly) UIWebView *webView;

@end

@implementation YXLLoginWebViewController

- (instancetype)initWithURL:(NSURL *)URL state:(NSString *)state delegate:(id<YXLLoginWebViewControllerDelegate>)delegate
{
    self = [super initWithNibName:nil bundle:nil];
    if (self != nil) {
        _url = URL;
        _state = [state copy];
        _delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    [self.webView stopLoading];
    self.webView.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)];

    _webView = [self webViewWithFrame:self.view.bounds delegate:self];
    [self.view addSubview:self.webView];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (UIWebView *)webViewWithFrame:(CGRect)frame delegate:(id<UIWebViewDelegate>)delegate
{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:frame];
    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    webView.scalesPageToFit = YES;
    webView.scrollView.bounces = NO;
    webView.scrollView.clipsToBounds = NO;
    webView.delegate = delegate;
    return webView;
}

- (void)close
{
    [self.delegate loginWebViewControllerDidClose:self];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return [self.delegate loginWebViewController:self shouldStartLoadURL:request.URL];
}

@end
