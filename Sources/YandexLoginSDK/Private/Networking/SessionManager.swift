
import Foundation
#if SWIFT_PACKAGE
import CertificateTransparency
#endif

final class SessionManager: NSObject {
    
    private(set) lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private let certificateTransparency = CertificateTransparency()
    private var delegateStorage = URLSessionDataTaskDelegateStorage()
    
    static let shared = SessionManager()
    
    private override init() { super.init() }
    
    func dataTask(with request: URLRequest, delegate: any URLSessionDataTaskDelegate) -> URLSessionDataTask {
        let dataTask = self.session.dataTask(with: request)
        self.delegateStorage.setDelegate(delegate, for: dataTask)
        
        return dataTask
    }
    
}

// MARK: - URLSessionDelegate

extension SessionManager {

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        self.certificateTransparency.handleChallenge(
            with: challenge.protectionSpace,
            completionHandler: completionHandler
        )
    }

}

// MARK: - URLSessionTaskDelegate

extension SessionManager: URLSessionTaskDelegate {
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            self.certificateTransparency.handleChallenge(
                with: challenge.protectionSpace,
                completionHandler: completionHandler
            )
            return
        }

        guard let dataTask = task as? URLSessionDataTask else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        if let delegate = self.delegateStorage.getDelegate(for: dataTask) {
            delegate.dataTask(dataTask, didReceive: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let dataTask = task as? URLSessionDataTask else { return }
        
        let delegate = self.delegateStorage.getDelegate(for: dataTask)
        delegate?.dataTask(dataTask, didCompleteWithError: error)
        
        self.delegateStorage.removeDelegate(for: dataTask)
    }
    
}

// MARK: - URLSessionDataDelegate

extension SessionManager: URLSessionDataDelegate {
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        let delegate = self.delegateStorage.getDelegate(for: dataTask)
        delegate?.dataTask(dataTask, didReceive: response, completionHandler: completionHandler)
        
        completionHandler(.allow)
    }
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        let delegate = self.delegateStorage.getDelegate(for: dataTask)
        delegate?.dataTask(dataTask, didReceive: data)
    }
    
}
