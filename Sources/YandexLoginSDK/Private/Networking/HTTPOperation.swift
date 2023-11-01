
import Foundation

final class HTTPOperation: Hashable {
    
    typealias ChallengeHandler = (
        URLAuthenticationChallenge,
        @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) -> Void
    typealias SuccessHandler = (HTTPOperation, URLResponse, Data) -> Void
    typealias FailureHandler = (HTTPOperation, Error) -> Void
    
    private let uuid = UUID()
    
    private let request: URLRequest
    private let challengeHandler: ChallengeHandler
    private let successHandler: SuccessHandler
    private let failureHandler: FailureHandler
    
    private var task: URLSessionDataTask?
    private var response: URLResponse?
    private var responseData: Data?
    
    init(
        request: URLRequest,
        onChallenge challengeHandler: @escaping ChallengeHandler,
        onSuccess successHandler: @escaping SuccessHandler,
        onFailure failureHandler: @escaping FailureHandler
    ) {
        self.request = request
        self.challengeHandler = challengeHandler
        self.successHandler = successHandler
        self.failureHandler = failureHandler
    }
    
    func start() throws {
        guard self.task == nil else {
            throw NetworkingError.httpOperationAlreadyStarted
        }
        
        DispatchQueue.main.async {
            self.responseData = Data()
            self.response = nil
            self.task = SessionManager.shared.dataTask(with: self.request, delegate: self)
            self.task?.resume()
        }
    }
    
    func cancel() {
        DispatchQueue.main.async {
            self.task?.cancel()
        }
    }
    
    // Conformance to Hashable
    
    static func == (lhs: HTTPOperation, rhs: HTTPOperation) -> Bool {
        lhs.uuid == rhs.uuid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.uuid)
    }
    
}

// MARK: - URL session data task delegate

extension HTTPOperation: URLSessionDataTaskDelegate {
    
    func dataTask(
        _ task: URLSessionDataTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        self.challengeHandler(challenge, completionHandler)
    }
    
    func dataTask(_ task: URLSessionDataTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let error {
                self.failureHandler(self, error)
            } else if let response = self.response, let responseData = self.responseData {
                self.successHandler(self, response, responseData)
            }
            
            self.task = nil
            self.response = nil
            self.responseData = nil
        }
    }
    
    func dataTask(
        _ task: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        self.response = response
    }
    
    func dataTask(_ task: URLSessionDataTask, didReceive data: Data) {
        self.responseData?.append(data)
    }
    
}
