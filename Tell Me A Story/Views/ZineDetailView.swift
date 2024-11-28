import SwiftUI

struct ZineDetailView: View {
    let zine: Zine
    @State private var showHeader = true
    @State private var lastScrollOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom header with back button
            if showHeader {
                CustomNavigationView(selectedTab: .constant(0), isDetailView: true)
                    .transition(.move(edge: .top))
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .center, spacing: 16) {
                        CachedAsyncImage(url: zine.coverImageUrl) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.2))
                        }
                        .frame(width: 120, height: 120)
                        .cornerRadius(12)
                        .background(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        VStack(spacing: 4) {
                            Text(zine.name)
                                .font(.system(size: 22, weight: .bold))
                            
                            Text("\(zine.issues.count) issues")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.system(size: 17, weight: .semibold))
                        
                        Text(zine.bio)
                            .font(.system(size: 15))
                        
                        if let url = URL(string: zine.instagramUrl) {
                            Link(destination: url) {
                                Text(zine.instagramUrl)
                                    .font(.system(size: 15))
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Issues List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Issues")
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.horizontal)
                        
                        ForEach(zine.issues) { issue in
                            Button {
                                if let url = URL(string: issue.linkUrl) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    CachedAsyncImage(url: issue.coverImageUrl) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .foregroundColor(.gray.opacity(0.2))
                                    }
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(issue.title)
                                            .font(.system(size: 15, weight: .semibold))
                                        Text(issue.publishedDate)
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                        }
                    }
                    .padding(.top)
                }
            }
            .coordinateSpace(name: "scroll")
            .onScrollOffsetChange { offset in
                let scrollingDown = offset < lastScrollOffset
                if abs(offset - lastScrollOffset) > 30 {
                    withAnimation {
                        showHeader = !scrollingDown
                    }
                    lastScrollOffset = offset
                }
            }
        }
        .navigationBarHidden(true)
    }
}
