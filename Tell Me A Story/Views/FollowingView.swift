import SwiftUI

struct FollowingView: View {
    @EnvironmentObject var zineService: ZineService
    @EnvironmentObject var notificationService: NotificationService
    @State private var selectedZine: Zine?
    @State private var debugMessage: String = ""
    
    var followedZines: [Zine] {
        let allZines = zineService.zines
        let followedIds = notificationService.followedZines
        
        debugMessage = """
        Total zines: \(allZines.count)
        Followed IDs: \(followedIds.joined(separator: ", "))
        """
        
        let filtered = allZines.filter { zine in
            let isFollowing = notificationService.isFollowingZine(zine.id)
            debugMessage += "\nZine \(zine.id): isFollowing = \(isFollowing)"
            return isFollowing
        }
        
        debugMessage += "\nFiltered count: \(filtered.count)"
        return filtered
    }
    
    var body: some View {
        ScrollView {
            // Add debug view at the top
            Text(debugMessage)
                .font(.caption)
                .foregroundColor(.gray)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding()
            
            VStack(spacing: 16) {
                if followedZines.isEmpty {
                    VStack(spacing: 12) {
                        Text("No followed zines yet")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Follow zines to see their updates here")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    ForEach(followedZines) { zine in
                        NavigationLink(value: zine) {
                            HStack(spacing: 16) {
                                // Cover image
                                CachedAsyncImage(url: zine.coverImageUrl) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .foregroundColor(.gray.opacity(0.2))
                                }
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)
                                
                                // Text content
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(zine.name)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text(zine.bio)
                                        .font(.system(size: 15))
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.leading, 92)
                    }
                }
            }
        }
        .onAppear {
            // Force a refresh of zines when view appears
            Task {
                await zineService.fetchZines()
            }
        }
    }
}
