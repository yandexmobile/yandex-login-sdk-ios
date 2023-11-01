
enum StorageError: YandexLoginSDKError {
    
    case nilObjectReturnedFromSecureStorage
    case couldntReadDataFromSecureStorage(objectType: String)
    
    var message: String {
        let message: String
        
        switch self {
        case .nilObjectReturnedFromSecureStorage:
            message = "Couldn't read data from keychain. The returned object is nil."
        case .couldntReadDataFromSecureStorage(let objectType):
            message = """
                      Couldn't cast object read from keychain to Data.
                      - object type: \(objectType)
                      """
        }
        
        return message
    }
    
}
