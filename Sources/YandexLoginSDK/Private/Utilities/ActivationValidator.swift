
import Foundation

enum ActivationValidator {
    
    static func validateActivation(
        with clientID: String,
        authorizationStrategy: YandexLoginSDK.AuthorizationStrategy
    ) throws {
        if let primacies = ApplicationPrimacy.primacies(for: authorizationStrategy) {
            for primacy in primacies {
                guard self.infoDictionaryContainsQueriesScheme(primacy.scheme) else {
                    throw ActivationError.absentQueriesScheme(scheme: primacy.scheme, primacies: primacies)
                }
            }
        }
        
        let redirectDeepLinkURLScheme = URLUtilities.urlSchemeDefinedBySDK(forAppWith: clientID)
        if self.infoDictionaryContainsURLTypesScheme(redirectDeepLinkURLScheme) == false {
            throw ActivationError.absentURLTypesScheme(scheme: redirectDeepLinkURLScheme)
        }
    }
    
    private static func infoDictionaryContainsURLTypesScheme(_ scheme: String) -> Bool {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let urlTypes = infoDictionary["CFBundleURLTypes"] as? [[String: Any]]
        else { return false }
        
        for urlType in urlTypes {
            guard let urlSchemes = urlType["CFBundleURLSchemes"] as? [String] else { continue }
                
            if urlSchemes.contains(scheme) { return true }
        }
        
        return false
    }
    
    private static func infoDictionaryContainsQueriesScheme(_ scheme: String) -> Bool {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let queriesSchemes = infoDictionary["LSApplicationQueriesSchemes"] as? [String]
        else { return false }
        
        return queriesSchemes.contains(scheme)
    }
    
}
