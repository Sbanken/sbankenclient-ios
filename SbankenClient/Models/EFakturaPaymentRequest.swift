//
//  EFakturaPaymentRequest.swift
//  SbankenClient
//
//  Created by Øyvind Tjervaag on 21/08/2018.
//  Copyright © 2018 SBanken. All rights reserved.
//

import Foundation

public struct EFakturaPaymentRequest: Codable {
    public var eFakturaId: String
    public var accountId: String
    public var payOnlyMinimumAmount: Bool
}
