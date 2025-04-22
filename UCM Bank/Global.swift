import Foundation

var allUsers: [User] = []
var currentUser: User?

func initialUser()-> User {
    let user = User(accounts: [], personalInfo: PersonalInfo(firstName: "",lastName: "",username: "",password: "",ssn: "",email: "",phone: "", address: Address(postalCode: "", unitNumber: "", streetNumber: "", streetName: "", province: ""), securityAnswers: []), payees: [])
    return user
}

func saveAccount(user: User) {
    for i in 0..<allUsers.count {
        if allUsers[i].personalInfo.username == user.personalInfo.username && allUsers[i].personalInfo.lastName == user.personalInfo.lastName {
            allUsers[i] = user
            UserDefaults.standard.saveUsers()
            break
        }
    }
    print("user is \(String(describing: currentUser))")
    UserDefaults.standard.saveUsers()
}

let provinces = ["Alabama","Alaska","Arizona","Arkansas","California","Colorado","Connecticut","Delaware","Florida","Georgia","Hawaii","Idaho","Illinois","Indiana","Iowa","Kansas","Kansas","Kentucky","Louisiana","Maine","Maryland","Massachusetts","Michigan","Minnesota","Mississippi","Missouri","Montana","Nebraska","Nevada","New Hampshire","New Jersey","New Mexico","New York","North Carolina","North Dakota","Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island","Rhode Island","South Carolina","South Dakota","Tennessee","Texas","Utah","Vermont","Virginia","Washington","West Virginia","Wisconsin","Wyoming"]

enum CornerRadius: CGFloat {
    case none = 0
    case large = 15
    case regular = 10
    case small = 5
    case round = -1
    case superLarge = 25
    case massiveLarge = 40
}
