
import Foundation

enum StatesManager {
    
    static let storageCapacity = 50
    
    static func generateNewState() throws -> String {
        var object = try SharedStorages.statesStorage.loadObject()
        var state: String
        repeat {
            state = UUID().uuidString
        } while object[state] != nil
        
        while object.count >= self.storageCapacity {
            if let stateWithEarliestDate = self.stateWithEarliestDate(object) {
                object.removeValue(forKey: stateWithEarliestDate)
            } else {
                break
            }
        }
        
        if #available(iOS 15.0, *) {
            object[state] = Date.now
        } else {
            object[state] = Date()
        }
        
        try SharedStorages.statesStorage.save(object: object)
        return state
    }
    
    static func checkStateValidity(_ state: String) throws -> Bool {
        let states = try SharedStorages.statesStorage.loadObject()
        return states[state] != nil
    }
    
    static func remove(state: String) throws {
        var states = try SharedStorages.statesStorage.loadObject()
        states[state] = nil
        try SharedStorages.statesStorage.save(object: states)
    }
    
    static func removeAll() throws {
        try SharedStorages.statesStorage.removeObject()
    }
    
    private static func stateWithEarliestDate(_ object: [String: Date]) -> String? {
        var earliestDate: Date? = nil
        var stateWithEarliestDate: String? = nil
        
        for (state, date) in object {
            if let safeEarliestDate = earliestDate {
                if safeEarliestDate > date {
                    earliestDate = date
                    stateWithEarliestDate = state
                }
            } else{
                earliestDate = date
                stateWithEarliestDate = state
            }
        }
        
        return stateWithEarliestDate
    }
    
}
