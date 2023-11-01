
protocol Storage {
    
    associatedtype ObjectValue: Codable
    
    func loadObject() throws -> [String: ObjectValue]
    func save(object: [String: ObjectValue]) throws
    func removeObject() throws
    
}
