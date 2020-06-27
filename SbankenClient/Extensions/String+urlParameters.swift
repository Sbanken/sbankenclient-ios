//
//  String+urlParameters.swift
//  SbankenClient
//
//  Created by Terje Tjervaag on 08/10/2017.
//  Copyright © 2017 SBanken. All rights reserved.
//

// https://stackoverflow.com/a/27724627

extension String {

    /// Percent escapes values to be added to a URL query as specified in RFC 3986
    ///
    /// This percent-escapes all characters besides the alphanumeric character set and "-", ".", "_", and "~".
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// - returns: Returns percent-escaped string.

    func addingPercentEncodingForURLQueryValue() -> String? {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: generalDelimitersToEncode + subDelimitersToEncode)

        return addingPercentEncoding(withAllowedCharacters: allowed)
    }
    
}

extension Dictionary {
    
    /// Build string representation of HTTP parameter dictionary of keys and objects
    ///
    /// This percent escapes in compliance with RFC 3986
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// - returns: String representation in the form of key1=value1&key2=value2
    ///            where the keys and values are percent escaped
    
    func stringFromHttpParameters() -> String {
        let parameterArray = compactMap { key, value -> String? in
            guard let key = key as? String, let value = value as? String else {
                return nil
            }
            let percentEscapedKey = key.addingPercentEncodingForURLQueryValue()!
            let percentEscapedValue = value.addingPercentEncodingForURLQueryValue()!
            return "\(percentEscapedKey)=\(percentEscapedValue)"
        }
        return parameterArray.joined(separator: "&")
    }
}
