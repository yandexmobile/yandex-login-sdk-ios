
import Foundation

final class SessionManager: NSObject {
    
    private(set) lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    private var delegateStorage = URLSessionDataTaskDelegateStorage()
    
    static let shared = SessionManager()
    
    private override init() { super.init() }
    
    func dataTask(with request: URLRequest, delegate: any URLSessionDataTaskDelegate) -> URLSessionDataTask {
        let dataTask = self.session.dataTask(with: request)
        self.delegateStorage.setDelegate(delegate, for: dataTask)
        
        return dataTask
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
        guard let dataTask = task as? URLSessionDataTask else { return }
        
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
