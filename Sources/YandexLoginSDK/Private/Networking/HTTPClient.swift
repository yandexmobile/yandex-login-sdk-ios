
import Foundation

final class HTTPClient {
    
    typealias SuccessHandler = (String) -> Void
    typealias FailureHandler = (Error) -> Void
    
    private var operations: Set<HTTPOperation> = []
    
    func executeRequest(
        with requestComponents: any RequestComponentsProvider,
        onSuccess successHandler: @escaping SuccessHandler,
        onFailure failureHandler: @escaping FailureHandler
    ) throws {
        assert(
            Thread.isMainThread,
            "executeRequestWithComponents(_:onSuccess:onFailure:) method must be executed on the main thread."
        )
        
        let request = try self.urlRequest(with: requestComponents)
        
        let operation = HTTPOperation(
            request: request,
            onChallenge: { _, completionHandler in
                completionHandler(.performDefaultHandling, nil)
            },
            onSuccess: { [weak self] operation, response, data in
                assert(
                    Thread.isMainThread,
                    "Success handler must be executed on the main thread."
                )
                
                self?.operation(
                    with: requestComponents,
                    didFinishWith: response,
                    data: data,
                    onSuccess: successHandler,
                    onFailure: failureHandler
                )
                
                self?.operations.remove(operation)
            },
            onFailure: { [weak self] operation, error in
                assert(
                    Thread.isMainThread,
                    "Failure handler must be executed on the main thread."
                )

                failureHandler(error)
                self?.operations.remove(operation)
            }
        )
        
        self.operations.insert(operation)
        try operation.start()
    }
    
    func cancelAllRequests() throws {
        assert(
            Thread.isMainThread,
            "cancelAllRequests() method must be executed on the main thread."
        )
        
        self.operations.forEach { $0.cancel() }
        self.operations.removeAll()
    }
    
    private func operation(
        with requestComponents: any RequestComponentsProvider,
        didFinishWith response: URLResponse,
        data: Data,
        onSuccess successHandler: SuccessHandler,
        onFailure failureHandler: FailureHandler
    ) {
        do {
            try validateResponse(response)
            try validateData(data)
            let parseResult = try self.parseData(data, with: requestComponents)
            successHandler(parseResult)
        } catch {
            failureHandler(error)
        }
    }
    
    private func parseData(_ data: Data, with components: any RequestComponentsProvider) throws -> String {
        guard let parser = ResponseParserFactory.parser(for: components) else {
            let type = "\(type(of: components))"
            throw NetworkingError.unknownRequestComponentsProviderType(type: type)
        }
        
        return try parser.parseData(data)
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpURLResponse = response as? HTTPURLResponse else {
            let responseType = "\(type(of: response))"
            throw NetworkingError.invalidResponseType(type: responseType)
        }
        
        guard 200..<300 ~= httpURLResponse.statusCode else {
            throw NetworkingError.badStatusCode(code: httpURLResponse.statusCode)
        }
    }
    
    private func validateData(_ data: Data) throws {
        guard data.isEmpty == false else {
            throw NetworkingError.emptyDataObject
        }
    }
    
    private func urlRequest(with components: any RequestComponentsProvider) throws -> URLRequest {
        let (urlAsString, parameters) = (components.urlAsString, components.parameters)
        
        guard let url = URL(string: urlAsString) else {
            throw NetworkingError.couldntCreateURLFromString(urlAsString)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if parameters.isEmpty == false {
            let query = try QueryUtilities.query(from: parameters)
            guard let httpBody = query.data(using: .utf8) else {
                throw NetworkingError.couldntCreateDataFromString(query)
            }
            request.httpBody = httpBody
        }
        
        return request
    }
    
}
