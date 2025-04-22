import Foundation

enum TransactionType: String, Codable {
    case income
    case outcome
}

enum TransactionReason: String, Codable {
    case bill
    case transfer
}

struct Transaction: Codable, Equatable {
    var date: Date
    var amount: Double
    var type: TransactionType
    var id: String
    var reason: TransactionReason
    var receiver: TransactionReceiver

    init(date: Date, amount: Double, type: TransactionType, reason: TransactionReason, id: String, receiver: TransactionReceiver) {
        self.date = date
        self.amount = amount
        self.type = type
        self.reason = reason
        self.id = id
        self.receiver = receiver
    }

    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.id == rhs.id &&
               lhs.date == rhs.date &&
               lhs.amount == rhs.amount &&
               lhs.type == rhs.type &&
               lhs.reason == rhs.reason &&
               lhs.receiver == rhs.receiver
    }
}

struct TransactionReceiver: Codable, Equatable {
    let title: String
    let id: String

    init(title: String, id: String) {
        self.title = title
        self.id = id
    }
}
