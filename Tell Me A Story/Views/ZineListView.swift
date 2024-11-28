import SwiftUI

struct ZineListView: View {
    @StateObject private var zineService = ZineService()
    
    var body: some View {
        LazyVStack(spacing: 16) {
            if zineService.isLoading {
                ProgressView("Loading zines...")
                    .padding()
            } else if let error = zineService.error {
                VStack(spacing: 16) {
                    Text("Unable to load zines")
                        .font(.headline)
                    
                    // Debug Information Section
                    VStack(alignment: .leading, spacing: 12) {
                        Group {
                            Text("Debug Information")
                                .font(.headline)
                            
                            Text("Error Type:")
                                .bold()
                            Text(String(describing: type(of: error)))
                            
                            Text("Error Description:")
                                .bold()
                            Text(error.localizedDescription)
                            
                            if let decodingError = error as? DecodingError {
                                Text("Decoding Error Details:")
                                    .bold()
                                Text(String(describing: decodingError))
                            }
                        }
                        .font(.system(.caption, design: .monospaced))
                    }
                    .padding()
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
                    
                    Button {
                        zineService.fetchZines()
                    } label: {
                        Text("Try Again")
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
            } else {
                ForEach(zineService.zines) { zine in
                    NavigationLink(destination: ZineDetailView(zine: zine)) {
                        ZineRowView(zine: zine)
                    }
                }
            }
        }
        .padding()
        .onAppear {
            if zineService.zines.isEmpty {
                zineService.fetchZines()
            }
        }
    }
}
