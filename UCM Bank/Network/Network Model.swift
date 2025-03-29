import Foundation

// MARK: - ExchangeRate
struct ExchangeRate: Codable {
    let base, date: String
    let rates: Rates
    let success: Bool
    let timestamp: Int
}

// MARK: - Rates
struct Rates: Codable {
    let eur, gbp, usd: Double

    enum CodingKeys: String, CodingKey {
        case eur = "EUR"
        case gbp = "GBP"
        case usd = "USD"
    }
}
