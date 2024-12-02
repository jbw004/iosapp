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
    
    // Date formatter for parsing publishedDate strings
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    private func parseDate(_ dateString: String) -> Date {
        // Return a very old date if parsing fails, so invalid dates sort to the end
        dateFormatter.date(from: dateString) ?? Date.distantPast
    }
    
    private func sortZines(_ zines: [Zine]) -> [Zine] {
        // First, create new zines with sorted issues
        let zinesWithSortedIssues = zines.map { zine in
            // Sort issues by published date in descending order (most recent first)
            let sortedIssues = zine.issues.sorted { first, second in
                let firstDate = parseDate(first.publishedDate)
                let secondDate = parseDate(second.publishedDate)
                return firstDate > secondDate
            }
            
            // Create a new zine with the sorted issues
            return Zine(
                id: zine.id,
                name: zine.name,
                bio: zine.bio,
                coverImageUrl: zine.coverImageUrl,
                instagramUrl: zine.instagramUrl,
                issues: sortedIssues
            )
        }
        
        // Then sort zines by issue count (descending) with name as secondary criteria
        return zinesWithSortedIssues.sorted { first, second in
            if first.issues.count != second.issues.count {
                return first.issues.count > second.issues.count
            }
            // If issue counts are equal, sort alphabetically by name
            return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
        }
    }
    
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
            
            // Apply sorting before updating published property
            let sortedZines = sortZines(response.zines)
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.zines = sortedZines
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
