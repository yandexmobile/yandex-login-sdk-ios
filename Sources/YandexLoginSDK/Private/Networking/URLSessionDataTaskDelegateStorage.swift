
import Foundation

final class URLSessionDataTaskDelegateStorage {
    
    private var delegates: [Int: any URLSessionDataTaskDelegate] = [:]
    private var synchronizationQueue = DispatchQueue(
        label: "ru.yandex.login-sdk.url-session-data-task-delegate-storage.synchronization-queue"
    )
    
    func getDelegate(for dataTask: URLSessionDataTask) -> (any URLSessionDataTaskDelegate)? {
        var delegate: (any URLSessionDataTaskDelegate)? = nil
        synchronizationQueue.sync {
            delegate = delegates[dataTask.taskIdentifier]
        }
        return delegate
    }
    
    func setDelegate(_ delegate: any URLSessionDataTaskDelegate, for dataTask: URLSessionDataTask) {
        synchronizationQueue.sync {
            delegates[dataTask.taskIdentifier] = delegate
        }
    }
    
    func removeDelegate(for dataTask: URLSessionDataTask) {
        synchronizationQueue.sync {
            delegates[dataTask.taskIdentifier] = nil
        }
    }
    
}
