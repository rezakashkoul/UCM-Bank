import Foundation
import NotificationBannerSwift

enum ValidationRule { case none, username, password, textName, ssn, email, tel, unitNumber, streetNumber, postalCode, province, bankID, amount }

extension ValidationRule {
    
    func isValid(text: String, shouldShowError: Bool = true) -> Bool {
        switch self {
        case .none: return true
        case .username:
            return isValidUsername(text: text, shouldShowError: shouldShowError)
        case .password:
            return isValidPassword(text: text, shouldShowError: shouldShowError)
        case .textName:
            return isValidTextName(text: text, shouldShowError: shouldShowError)
        case .ssn:
            return isValidSSN(text: text, shouldShowError: shouldShowError)
        case .email:
            return isValidEmail(text: text, shouldShowError: shouldShowError)
        case .tel:
            return isValidTel(text: text, shouldShowError: shouldShowError)
        case .unitNumber:
            return isValidUnitNumber(text: text, shouldShowError: shouldShowError)
        case .streetNumber:
            return isValidStreetNumber(text: text, shouldShowError: shouldShowError)
        case .postalCode:
            return isValidPostalCode(text: text, shouldShowError: shouldShowError)
        case .province:
            return isValidProvince(text: text, shouldShowError: shouldShowError)
        case .bankID:
            return isValidBankID(id: text, shouldShowError: shouldShowError)
        case .amount:
            return isValidAmount(text: text, shouldShowError: shouldShowError)
        }
    }
    
    func isValidUsername(text: String, shouldShowError: Bool = true)-> Bool {
        let regex = "\\w{8,32}"
        let username = NSPredicate(format:"SELF MATCHES %@", regex)
        let isValid = username.evaluate(with: text) && text.count >= 8
        if isValid {
            return true
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Username is not valid", style: .danger)
            }
            return false
        }
    }
    
    func isValidPassword(text: String, shouldShowError: Bool = true)-> Bool {
        let regex = "(?=[^a-z]*[a-z])(?=.*[!@#$&*])[^0-9]*[0-9].*"
        let password = NSPredicate(format: "SELF MATCHES %@", regex)
        let isValid = password.evaluate(with: text) && text.count >= 8 && text .count <= 32
        if isValid {
            return true
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please check password!", style: .danger)
            }
            return false
        }
    }
    
    func isValidSSN(text: String, shouldShowError: Bool = true)-> Bool {
        let isValid = text.count == 9
        if isValid {
            return true
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "SSN is not valid", style: .danger)
            }
            return false
        }
    }
    
    func isValidEmail(text: String, shouldShowError: Bool = true)-> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let email = NSPredicate(format:"SELF MATCHES %@", regex)
        if email.evaluate(with: text) {
            return true
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Email is not valid", style: .danger)
            }
            return false
        }
    }
    
    func isValidTel(text: String, shouldShowError: Bool = true)-> Bool {
        let validNumber = Int(text)?.description.count == 10
        if validNumber {
            return true
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Tel number is not valid", style: .danger)
            }
            return false
        }
    }
    
    func isValidUnitNumber(text: String, shouldShowError: Bool = true)-> Bool {
        if let unitNumber = Int(text)?.description.count {
            return unitNumber <= 4
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Unit number is not valid", style: .danger)
            }
            return false
        }
    }
    
    func isValidStreetNumber(text: String, shouldShowError: Bool = true)-> Bool {
        if let streetNumber = Int(text)?.description.count {
            return streetNumber <= 6
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Street number is not valid", style: .danger)
            }
            return false
        }
    }
    
    func isValidPostalCode(text: String, shouldShowError: Bool = true)-> Bool {
        let regex = "(^[a-zA-Z][0-9][a-zA-Z][- ]*[0-9][a-zA-Z][0-9]$)"
        let postalCode = NSPredicate(format: "SELF MATCHES %@", regex)
        let isValid = postalCode.evaluate(with: text) as Bool
        if isValid {
            return true
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Postal code is not valid", style: .danger)
            }
            return false
        }
    }
    
    func isValidProvince(text: String, shouldShowError: Bool = true)-> Bool {
        let isValid = provinces.contains(text)
        if isValid {
            return true
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "State is not valid", style: .danger)
            }
            return false
        }
    }
    
    func isValidBankID(id: String, shouldShowError: Bool = true)-> Bool {
        let isValid = id.count == 11
        if isValid {
            return true
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "The Bank ID is not valid", style: .danger)
            }
            return false
        }
    }
    
    func isValidPayeeID(id: String, shouldShowError: Bool = true)-> Bool {
        let regex = "^[0-9]*$"
        let title = NSPredicate(format: "SELF MATCHES %@", regex)
        let isValid = title.evaluate(with: id) && 1...11 ~= id.count && id != "0"
        if isValid {
            return true
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "The Payee ID is not valid", style: .danger)
            }
            return false
        }
    }
    
    func isValidTextName(text: String, shouldShowError: Bool = true)-> Bool {
        let regex = "[a-zA-Z\\s']+"
        let title = NSPredicate(format: "SELF MATCHES %@", regex)
        let isValid = title.evaluate(with: text) && text.count >= 3 && text .count <= 30
        if isValid {
            return true
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please check the text!", style: .danger)
            }
            return false
        }
    }
    
    func isValidAmount(text: String, shouldShowError: Bool = true)-> Bool {
        let regex = "^[1-9][0-9]*$"
        let title = NSPredicate(format: "SELF MATCHES %@", regex)
        let isValid = title.evaluate(with: Int(text)?.description)
        if isValid {
            return true
        } else {
            if shouldShowError {
                BannerManager.showMessage(messageText: "Error", messageSubtitle: "Please check amount!", style: .danger)
            }
            return false
        }
    }
}
