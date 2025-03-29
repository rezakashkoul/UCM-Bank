import Foundation


class NetworkManager {
    
    static let shared = NetworkManager()
    
    enum NetworkError: Error {
        case general
        case timeout
        case noData
        case decode
        case badURL
    }
    
    func getExchangeRate(completion: @escaping (Result<ExchangeRate, NetworkError>)-> Void) {
        
        let url = "https://api.apilayer.com/exchangerates_data/latest?symbols=USD%2CGBP%2CEUR%2C&base=CAD"
        baseRequest(type: ExchangeRate.self, url: url, completion: completion)
    }
    
    private func baseRequest<T: Decodable>(type: T.Type, url: String, completion: @escaping (Result<T, NetworkError>) -> Void) {
        
        let apiKey = "LhVDpencvd2Lu1YY48AwKyk1m1banV6N"
        guard let url = URL(string: url) else {
            completion(.failure(.badURL))
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "apikey")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion(.failure(.general))
                return
            }
            guard let data = data , let _  = response else {
                completion(.failure(.noData))
                return
            }
            
            if (error as? URLError)?.code == .timedOut {
                completion(.failure(.timeout))
            }
            
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(.decode))
            }
        }
        task.resume()
    }
}
