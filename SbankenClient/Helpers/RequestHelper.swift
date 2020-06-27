//
//  RequestHelper.swift
//  SbankenClient
//
//  Created by Terje Tjervaag on 20/09/2018.
//  Copyright © 2018 SBanken. All rights reserved.
//

class RequestHelper {
    
    static func urlRequest(_ urlString: String, token: AccessToken, parameters: [String: Any]) -> URLRequest? {
        guard var request = urlRequest(urlString, token: token) else { return nil }
        guard let originalUrl = request.url?.absoluteString else { return nil }
        
        request.url = URL(string: "\(originalUrl)?\(parameters.stringFromHttpParameters())")
        
        return request
    }
    
    static func urlRequest(_ urlString: String, token: AccessToken) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return request
    }
}
