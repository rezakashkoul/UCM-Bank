import Foundation

extension UserDefaults {
    
    func saveUsers() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(allUsers) {
            self.set(encoded, forKey: "accounts")
        }
    }
    
    func retrieveUsers() -> [User] {
        if let data = self.data(forKey: "accounts") {
            let decoder = JSONDecoder()
            if let objects = try? decoder.decode([User].self, from: data) {
                return objects
            } else {
                print("Couldn't decode accounts")
                return []
            }
        } else {
            print("Couldn't find key")
            return []
        }
    }
}
