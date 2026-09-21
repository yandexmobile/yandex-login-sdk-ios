import UIKit
import WebKit
#if SWIFT_PACKAGE
import CertificateTransparency
#endif

final class WebAuthorizationViewController: UIViewController {

    private let authorizationURL: URL
    private let clientID: String
    private var completion: ((Result<URL, Error>) -> Void)?
    private let certificateTransparency = CertificateTransparency()
    private(set) var isFinished = false
    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        // Each authorization has its own cookies; logout must not silently reuse a web login.
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()

    init(url: URL, clientID: String, completion: @escaping (Result<URL, Error>) -> Void) {
        self.authorizationURL = url
        self.clientID = clientID
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        self.view = self.webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Yandex ID"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelAuthorization)
        )
        self.webView.load(URLRequest(url: self.authorizationURL))
    }

    @objc func cancelAuthorization() {
        self.finish(with: .failure(CoreLoginSDKError.userClosedWebViewController))
    }

    @discardableResult
    func handleCallbackURL(_ url: URL) -> Bool {
        guard URLUtilities.isURLSchemeDefinedBySDK(url: url, clientID: self.clientID),
              url.path == "/auth/finish" else { return false }
        self.finish(with: .success(url))
        return true
    }

    private func finish(with result: Result<URL, Error>) {
        guard !self.isFinished else { return }
        self.isFinished = true
        let completion = self.completion
        self.completion = nil
        if self.isViewLoaded {
            self.webView.stopLoading()
            self.webView.navigationDelegate = nil
            self.webView.uiDelegate = nil
        }
        let container = self.navigationController ?? self
        if container.presentingViewController != nil {
            container.dismiss(animated: true) { completion?(result) }
        } else {
            completion?(result)
        }
    }

    private func handleNavigationError(_ error: Error) {
        let nsError = error as NSError
        // Redirect interception and stopLoading also cancel navigation.
        guard nsError.domain != NSURLErrorDomain || nsError.code != NSURLErrorCancelled else { return }
        self.finish(with: .failure(error))
    }
}

extension WebAuthorizationViewController: WKNavigationDelegate {

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard !self.isFinished, let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        if self.handleCallbackURL(url) {
            decisionHandler(.cancel)
        } else {
            decisionHandler(["https", "http", "about"].contains(url.scheme?.lowercased() ?? "") ? .allow : .cancel)
        }
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        self.certificateTransparency.handleChallenge(with: challenge.protectionSpace, completionHandler: completionHandler)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.handleNavigationError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.handleNavigationError(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        self.finish(with: .failure(WKError(.webContentProcessTerminated)))
    }
}

extension WebAuthorizationViewController: WKUIDelegate {

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Keep target="_blank" links in the authorization window.
        if !self.isFinished, navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
