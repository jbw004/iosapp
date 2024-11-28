import SwiftUI

actor ImageCache {
    static let shared = ImageCache()
    private var cache: [String: Image] = [:]
    
    func image(for url: String) -> Image? {
        cache[url]
    }
    
    func insert(_ image: Image, for url: String) {
        cache[url] = image
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: String
    private let scale: CGFloat
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var image: Image? = nil
    @State private var isLoading = false
    @State private var error: Error? = nil
    @State private var showDebug = false
    
    init(
        url: String,
        scale: CGFloat = 1.0,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(image)
            } else {
                placeholder()
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                            } else if error != nil {
                                // Show a small red dot to indicate error
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .padding(4)
                            }
                        }
                    )
                    .onTapGesture {
                        if let error = error {
                            print("Image loading error for \(url):")
                            print(error.localizedDescription)
                        }
                        showDebug.toggle()
                    }
                    .overlay(
                        Group {
                            if showDebug {
                                Text(url)
                                    .font(.caption2)
                                    .padding(4)
                                    .background(Color.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                    )
                    .task {
                        await loadImage()
                    }
            }
        }
    }
    
    private func loadImage() async {
        if let cached = await ImageCache.shared.image(for: url) {
            self.image = cached
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        guard let imageUrl = URL(string: url) else {
            error = URLError(.badURL)
            print("Invalid image URL: \(url)")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: imageUrl)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Image response status: \(httpResponse.statusCode) for URL: \(url)")
            }
            
            guard let uiImage = UIImage(data: data) else {
                error = URLError(.cannotDecodeRawData)
                print("Cannot decode image data for URL: \(url)")
                return
            }
            
            let image = Image(uiImage: uiImage)
            await ImageCache.shared.insert(image, for: url)
            self.image = image
        } catch {
            self.error = error
            print("Error loading image: \(error.localizedDescription) for URL: \(url)")
        }
    }
}
