import SwiftUI

struct ZinePicker: View {
    @EnvironmentObject var zineService: ZineService
    @Binding var selectedZine: Zine?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if zineService.isLoading {
                HStack {
                    ProgressView()
                        .padding(.trailing, 8)
                    Text("Loading zines...")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            } else if zineService.hasError {
                HStack {
                    Text("Failed to load zines")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await zineService.fetchZines()
                        }
                    }
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
            } else if zineService.zines.isEmpty {
                Text("No zines available")
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                Menu {
                    ForEach(zineService.zines) { zine in
                        Button(zine.name) {
                            selectedZine = zine
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedZine?.name ?? "Select a Zine")
                            .foregroundColor(selectedZine == nil ? .gray : .primary)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .onAppear {
            if zineService.zines.isEmpty {
                Task {
                    await zineService.fetchZines()
                }
            }
        }
    }
}
