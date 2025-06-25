import SwiftUI

struct LyoHeaderView: View {
    @StateObject private var viewModel = HeaderViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            headerContent
            
            if viewModel.isStoryDrawerOpen {
                StoryStripView()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            // Auto-minimize timer is handled by the viewModel
        }
        .onDisappear {
            // Auto-minimize timer is handled by the viewModel
        }
        .fullScreenCover(isPresented: $viewModel.showSearch) {
            AISearchView(isPresented: $viewModel.showSearch)
        }
        .fullScreenCover(isPresented: $viewModel.showMessages) {
            MessagesView(
                isPresented: $viewModel.showMessages,
                conversations: $viewModel.conversations,
                unreadMessages: $viewModel.unreadMessagesCount
            )
        }
        .sheet(isPresented: $viewModel.showProfileSheet) {
            HeaderProfileView(isPresented: $viewModel.showProfileSheet)
        }
    }
    
    private var headerContent: some View {
        HStack {
            // Left: Lyo Logo
            logoSection
            
            Spacer()
            
            // Right: Action Icons
            actionIconsSection
        }
        .padding(.horizontal, 16)
        .frame(height: viewModel.headerState == .expanded ? 80 : 40)
        .background(
            Material.ultraThin
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.1),
                            Color.purple.opacity(0.05)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                )
        )
        .overlay(
            // Bottom border
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.handleHeaderTap()
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.headerState == .expanded)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isStoryDrawerOpen)
    }
    
    private var logoSection: some View {
        HStack(spacing: 8) {
            // Logo icon
            Image(systemName: "graduationcap.fill")
                .font(.system(size: viewModel.headerState == .expanded ? 28 : 20, weight: .semibold))
                .foregroundColor(.blue)
                .scaleEffect(viewModel.headerState == .expanded ? 1.0 : 0.8)
            
            // Logo text (only visible when expanded)
            if viewModel.headerState == .expanded {
                Text("Lyo")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.headerState == .expanded)
    }
    
    private var actionIconsSection: some View {
        HStack(spacing: viewModel.headerState == .expanded ? 20 : 12) {
            // Search Icon
            ActionIcon(
                systemName: "magnifyingglass",
                isExpanded: viewModel.headerState == .expanded,
                action: {
                    viewModel.handleIconTap()
                    viewModel.openSearch()
                }
            )
            
            // Messages Icon with Badge
            ZStack {
                ActionIcon(
                    systemName: "paperplane.fill",
                    isExpanded: viewModel.headerState == .expanded,
                    action: {
                        viewModel.handleIconTap()
                        viewModel.openMessages()
                    }
                )
                
                if viewModel.unreadMessagesCount > 0 {
                    NotificationBadge(count: viewModel.unreadMessagesCount)
                        .offset(x: 8, y: -8)
                }
            }
            
            // Story Drawer Icon
            ActionIcon(
                systemName: viewModel.isStoryDrawerOpen ? "chevron.up" : "chevron.down",
                isExpanded: viewModel.headerState == .expanded,
                isActive: viewModel.isStoryDrawerOpen,
                action: {
                    viewModel.handleIconTap()
                    viewModel.toggleStoryDrawer()
                }
            )
            
            // Profile Icon
            ActionIcon(
                systemName: "person.crop.circle.fill",
                isExpanded: viewModel.headerState == .expanded,
                action: {
                    viewModel.handleIconTap()
                    viewModel.openProfile()
                }
            )
        }
    }
    
    @ViewBuilder
    private func StoryStripView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.stories, id: \.id) { story in
                    StoryCircle(story: story)
                        .onTapGesture {
                            // Handle story tap
                            viewModel.handleStoryTap(story)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(height: 100)
        .background(
            Material.ultraThin
        )
        .overlay(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // Close story drawer when tapping background
            viewModel.toggleStoryDrawer()
        }
    }
}

// MARK: - Supporting Views

struct ActionIcon: View {
    let systemName: String
    let isExpanded: Bool
    let isActive: Bool
    let action: () -> Void
    
    init(
        systemName: String,
        isExpanded: Bool,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.isExpanded = isExpanded
        self.isActive = isActive
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isActive ? .blue : .white)
                .scaleEffect(isExpanded ? 1.0 : 0.8)
                .opacity(isExpanded ? 1.0 : 0.5)
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

struct NotificationBadge: View {
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(minWidth: 16, minHeight: 16)
            .background(
                Circle()
                    .fill(Color.red)
            )
            .scaleEffect(count > 0 ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: count)
    }
}

struct StoryCircle: View {
    let story: Story
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .strokeBorder(
                        story.hasUnwatchedStory ? 
                            LinearGradient(
                                gradient: Gradient(colors: [.purple, .blue]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [.gray.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: 2
                    )
                    .frame(width: 60, height: 60)
                
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: story.colorGradient),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                    .overlay(
                        Text(story.initials)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
            
            Text(story.username)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .frame(width: 65)
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - AI Search View

struct AISearchView: View {
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var isListening = false
    @FocusState private var isSearchFocused: Bool
    
    private let suggestedQueries = [
        "Explain quantum physics",
        "Swift programming basics",
        "History of Renaissance",
        "Math calculus help",
        "Spanish grammar rules"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [.black, .blue.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // AI Search Input
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("Ask me anything...", text: $searchText)
                            .foregroundColor(.white)
                            .focused($isSearchFocused)
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                isListening.toggle()
                            }
                        }) {
                            Image(systemName: isListening ? "mic.fill" : "mic")
                                .foregroundColor(isListening ? .red : .white.opacity(0.7))
                                .scaleEffect(isListening ? 1.2 : 1.0)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Material.ultraThin)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal)
                    
                    // Suggested Queries
                    if searchText.isEmpty {
                        SuggestedQueriesView(queries: suggestedQueries) { query in
                            searchText = query
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }
}

struct SuggestedQueriesView: View {
    let queries: [String]
    let onQueryTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested Queries")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(queries, id: \.self) { query in
                    Button(action: {
                        onQueryTap(query)
                    }) {
                        Text(query)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Material.ultraThin)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Messages View

struct MessagesView: View {
    @Binding var isPresented: Bool
    @Binding var conversations: [Conversation]
    @Binding var unreadMessages: Int
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [.black, .purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(conversations) { conversation in
                            ConversationRow(conversation: conversation)
                                .onTapGesture {
                                    // Open chat view
                                    markAsRead(conversation)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Compose new message
                    }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            // Mark all as read when opening
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                unreadMessages = 0
            }
        }
    }
    
    private func markAsRead(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index].hasUnreadMessages = false
        }
        updateUnreadCount()
    }
    
    private func updateUnreadCount() {
        unreadMessages = conversations.filter { $0.hasUnreadMessages }.count
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: conversation.colorGradient),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(conversation.initials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(conversation.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Text(conversation.lastMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            if conversation.hasUnreadMessages {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            conversation.hasUnreadMessages ?
                Color.blue.opacity(0.1) :
                Color.clear
        )
    }
}

// MARK: - Header Profile View

struct HeaderProfileView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [.black, .green.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text("JD")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.white)
                                )
                            
                            VStack(spacing: 4) {
                                Text("John Doe")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Student")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // Stats
                        HStack {
                            ProfileStat(title: "Courses", value: "12")
                            ProfileStat(title: "Hours", value: "48")
                            ProfileStat(title: "Followers", value: "234")
                        }
                        
                        // Bio
                        Text("Passionate learner exploring the intersection of technology and education. Always eager to discover new concepts and share knowledge.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        // Open settings
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct ProfileStat: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Preview

struct LyoHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            LyoHeaderView()
            
            Spacer()
            
            Text("Main Content Area")
                .font(.title)
                .foregroundColor(.white)
        }
        .background(.black)
    }
}