
import Foundation

protocol ResponseParser {
    
    func parseData(_ data: Data) throws -> String
    
}
