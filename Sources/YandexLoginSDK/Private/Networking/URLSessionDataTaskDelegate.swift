
import Foundation

protocol URLSessionDataTaskDelegate {
    
    // delegate methods transmitted from URLSessionTaskDelegate instance
    
    func dataTask(
        _ task: URLSessionDataTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    )
    
    func dataTask(_ task: URLSessionDataTask, didCompleteWithError error: Error?)
    
    
    // delegate methods transmitted from URLSessionDataDelegate instance
    
    func dataTask(
        _ task: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    )
    
    func dataTask(_ task: URLSessionDataTask, didReceive data: Data)
    
}
