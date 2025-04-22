import Foundation

struct User: Codable, Equatable {
    var personalInfo: PersonalInfo
    var accounts: [Account]
    var payees: [Payee]
    var rememberUserLogin: Bool? = false  // Optional with default value

    init(accounts: [Account], personalInfo: PersonalInfo, payees: [Payee]) {
        self.accounts = accounts
        self.personalInfo = personalInfo
        self.payees = payees
    }

    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.personalInfo == rhs.personalInfo && lhs.accounts == rhs.accounts
    }
}

struct PersonalInfo: Codable, Equatable {
    var firstName: String
    var lastName: String
    var username: String
    var password: String
    var ssn: String
    var email: String
    var phone: String
    var address: Address
    var securityAnswers: [SecurityAnswer]

    init(firstName: String, lastName: String, username: String, password: String, ssn: String, email: String, phone: String, address: Address, securityAnswers: [SecurityAnswer]) {
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.password = password
        self.ssn = ssn
        self.email = email
        self.phone = phone
        self.address = address
        self.securityAnswers = securityAnswers
    }

    static func == (lhs: PersonalInfo, rhs: PersonalInfo) -> Bool {
        return lhs.username == rhs.username &&
               lhs.password == rhs.password &&
               lhs.firstName == rhs.firstName &&
               lhs.lastName == rhs.lastName
    }
}

struct Address: Codable, Equatable {
    var postalCode: String
    var unitNumber: String
    var streetNumber: String
    var streetName: String
    var province: String

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
}

struct Payee: Codable, Equatable {
    var title: String
    var id: String

    init(title: String, id: String) {
        self.title = title
        self.id = id
    }
}
