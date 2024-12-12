import SwiftUI

struct FollowingView: View {
    @EnvironmentObject var zineService: ZineService
    @EnvironmentObject var notificationService: NotificationService
    @State private var selectedZine: Zine?
    
    var followedZines: [Zine] {
        let allZines = zineService.zines
        
        return allZines
            .filter { notificationService.isFollowingZine($0.id) }
            .sorted { zine1, zine2 in
                // Get timestamps from metadata
                let notification1 = notificationService.followedZinesMetadata[zine1.id]?.lastNotificationAt
                let notification2 = notificationService.followedZinesMetadata[zine2.id]?.lastNotificationAt
                
                // Sort by notification timestamp, newest first
                // If no notification, use an old date
                let date1 = notification1 ?? .distantPast
                let date2 = notification2 ?? .distantPast
                
                return date1 > date2
            }
    }
    
    func isRecent(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return Date().timeIntervalSince(date) < 24 * 60 * 60 // 24 hours
    }
    
    var body: some View {
        ScrollView {
            
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
                                    HStack {
                                        Text(zine.name)
                                            .font(.system(size: 17, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        // New indicator
                                        if let lastNotification = notificationService.followedZinesMetadata[zine.id]?.lastNotificationAt,
                                           isRecent(lastNotification) {
                                            Text("New")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.blue)
                                                .cornerRadius(12)
                                        }
                                    }
                                    
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
        .padding(.bottom, 100)    // Add here
        .onAppear {
            Task {
                await zineService.fetchZines()
            }
        }
    }
}
