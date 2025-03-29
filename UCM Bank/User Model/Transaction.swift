import Foundation

enum TransactionType: Codable {case income, outcome}
enum TransactionReason: Codable { case bill, transfer }

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
        return lhs.amount == rhs.amount && lhs.date == rhs.date && lhs.id == rhs.id && lhs.reason == rhs.reason
    }
}

struct TransactionReceiver: Codable {
    let title, id: String
    
    init(title: String, id: String) {
        self.title = title
        self.id = id
    }
}
