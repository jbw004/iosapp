import Foundation

enum ZineServiceError: LocalizedError {
    case invalidURL(String)
    case networkError(String)
    case noData
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .noData:
            return "No data received from server"
        case .decodingError(let message):
            return "Failed to decode data: \(message)"
        }
    }
}

class ZineService: ObservableObject {
    @Published var zines: [Zine] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    var hasError: Bool {
            error != nil
        }
    
    private let dataUrl = "https://raw.githubusercontent.com/jbw004/zine-data/main/data.json"
    
    func fetchZines() {
        isLoading = true
        error = nil
        
        guard let url = URL(string: dataUrl) else {
            error = ZineServiceError.invalidURL(dataUrl)
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = ZineServiceError.networkError(error.localizedDescription)
                    return
                }
                
                guard let data = data else {
                    self?.error = ZineServiceError.noData
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    // Removed the global snake case strategy since we're handling it in CodingKeys
                    let response = try decoder.decode(ZineResponse.self, from: data)
                    self?.zines = response.zines
                } catch {
                    let rawJson = String(data: data, encoding: .utf8) ?? "Unable to convert data to string"
                    let jsonPreview = String(rawJson.prefix(200)) + "..."
                    let errorDetails = """
                    Error: \(error)
                    JSON Preview: \(jsonPreview)
                    """
                    self?.error = ZineServiceError.decodingError(errorDetails)
                }
            }
        }.resume()
    }
}
