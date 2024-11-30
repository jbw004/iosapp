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
    
    func fetchZines() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        guard let url = URL(string: dataUrl) else {
            DispatchQueue.main.async {
                self.error = ZineServiceError.invalidURL(self.dataUrl)
                self.isLoading = false
            }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let decoder = JSONDecoder()
            let response = try decoder.decode(ZineResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.zines = response.zines
            }
        } catch let error {
            DispatchQueue.main.async {
                self.isLoading = false
                if let urlError = error as? URLError {
                    self.error = ZineServiceError.networkError(urlError.localizedDescription)
                } else {
                    self.error = ZineServiceError.decodingError(error.localizedDescription)
                }
            }
        }
    }
}
