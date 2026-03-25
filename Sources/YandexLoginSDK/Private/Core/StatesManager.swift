
import Foundation

enum StatesManager {
    
    static let storageCapacity = 50

    static func generateNewState(clientID: String? = nil) throws -> String {
        let storage = clientID != nil ? SpecializedStorages.statesStorage(clientID: clientID!) : SharedStorages.statesStorage

        var object = try storage.loadObject()
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
        
        try storage.save(object: object)
        return state
    }

    static func checkStateValidity(_ state: String, clientID: String? = nil) throws -> Bool {
        let storage = clientID != nil ? SpecializedStorages.statesStorage(clientID: clientID!) : SharedStorages.statesStorage

        let states = try storage.loadObject()
        return states[state] != nil
    }

    static func remove(state: String, clientID: String? = nil) throws {
        let storage = clientID != nil ? SpecializedStorages.statesStorage(clientID: clientID!) : SharedStorages.statesStorage
        var states = try storage.loadObject()
        states[state] = nil
        try storage.save(object: states)
    }
    
    static func removeAll(clientID: String? = nil) throws {
        let storage = clientID != nil ? SpecializedStorages.statesStorage(clientID: clientID!) : SharedStorages.statesStorage
        try storage.removeObject()
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
