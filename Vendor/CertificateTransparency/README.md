# CertificateTransparency

## Purpose

URLSession/WKWebView don't apply certificate transparency checks when verifying certificate chains, originating from a custom root (a certificate not in system trust store). The goal of this library is to perform such checks.

## Configuration

Library can be configured with `CertificateTransparencyConfiguration` object:
1. `autoUpdate`: Automatically update list of CertificateTransparency logs (CT logs) from a server. `true` by default.
2. `updateURL`: URL where CT logs are stored. Takes effect only if `autoUpdate = true`. By default the logs will be downloaded from  https://browser-resources.s3.yandex.net/ctlog/ctlog.json
3. `customRoots`: A list of custom trust anchors. By default it contains 'Russian Trusted Root CA'
4. `logs`: A list of CT logs to perform checks. Takes effect only if `autoUpdate = false`. By default it contains a snapshot from https://browser-resources.s3.yandex.net/ctlog/ctlog.json


## Working with URLSession

- Implement URLSessionDelegate
```swift
class YourSessionDelegate: URLSessionDelegate {
  private let ct: CertificateTransparency

  init() {
    let configuration = CertificateTransparencyConfiguration()
    ct = CertificateTransparency(configuration: configuration)
  }

  func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    ct.handleChallenge(with: challenge.protectionSpace, completionHandler: completionHandler)
  }
}
```

- Add URLSessionDelegate to URLSession
```swift
  self.urlSessionDelegate = YourSessionDelegate()
  self.urlSession = URLSession(configuration: .default, delegate: self.urlSessionDelegate, delegateQueue: nil)
```

## Working with WKWebView

- Implement WKNavigationDelegate
```swift
class YourNavigationDelegate: WKNavigationDelegate {
  private let ct: CertificateTransparency

  init() {
    let configuration = CertificateTransparencyConfiguration()
    ct = CertificateTransparency(configuration: configuration)
  }

  func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    ct.handleChallenge(with: challenge.protectionSpace, completionHandler: completionHandler)
  }
}
```

- Add WKNavigationDelegate to WKWebView

```swift
self.navigationDelegate = YourNavigationDelegate()
self.webView.navigationDelegate = self.navigationDelegate
```

## Add exceptions to ATS

https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity

To enable trust for custom trust anchor from URLSession/WkWebView App Trust Security (ATS) should be disabled.

- Disable ATS globally
```
Info.plist -> NSAppTransportSecurity -> NSAllowsArbitraryLoads = YES
```
- Disable ATS for WKWebView
```
Info.plist -> NSAppTransportSecurity -> NSAllowsArbitraryLoadsInWebContent = YES
```
- Disable ATS for some domains
```
Info.plist -> NSAppTransportSecurity -> NSExceptionDomains -> {
    <domain-name-string>: {
        NSIncludesSubdomains : YES/NO
        NSExceptionAllowsInsecureHTTPLoads : YES
    }
}
```
