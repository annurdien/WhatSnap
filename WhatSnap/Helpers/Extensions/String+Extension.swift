//
//  String+Formater.swift
//  whatsnap
//
//  Created by Annurdien Rasyid on 06/09/24.
//

import Foundation

extension String {
    func toPhoneNumberFormat(countryId: String) -> String {
        var cleanedPhoneNumber = self.filter { "0123456789".contains($0) }

        // If the number starts with "+" (already in international format), return it as is.
        if self.first == "+" {
            return self
        }
        
        // If the number starts with "0", replace it with the desired country code, e.g., +62
        if self.first == "0" {
            cleanedPhoneNumber.removeFirst() // Remove the leading "0"
            cleanedPhoneNumber = countryId + cleanedPhoneNumber
        }

        return cleanedPhoneNumber
    }
    
    func isValidPhoneNumber() -> Bool {
        let phoneRegex = "^[+]?[0-9]{6,15}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: self)
    }
}
