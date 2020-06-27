//
//  EFaktura.swift
//  SbankenClient
//
//  Created by Øyvind Tjervaag on 21/08/2018.
//  Copyright © 2018 SBanken. All rights reserved.
//

import Foundation

public class EFaktura: Codable {
    public let eFakturaId: String
    public let issuerId: String
    public let eFakturaReference: String
    public let documentType: String
    public let status: String
    public let kid: String
    public let originalDueDate: Date?
    public let originalAmount: Double
    public let minimumAmount: Double
    public let updatedDueDate: Date?
    public let updatedAmount: Double
    public let notificationDate: Date?
    public let creditAccountNumber: String
    public let issuerName: String
}
