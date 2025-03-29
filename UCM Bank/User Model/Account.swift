import Foundation

struct Account: Codable, Equatable {
    var id, title: String
    var type: AccountType
    var currency: Currency
    var balance: Double
    var transactions: [Transaction]
    
    init(id: String, title: String, type: AccountType, currency: Currency, balance: Double, transactions: [Transaction]) {
        self.id = id
        self.title = title
        self.type = type
        self.currency = currency
        self.balance = balance
        self.transactions = transactions
    }
    
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.balance == rhs.balance && lhs.transactions == rhs.transactions
    }
}

enum AccountType: Codable { case saving, checking, none }

extension AccountType {
    func getAccountTypeIndex()-> Int {
        switch self {
        case .checking: return 0
        case .saving: return 1
        default: return -1
        }
    }
}
