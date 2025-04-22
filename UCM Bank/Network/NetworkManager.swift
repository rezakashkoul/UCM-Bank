import Foundation
import Amplify

class NetworkManager {
    
    static let shared = NetworkManager()
    private init() {}

    private let baseURL = "https://8f43x5vm23.execute-api.us-east-2.amazonaws.com/dev"

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

    func checkUsernameExists(username: String) async -> Bool {
        await withCheckedContinuation { continuation in
            self.checkUsernameExists(username) { exists in
                continuation.resume(returning: exists)
            }
        }
    }

    func addUser(personalInfo: PersonalInfo, completion: @escaping (Result<Bool, Error>) -> Void) {
        let address = personalInfo.address
        let body: [String: Any] = [
            "username": personalInfo.username,
            "password": personalInfo.password,
            "email": personalInfo.email,
            "first_name": personalInfo.firstName,
            "last_name": personalInfo.lastName,
            "ssn": personalInfo.ssn,
            "phone": personalInfo.phone,
            "postal_code": address.postalCode,
            "unit_number": address.unitNumber,
            "street_number": address.streetNumber,
            "street_name": address.streetName,
            "province": address.province
        ]

        postRequest(endpoint: "addUser", body: body) { result in
            switch result {
            case .success:
                completion(.success(true))
            case .failure(let error):
                print("❌ Error adding user with full data:", error)
                completion(.failure(error))
            }
        }
    }
    
        //TODO: - Fix cummy / mock values
    func getUser(by username: String, completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/getUser?username=\(username)") else {
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

                    let dummyAddress = Address(postalCode: "", unitNumber: "", streetNumber: "", streetName: "", province: "")
                    let dummySecurityAnswers = [SecurityAnswer(answer: ""), SecurityAnswer(answer: ""), SecurityAnswer(answer: "")]
                    let personal = PersonalInfo(firstName: firstName, lastName: lastName, username: username, password: "", ssn: "", email: "", phone: "", address: dummyAddress, securityAnswers: dummySecurityAnswers)

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
        let innerBody: [String: Any] = [
            "username": username,
            "answers": [answer1, answer2, answer3]
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: innerBody, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                completion(.failure(NSError(domain: "JSON Encoding Failed", code: -2)))
                return
            }
            let finalBody: [String: Any] = [
                "body": jsonString
            ]
            postRequest(endpoint: "setSecurityQuestions", body: finalBody) { result in
                switch result {
                case .success(let data):
                    do {
                        if let outerJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let bodyString = outerJson["body"] as? String,
                           let innerData = bodyString.data(using: .utf8),
                           let innerJson = try JSONSerialization.jsonObject(with: innerData, options: []) as? [String: Any],
                           let message = innerJson["message"] as? String,
                           message.lowercased().contains("saved") {
                            completion(.success(true))
                        } else {
                            completion(.failure(NSError(domain: "Invalid JSON structure", code: -3)))
                        }
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    print("❌ Error setting security questions:", error)
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func validateSecurityAnswers(username: String, answer1: String, answer2: String, answer3: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let body = [
            "username": username,
            "answers": [answer1, answer2, answer3]
        ] as [String : Any]

        postRequest(endpoint: "validateSecurityAnswers", body: body) { result in
            switch result {
            case .success(let data):
                do {
                    if let outerJson = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let bodyString = outerJson["body"] as? String,
                       let innerData = bodyString.data(using: .utf8),
                       let innerJson = try JSONSerialization.jsonObject(with: innerData, options: []) as? [String: Any],
                       let match = innerJson["match"] as? Bool {
                        completion(.success(match))
                    } else {
                        completion(.failure(NSError(domain: "Invalid JSON structure", code: -3)))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func resetCognitoPassword(username: String, newPassword: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let body = [
            "username": username,
            "new_password": newPassword
        ]

        postRequest(endpoint: "resetCognitoPassword", body: body) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        completion(.success(json))
                    } else {
                        completion(.failure(NSError(domain: "Invalid JSON", code: -3)))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                print("❌ Error resetting Cognito password:", error)
                completion(.failure(error))
            }
        }
    }
}

extension NetworkManager {
    /// Logs out the currently signed-in user if there is one.
    func signOutIfNeeded() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            if session.isSignedIn {
                _ = await Amplify.Auth.signOut()
                print("✅ Signed out previous user session.")
            } else {
                print("ℹ️ No user is currently signed in.")
            }
        } catch {
            print("❌ Failed to check or sign out session:", error.localizedDescription)
        }
    }
}
