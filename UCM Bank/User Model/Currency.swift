import Foundation

enum Currency: Codable { case usd, cad, gbp, eur, none}

extension Currency {
    
    func getCurrencyIndex()-> Int {
        switch self {
        case .cad: return 0
        case .usd: return 1
        case .gbp: return 2
        case .eur: return 3
        default: break
        }
        return -1
    }
    
    func getCurrency()-> String {
        switch self {
        case .cad: return "CAD $"
        case .usd: return "$"
        case .gbp: return "£"
        case .eur: return "€"
        default: break
        }
        return "?"
    }
}
