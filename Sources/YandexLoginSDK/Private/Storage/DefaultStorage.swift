
import Foundation

struct DefaultStorage<Value: Codable>: Storage {
    
    typealias ObjectValue = Value
    
    private let objectURL: URL
    
    init(key: String) {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Couldn't create url for caches directory in user domain.")
        }
        
        if #available(iOS 16.0, *) {
            self.objectURL = url.appending(path: key)
        } else {
            self.objectURL = url.appendingPathComponent(key)
        }
    }
    
    func loadObject() throws -> [String: Value] {
        guard let data = try? Data(contentsOf: self.objectURL) else { return [:] }
        return try StorageUtilities.unarchive(data)
    }
    
    func save(object: [String: Value]) throws {
        let data = try StorageUtilities.archive(object)
        try data.write(to: self.objectURL, options: .atomic)
    }
    
    func removeObject() throws {
        try FileManager.default.removeItem(at: self.objectURL)
    }
    
}
