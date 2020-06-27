//
//  SbankenClient.swift
//  SbankenClient
//
//  Created by Terje Tjervaag on 07/10/2017.
//  Copyright © 2017 SBanken. All rights reserved.
//

import Foundation

open class SbankenClient: NSObject {
    var clientId: String?
    var secret: String?
    public var baseUrl: String? = Constants.baseUrl
    public var tokenManager: AccessTokenManager = AccessTokenManager()
    public var urlSession: SURLSessionProtocol = URLSession.shared
    public var decoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        
        jsonDecoder.dateDecodingStrategy = .custom({ decoder -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let length = dateString.count
            
            var date: Date?
            if length == 19 {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.calendar = Calendar(identifier: .iso8601)
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                formatter.locale = Locale(identifier: "en_US_POSIX")
                date = formatter.date(from: dateString)
            } else {
                date = ISO8601DateFormatter().date(from: dateString)
            }
            
            guard date != nil else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string \(dateString)")
            }
            
            return date!
        })
        
        return jsonDecoder
    }()
    public var encoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        return jsonEncoder
    }()

    public init(clientId: String?, secret: String?) {
        self.clientId = clientId
        self.secret = secret
    }
    
    public func accounts(userId: String,
                         success: @escaping ([Account]) -> Void,
                         failure: @escaping (Error?, String?) -> Void) {
        accessToken(clientId: clientId, secret: secret) { (token) in
            guard token != nil else {
                failure(ClientError.invalidToken, "Invalid or expired token")
                return
            }
            
            guard let baseUrl = self.baseUrl else {
                failure(ClientError.baseUrlNotSet, "BaseURL not set")
                return
            }
            
            let urlString = "\(baseUrl)/exec.bank/api/v1/Accounts"
            guard var request = self.urlRequest(urlString, token: token!) else { return }
            request.setValue(userId, forHTTPHeaderField: "CustomerID")
            
            self.urlSession.dataTask(with: request, completionHandler: { (data, _, error) in
                guard data != nil, error == nil else {
                    failure(error, "Requst failed or empty response")
                    return
                }
                
                if let accountsResponse = try? self.decoder.decode(AccountsResponse.self, from: data!) {
                    success(accountsResponse.items)
                } else {
                    failure(ClientError.responseDecodingFailed, "Could not decode AccountsResponse")
                }
            }).resume()
        }
    }
    
    public func cards(userId: String,
                      success: @escaping ([Card]) -> Void,
                      failure: @escaping (Error?, String?) -> Void) {
        accessToken(clientId: clientId, secret: secret) { (token) in
            guard token != nil else {
                failure(ClientError.invalidToken, "Invalid or expired token")
                return
            }
            
            guard let baseUrl = self.baseUrl else {
                failure(ClientError.baseUrlNotSet, "BaseURL not set")
                return
            }
            
            let urlString = "\(baseUrl)/exec.bank/api/v1/Cards"
            guard var request = self.urlRequest(urlString, token: token!) else { return }
            request.setValue(userId, forHTTPHeaderField: "CustomerID")
            
            self.urlSession.dataTask(with: request, completionHandler: { (data, _, error) in
                guard data != nil, error == nil else {
                    failure(error, "Requst failed or empty response")
                    return
                }
                
                self.decoder.dataDecodingStrategy = .deferredToData
                
                if let response = try? self.decoder.decode(CardsResponse.self, from: data!) {
                    success(response.items)
                } else {
                    failure(ClientError.responseDecodingFailed, "Could not decode CardsResponse")
                }
            }).resume()
        }
    }
    
    public func transactions(userId: String,
                             accountId: String,
                             startDate: Date,
                             endDate: Date = Date(),
                             index: Int = 0,
                             length: Int = 10,
                             success: @escaping (TransactionResponse) -> Void,
                             failure: @escaping (Error?) -> Void) {
        accessToken(clientId: clientId, secret: secret) { (token) in
            guard token != nil else {
                failure(nil)
                return
            }
            
            let formatter = ISO8601DateFormatter()
            let parameters = [
                "index": "\(index)",
                "length": "\(length)",
                "startDate": formatter.string(from: startDate),
                "endDate": formatter.string(from: endDate)
                ] as [String: Any]

            guard let baseUrl = self.baseUrl else {
                failure(ClientError.baseUrlNotSet)
                return
            }
            
            let urlString = "\(baseUrl)/exec.bank/api/v1/Transactions/\(accountId)"
            guard var request = self.urlRequest(urlString, token: token!, parameters: parameters) else { return }
            request.setValue(userId, forHTTPHeaderField: "CustomerID")
            
            self.urlSession.dataTask(with: request, completionHandler: { (data, _, error) in
                guard data != nil, error == nil else {
                    failure(error)
                    return
                }
                
                if let transactionResponse = try? self.decoder.decode(TransactionResponse.self, from: data!) {
                    success(transactionResponse)
                } else {
                    failure(nil)
                }
            }).resume()
        }
    }
    
    public func transfer(userId: String,
                         fromAccount: String,
                         toAccount: String,
                         message: String,
                         amount: Float,
                         success: @escaping (TransferResponse) -> Void,
                         failure: @escaping (Error?) -> Void) {
        accessToken(clientId: clientId, secret: secret) { (token) in
            guard token != nil else {
                failure(nil)
                return
            }
            
            guard let baseUrl = self.baseUrl else {
                failure(ClientError.baseUrlNotSet)
                return
            }
            
            let urlString = "\(baseUrl)/exec.bank/api/v1/Transfers"
            guard var request = self.urlRequest(urlString, token: token!) else { return }
            
            let transferRequest = TransferRequest(fromAccountId: fromAccount,
                                                  toAccountId: toAccount,
                                                  message: message,
                                                  amount: amount)
            
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(userId, forHTTPHeaderField: "CustomerID")
            
            if let body = try? self.encoder.encode(transferRequest) {
                request.httpBody = body
            } else {
                failure(nil)
            }
            
            self.urlSession.dataTask(with: request, completionHandler: { (data, _, error) in
                guard data != nil, error == nil else {
                    failure(error)
                    return
                }
                
                if let transferResponse = try? self.decoder.decode(TransferResponse.self, from: data!) {
                    if transferResponse.isError {
                        failure(nil)
                    } else {
                        success(transferResponse)
                    }
                } else {
                    failure(nil)
                }
            }).resume()
        }
    }
    
    public func efaktura(userId: String,
                         eFakturaId: String,
                         success: @escaping (EFakturaResponse) -> Void,
                         failure: @escaping (Error?) -> Void) {
        accessToken(clientId: clientId, secret: secret) { (token) in
            guard token != nil else {
                failure(nil)
                return
            }

            let urlString = "\(Constants.baseUrl)/exec.bank/api/v1/EFakturas/\(eFakturaId)"
            
            guard var request = RequestHelper.urlRequest(urlString,
                                                         token: token!,
                                                         parameters: [:]) else { return }

            request.setValue(userId, forHTTPHeaderField: "CustomerID")

            self.urlSession.dataTask(with: request, completionHandler: { (data, _, error) in
                guard data != nil, error == nil else {
                    failure(error)
                    return
                }
                
                if let eFakturaResponse = try? self.decoder.decode(EFakturaResponse.self, from: data!) {
                    if eFakturaResponse.isError {
                        failure(nil)
                    } else {
                        success(eFakturaResponse)
                    }
                } else {
                    failure(nil)
                }
            }).resume()
        }
    }

    public func eFakturas(userId: String,
                          startDate: Date,
                          endDate: Date = Date(),
                          status: String = "ALL",
                          length: Int = 100,
                          index: Int = 0,
                          success: @escaping (EFakturasResponse) -> Void,
                          failure: @escaping (Error?) -> Void) {
        accessToken(clientId: clientId, secret: secret) { (token) in
            guard token != nil else {
                failure(nil)
                return
            }

            let urlString = "\(Constants.baseUrl)/exec.bank/api/v1/EFakturas"
            let formatter = ISO8601DateFormatter()
            let parameters = [
                "index": "\(index)",
                "length": "\(length)",
                "startDate": formatter.string(from: startDate),
                "endDate": formatter.string(from: endDate),
                "status": status
                ] as [String: Any]

            guard var request = RequestHelper.urlRequest(urlString,
                                                         token: token!,
                                                         parameters: parameters) else { return }

            request.setValue(userId, forHTTPHeaderField: "CustomerID")

            self.urlSession.dataTask(with: request, completionHandler: { (data, huh, error) in
                guard data != nil, error == nil else {
                    failure(error)
                    return
                }
                
                if let eFakturasResponse = try? self.decoder.decode(EFakturasResponse.self, from: data!) {
                    if eFakturasResponse.isError {
                        failure(nil)
                    } else {
                        success(eFakturasResponse)
                    }
                } else {
                    failure(nil)
                }
            }).resume()
        }
    }
    
    public func payEFaktura(userId: String,
                            eFakturaId: String,
                            fromAccountId: String,
                            payMinimumAmount: Bool,
                            success: @escaping (EFakturaPaymentResponse) -> Void,
                            failure: @escaping (Error?) -> Void) {
        accessToken(clientId: clientId, secret: secret) { (token) in
            guard token != nil else {
                failure(nil)
                return
            }
            
            let urlString = "\(Constants.baseUrl)/exec.bank/api/v1/EFakturas"
            guard var request = RequestHelper.urlRequest(urlString,
                                                         token: token!) else { return }
            
            let paymentRequest = EFakturaPaymentRequest(eFakturaId: eFakturaId,
                                                        accountId: fromAccountId,
                                                        payOnlyMinimumAmount: payMinimumAmount)
            
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(userId, forHTTPHeaderField: "CustomerID")
            
            if let body = try? self.encoder.encode(paymentRequest) {
                request.httpBody = body
            } else {
                failure(nil)
            }
            
            self.urlSession.dataTask(with: request, completionHandler: { (data, _, error) in
                guard data != nil, error == nil else {
                    failure(error)
                    return
                }
                
                if let paymentResponse = try? self.decoder.decode(EFakturaPaymentResponse.self, from: data!) {
                    if paymentResponse.isError {
                        failure(nil)
                    } else {
                        success(paymentResponse)
                    }
                } else {
                    failure(nil)
                }
            }).resume()
        }
    }
    
    public func urlRequest(_ urlString: String, token: AccessToken, parameters: [String: Any]) -> URLRequest? {
        guard var request = urlRequest(urlString, token: token) else { return nil }
        guard let originalUrl = request.url?.absoluteString else { return nil }
        
        request.url = URL(string: "\(originalUrl)?\(parameters.stringFromHttpParameters())")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        return request
    }
    
    public func urlRequest(_ urlString: String, token: AccessToken?) -> URLRequest? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        if token != nil {
            request.setValue("Bearer \(token!.accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return request
    }
    
    open func accessToken(clientId: String?, secret: String?, completion: @escaping (AccessToken?) -> Void) {
        if tokenManager.token != nil {
            completion(tokenManager.token!)
            return
        }
        
        guard let clientId = clientId, let secret = secret else { return }
        
        let characterSet = NSMutableCharacterSet.alphanumeric()
        characterSet.addCharacters(in: "-_.!~*'()")
        
        let encodedClientId = clientId.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet)
        let encodedsecret = secret.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet)
        
        let credentialData = "\(encodedClientId!):\(encodedsecret!)".data(using: .utf8)!
        let encodedCredentials = credentialData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        
        let url = URL(string: "\(Constants.baseAuthUrl)/identityserver/connect/token")
        var request = URLRequest(url: url!)
        
        [
            "Authorization": "Basic \(encodedCredentials)",
            "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
            "Accept": "application/json"
        ].forEach { (key, value) in request.setValue(value, forHTTPHeaderField: key) }
        
        request.httpMethod = "POST"
        request.httpBody = "grant_type=client_credentials".data(using: .utf8)
        
        self.urlSession.dataTask(with: request,
                                 completionHandler: { (data, _, error) in
            guard data != nil, error == nil else {
                completion(nil)
                return
            }
            
            if let token = try? self.decoder.decode(AccessToken.self, from: data!) {
                self.tokenManager.token = token
            }
            
            completion(self.tokenManager.token)
        }).resume()
    }
}
