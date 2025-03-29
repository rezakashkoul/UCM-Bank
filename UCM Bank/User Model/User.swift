import Foundation

struct User: Codable, Equatable {
    var personalInfo: PersonalInfo
    var accounts: [Account]
    var payees: [Payee]
    var rememberUserLogin: Bool?
    
    init(accounts: [Account], personalInfo: PersonalInfo, payees: [Payee]) {
        self.accounts = accounts
        self.personalInfo = personalInfo
        self.payees = payees
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.personalInfo == rhs.personalInfo && lhs.accounts == rhs.accounts
    }
}

struct PersonalInfo: Codable {
    var firstName, lastName, username, password: String
    var ssn, email, tel: String
    var address: Address
    var securityAnswers: [SecurityAnswer]
    
    init(firstName: String, lastName: String, username: String, password: String, ssn: String, email: String, tel: String, address: Address, securityAnswers: [SecurityAnswer]) {
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.password = password
        self.ssn = ssn
        self.email = email
        self.tel = tel
        self.address = address
        self.securityAnswers = securityAnswers
    }
    
    static func == (lhs: PersonalInfo, rhs: PersonalInfo) -> Bool {
        return lhs.username == rhs.username && lhs.password == rhs.password
    }
}

struct Address: Codable {
    var postalCode, unitNumber, streetNumber, streetName, province: String
    
    init(postalCode: String, unitNumber: String, streetNumber: String, streetName: String, province: String) {
        self.postalCode = postalCode
        self.unitNumber = unitNumber
        self.streetNumber = streetNumber
        self.streetName = streetName
        self.province = province
    }
}

struct SecurityAnswer: Codable, Equatable {
    var answer: String
    
    init(answer: String) {
        self.answer = answer
    }
    
    static func == (lhs: SecurityAnswer, rhs: SecurityAnswer) -> Bool {
        return lhs.answer == rhs.answer
    }
}

struct Payee: Codable {
    var title, id: String
    
    init(title: String, id: String) {
        self.title = title
        self.id = id
    }
}
