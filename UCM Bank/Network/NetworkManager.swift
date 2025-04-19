import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "https://8f43x5vm23.execute-api.us-east-2.amazonaws.com/dev"

    // ✅ public به جای private برای استفاده از viewcontrollers
    func postRequest(endpoint: String, body: [String: Any], completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Request failed for \(endpoint):", error)
                completion(.failure(error))
            } else if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "No data returned", code: 0)))
            }
        }.resume()
    }

    func checkUsernameExists(_ username: String, completion: @escaping (Bool) -> Void) {
        let body = ["username": username]
        postRequest(endpoint: "usernameExists", body: body) { result in
            switch result {
            case .success(let data):
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let exists = json["exists"] as? Bool {
                    completion(exists)
                } else {
                    print("❌ Unexpected response format for usernameExists.")
                    completion(false)
                }
            case .failure(let error):
                print("❌ Error checking usernameExists:", error)
                completion(false)
            }
        }
    }

    // ✅ async/await version
    func checkUsernameExists(username: String) async -> Bool {
        await withCheckedContinuation { continuation in
            self.checkUsernameExists(username) { exists in
                continuation.resume(returning: exists)
            }
        }
    }

    func addUser(username: String, password: String, firstName: String, lastName: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let body = [
            "username": username,
            "password": password,
            "first_name": firstName,
            "last_name": lastName
        ]

        postRequest(endpoint: "addUser", body: body) { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                print("❌ Error adding user:", error)
                completion(.failure(error))
            }
        }
    }
    
        //TODO: - Fix cummy / mock values
    func getUser(by username: String, completion: @escaping (Result<User, Error>) -> Void) {
        
        guard let url = URL(string: "https://8f43x5vm23.execute-api.us-east-2.amazonaws.com/dev/getUser?username=\(username)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let userDict = json?["user"] as? [String: Any],
                   let username = userDict["username"] as? String,
                   let firstName = userDict["first_name"] as? String,
                   let lastName = userDict["last_name"] as? String {

                    // ساختن personalInfo موقت
                    let dummyAddress = Address(postalCode: "", unitNumber: "", streetNumber: "", streetName: "", province: "")
                    let dummySecurityAnswers = [SecurityAnswer(answer: ""), SecurityAnswer(answer: ""), SecurityAnswer(answer: "")]
                    let personal = PersonalInfo(firstName: firstName, lastName: lastName, username: username, password: "", ssn: "", email: "", tel: "", address: dummyAddress, securityAnswers: dummySecurityAnswers)

                    let user = User(accounts: [], personalInfo: personal, payees: [])
                    completion(.success(user))
                } else {
                    completion(.failure(NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid user JSON"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func setSecurityQuestions(username: String, answer1: String, answer2: String, answer3: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let body = [
            "username": username,
            "answer1": answer1,
            "answer2": answer2,
            "answer3": answer3
        ]

        postRequest(endpoint: "SetSecurityQuestions", body: body) { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                print("❌ Error setting security questions:", error)
                completion(.failure(error))
            }
        }
    }

    func changePassword(username: String, newPassword: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let body = [
            "username": username,
            "new_password": newPassword
        ]

        postRequest(endpoint: "ChangePassword", body: body) { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                print("❌ Error changing password:", error)
                completion(.failure(error))
            }
        }
    }
}
