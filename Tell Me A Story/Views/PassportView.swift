import SwiftUI

// Supporting Views first (keep your existing implementations)
struct TopZineView: View {
    let zine: ZineReadStats
    let borderColor: Color
    
    var body: some View {
        CachedAsyncImage(url: zine.coverImageUrl) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 280, height: 280)
        } placeholder: {
            Color.gray.opacity(0.2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(borderColor, lineWidth: 4)
        )
        .shadow(color: .black.opacity(0.3), radius: 10)
        .rotationEffect(.degrees(-3))
    }
}

struct SecondaryZineView: View {
    let zine: ZineReadStats
    let rank: Int
    let borderColor: Color
    
    private var frameSize: CGFloat { rank == 2 ? 120 : 100 }
    private var rotation: Double { rank == 2 ? 15 : -15 }
    
    var body: some View {
        CachedAsyncImage(url: zine.coverImageUrl) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: frameSize, height: frameSize)
        } placeholder: {
            Color.gray.opacity(0.2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.2), radius: 5)
        .rotationEffect(.degrees(rotation))
    }
}

struct RankingListView: View {
    let stats: [ZineReadStats]
    let theme: PassportTheme
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(theme.typography.displayFont(size: 24))
                        .foregroundColor(Color(hex: theme.textColor))
                        .frame(width: 40)
                    
                    Text(stat.zineName)
                        .font(theme.typography.bodyFont(size: 18))
                        .foregroundColor(Color(hex: theme.textColor))
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: index == 0 ? theme.primaryColor :
                                  index == 1 ? theme.secondaryColor : theme.accentColor))
                )
            }
        }
    }
}

struct SignInPromptView: View {
    @Binding var showingAuthSheet: Bool
    let theme: PassportTheme = passportThemes[0]
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: theme.secondaryColor))
            
            Text("Sign in to see your reading collection")
                .font(theme.typography.displayFont(size: 20))
                .foregroundColor(Color(hex: theme.textColor))
            
            Button("Sign In") {
                showingAuthSheet = true
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: theme.background))
    }
}

struct EmptyStateView: View {
    let theme: PassportTheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: theme.secondaryColor))
            
            Text("No read issues yet")
                .font(theme.typography.displayFont(size: 20))
                .foregroundColor(Color(hex: theme.textColor))
            
            Text("Mark issues as read to start your collection")
                .font(theme.typography.bodyFont(size: 16))
                .foregroundColor(Color(hex: theme.secondaryColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: theme.background))
    }
}

struct ThemePicker: View {
    @Binding var selectedTheme: PassportTheme
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(passportThemes) { theme in
                    ThemePreviewButton(
                        theme: theme,
                        isSelected: theme.id == selectedTheme.id,
                        action: { selectedTheme = theme }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct ThemePreviewButton: View {
    let theme: PassportTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: theme.background))
                        .frame(width: 60, height: 60)
                    
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: theme.primaryColor))
                            .frame(width: 40, height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: theme.secondaryColor))
                            .frame(width: 40, height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: theme.accentColor))
                            .frame(width: 40, height: 8)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
                )
                
                Text(theme.name)
                    .font(theme.typography.bodyFont(size: 12))
                    .foregroundColor(Color(hex: theme.textColor))
            }
        }
    }
}

// Main PassportView
struct PassportView: View {
    @Binding var selectedFooterTab: TabItem
    @State private var showingSubmissionSheet = false  // Add this
    @EnvironmentObject var readService: ReadService
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var zineService: ZineService
    @State private var readStats: [ZineReadStats] = []
    @State private var isLoading = false
    @State private var showingAuthSheet = false
    @State private var selectedTheme: PassportTheme = passportThemes[0]
    @State private var isUIHidden = false
    
    var body: some View {
        ZStack {
            // Background that extends edge-to-edge
            Color(hex: selectedTheme.background)
                .ignoresSafeArea()
            
            if !authService.isAuthenticated {
                            VStack(spacing: 0) {
                                // Always show header in logged out state
                                CustomNavigationView(
                                    selectedTab: .constant(0),
                                    simplifiedHeader: true,
                                    headerTitle: "Reading Wrapped"
                                )
                                
                                SignInPromptView(showingAuthSheet: $showingAuthSheet)
                                
                                // Always show footer in logged out state
                                CustomTabBar(selectedTab: $selectedFooterTab,
                                           showingSubmissionSheet: $showingSubmissionSheet)
                            }
                        } else if isLoading {
                            VStack(spacing: 0) {
                                // Always show header in loading state
                                CustomNavigationView(
                                    selectedTab: .constant(0),
                                    simplifiedHeader: true,
                                    headerTitle: "Reading Wrapped"
                                )
                                
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                // Always show footer in loading state
                                CustomTabBar(selectedTab: $selectedFooterTab,
                                           showingSubmissionSheet: $showingSubmissionSheet)
                            }
                        } else if readStats.isEmpty {
                            VStack(spacing: 0) {
                                // Always show header in empty state
                                CustomNavigationView(
                                    selectedTab: .constant(0),
                                    simplifiedHeader: true,
                                    headerTitle: "Reading Wrapped"
                                )
                                
                                EmptyStateView(theme: selectedTheme)
                                
                                // Always show footer in empty state
                                CustomTabBar(selectedTab: $selectedFooterTab,
                                           showingSubmissionSheet: $showingSubmissionSheet)
                            }
                        } else {
                            // Only allow UI hiding when we have data to display
                            VStack(spacing: 0) {
                                // Theme Selector
                                if !isUIHidden {
                                    VStack {
                                        CustomNavigationView(
                                            selectedTab: .constant(0),
                                            simplifiedHeader: true,
                                            headerTitle: "Reading Wrapped"
                                        )
                                        
                                        ThemePicker(selectedTheme: $selectedTheme)
                                            .padding()
                                    }
                                    .transition(.opacity)
                                }
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Title
                            Text("My Top Zines")
                                .font(selectedTheme.typography.displayFont(size: 36))
                                .foregroundColor(Color(hex: selectedTheme.textColor))
                                .padding(.top, isUIHidden ? 60 : 40)
                            
                            // Main content
                            ZStack(alignment: .trailing) {
                                // Top zine large image
                                if let topZine = readStats.first {
                                    TopZineView(
                                        zine: topZine,
                                        borderColor: Color(hex: selectedTheme.primaryColor)
                                    )
                                }
                                
                                // Secondary zines
                                VStack(spacing: 20) {
                                    ForEach(readStats.dropFirst().prefix(2)) { zine in
                                        SecondaryZineView(
                                            zine: zine,
                                            rank: readStats.firstIndex(where: { $0.id == zine.id })! + 1,
                                            borderColor: Color(hex: readStats.firstIndex(where: { $0.id == zine.id })! == 1 ? selectedTheme.secondaryColor : selectedTheme.accentColor)
                                        )
                                    }
                                }
                                .padding(.trailing, 20)
                            }
                            
                            // Ranking list
                            RankingListView(
                                stats: readStats,
                                theme: selectedTheme
                            )
                            .padding(.horizontal)
                            .padding(.top, 20)
                        }
                        .padding(.bottom, isUIHidden ? 60 : 100)
                    }
                    
                    // Custom Tab Bar
                    if !isUIHidden {
                                    CustomTabBar(selectedTab: $selectedFooterTab,
                                               showingSubmissionSheet: $showingSubmissionSheet)
                                        .transition(.opacity)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isUIHidden.toggle()
                    }
                }
            }
        }
        .task {
                    await loadReadStats()
                }
                .onChange(of: authService.isAuthenticated) { _, newValue in
                    if newValue {
                        // Immediately load data when user becomes authenticated
                        Task {
                            await loadReadStats()
                        }
                    }
                }
                .sheet(isPresented: $showingAuthSheet) {
                    NavigationView {
                        AuthenticationView()
                    }
                }
                .sheet(isPresented: $showingSubmissionSheet) {
                    SubmissionTypeSelectionView()
                }
            }
    
    private func loadReadStats() async {
        isLoading = true
        do {
            let grouped = try await readService.fetchGroupedReadIssues()
            await zineService.fetchZines()
            
            await MainActor.run {
                let stats = grouped.map { (zineName, issues) -> ZineReadStats in
                    let zine = zineService.zines.first { $0.name == zineName }
                    return ZineReadStats(
                        zineName: zineName,
                        issueCount: issues.count,
                        coverImageUrl: zine?.coverImageUrl ?? issues.first?.coverImageUrl ?? ""
                    )
                }
                .sorted { $0.issueCount > $1.issueCount }
                
                readStats = Array(stats.prefix(3))
                isLoading = false
            }
        } catch {
            print("Error loading read stats: \(error)")
            await MainActor.run {
                readStats = []
                isLoading = false
            }
        }
    }
}
