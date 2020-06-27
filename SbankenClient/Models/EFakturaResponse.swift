//
//  EFakturaResponse.swift
//  SbankenClient
//
//  Created by Øyvind Tjervaag on 17/10/2019.
//  Copyright © 2019 SBanken. All rights reserved.
//

import Foundation

public struct EFakturaResponse: Codable {
    public var item: EFaktura
    
    public var errorType: String?
    public var isError: Bool
    public var errorMessage: String?
    public var traceId: String?
}
