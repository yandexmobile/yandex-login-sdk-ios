
import Foundation

struct SecureStorage<Value: Codable>: Storage {
    
    typealias ObjectValue = Value
    
    private let keychainQueryBase: [CFString: Any]
    
    init(key: String) {
        self.keychainQueryBase = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: key,
            kSecAttrAccount: key
        ]
    }
    
    func loadObject() throws -> [String: Value] {
        var query = keychainQueryBase
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne
        
        var object: AnyObject? = nil
        SecItemCopyMatching(query as CFDictionary, &object)
        
        guard let object else { throw StorageError.nilObjectReturnedFromSecureStorage }
        
        guard let data = object as? Data else {
            let objectType = "\(type(of: object))"
            throw StorageError.couldntReadDataFromSecureStorage(objectType: objectType)
        }
        
        return try StorageUtilities.unarchive(data)
    }
    
    func save(object: [String: Value]) throws {
        SecItemDelete(self.keychainQueryBase as CFDictionary)
        
        var query = self.keychainQueryBase
        query[kSecValueData] = try StorageUtilities.archive(object)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func removeObject() {
        SecItemDelete(self.keychainQueryBase as CFDictionary)
    }
    
}
