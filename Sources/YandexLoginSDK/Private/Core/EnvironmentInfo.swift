
import Foundation
import UIKit

enum EnvironmentInfo {
    
    enum Parameter: String {
        
        case platform = "app_platform"
        case manufacturer
        case model
        case deviceName = "device_name"
        case identifierForVendor = "ifv"
        case appID = "app_id"
        case appVersion = "app_version"
        
    }
    
    static var parametersWithStringKeys: [String: String] {
        var parameters: [String: String] = [:]
        
        for (key, value) in self.parameters {
            parameters[key.rawValue] = value
        }
        
        return parameters
    }
    
    static var parameters: [Parameter: String] {
        var parameters: [Parameter: String] = [
            .platform: UIDevice.current.model,
            .manufacturer: "Apple",
            .model: self.model,
            .deviceName: UIDevice.current.name,
        ]
        
        if let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString {
            parameters[.identifierForVendor] = identifierForVendor
        }
        
        if let appID = Bundle.main.bundleIdentifier {
            parameters[.appID] = appID
        }
        
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            parameters[.appVersion] = appVersion
        }
        
        return parameters
    }
    
    private static var model: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = systemInfo.machine
        
        /*
         There is an alternative solution for problem of data extraction from `machine`.
         
         `machine` is a tuple (not an array!) consisting of 256 CChar elements. We need to represent that tuple as an
         array of CChar to then convert that array to String using .init(cString:) where cString argument is [CChar].
         Current solution uses Mirror object that represents structure of the `machine` and extranct it's elements to
         the children property.
         
         The alternative solution is to use unsafe Swift pointers to directly access region of memory where `machine`
         is located. This solution is unsecure and raises a warning due to the fact that compiler optimization may
         deallocate object that is pointed to. Nevertheless, I consider it necessary to leave this option in a code
         at least as a comment.
         
         ```
         let pointer = UnsafeRawPointer(&machine).bindMemory(to: CChar.self, capacity: 256)
         let model = String(cString: pointer)
         ```
         */
        
        let mirror = Mirror(reflecting: machine)
        let cString = mirror.children.compactMap { $0.value as? CChar}
        let model = String(cString: cString)
        
        return model
    }
    
}
