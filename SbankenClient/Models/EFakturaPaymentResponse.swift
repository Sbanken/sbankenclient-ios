//
//  EFakturaPaymentResponse.swift
//  SbankenClient
//
//  Created by Øyvind Tjervaag on 21/08/2018.
//  Copyright © 2018 SBanken. All rights reserved.
//

import Foundation

public struct EFakturaPaymentResponse: Codable {
    public var errorType: String
    public var isError: Bool
    public var errorMessage: String
    public var traceId: String
}
