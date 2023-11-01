
import CommonCrypto
import CryptoKit
import Foundation

enum CryptoUtilities {
    
    static func base64URLEncodedString(from data: Data) -> String {
        let base64 = data.base64EncodedString()

        let urlEncoding: [Character: String] = ["+": "-", "/": "_", "=": ""]
        let base64URLEncoded = base64.reduce("") { $0 + (urlEncoding[$1] ?? String($1)) }
        
        return base64URLEncoded
    }
    
    static func sha256(from data: Data) -> Data {
        if #available(iOS 13.0, *) {
            return sha256UsingCryptoKit(from: data)
        } else {
            return sha256UsingCommonCrypto(from: data)
        }
    }
    
    @available(iOS 13.0, *)
    private static func sha256UsingCryptoKit(from data: Data) -> Data {
        let digest = SHA256.hash(data: data)
        var hashedData = Data(capacity: SHA256.byteCount)
        for byte in digest {
            hashedData.append(byte)
        }
        
        return hashedData
    }
    
    private static func sha256UsingCommonCrypto(from data: Data) -> Data {
        var digest = Array<UInt8>(repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        var hashedData = Data(capacity: Int(CC_SHA256_DIGEST_LENGTH))
        let _ = data.withUnsafeBytes { buffer in
            CC_SHA256(buffer.baseAddress, UInt32(data.count), &digest)
        }
        for byte in digest {
            hashedData.append(byte)
        }
        
        return hashedData
    }
    
}
