//
//  DatabaseManager.swift
//  UCM Bank
//
//  Created by Reza Kashkoul on 3/29/25.
//

import Foundation

let baseURL = "http://localhost:62547"

struct SignupRequest: Codable {
    let username: String
    let password: String
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let message: String
    let user: User
}

extension NetworkManager {
    
    func signup(username: String, password: String, completion: @escaping (Result<String, NetworkError>) -> Void) {
        let url = "\(baseURL)/users/signup"
        let body = SignupRequest(username: username, password: password)
        sendRequest(url: url, method: "POST", body: body, completion: completion)
    }

    func login(username: String, password: String, completion: @escaping (Result<User, NetworkError>) -> Void) {
        let url = "\(baseURL)/users/login"
        let body = LoginRequest(username: username, password: password)
        sendRequest(url: url, method: "POST", body: body, completion: completion)
    }
    
    private func sendRequest<T: Codable, R: Codable>(url: String, method: String, body: T, completion: @escaping (Result<R, NetworkError>) -> Void) {
        guard let requestURL = URL(string: url) else {
            completion(.failure(.badURL))
            return
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil else {
                completion(.failure(.general))
                return
            }

            guard let data = data else {
                completion(.failure(.noData))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(R.self, from: data)
                completion(.success(decoded))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(.decode))
            }
        }.resume()
    }
}
