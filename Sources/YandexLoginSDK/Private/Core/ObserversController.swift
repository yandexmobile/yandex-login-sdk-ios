
import Foundation

struct ObserversController {
    
    private let synchronizationQueue = DispatchQueue(
        label: "ru.yandex.login-sdk.observers-controller.synchronization-queue.\(UUID().uuidString)"
    )
    
    private var observers: [any YandexLoginSDKObserver] = []
    
    mutating func add(_ observer: any YandexLoginSDKObserver) {
        synchronizationQueue.sync {
            observers.append(observer)
        }
    }
    
    mutating func remove(_ observer: any YandexLoginSDKObserver) {
        synchronizationQueue.sync {
            observers.removeAll { $0 === observer }
        }
    }
    
    func notifyLoginDidFinish(with result: Result<LoginResult, any Error>) {
        synchronizationQueue.sync {
            observers.forEach { $0.didFinishLogin(with: result) }
        }
    }
    
}
