import SwiftUI
import Foundation
import Combine

@MainActor
class HeaderViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var headerState: HeaderState = .minimized
    @Published var isStoryDrawerOpen = false
    @Published var unreadMessagesCount = 0
    @Published var stories: [Story] = []
    @Published var conversations: [Conversation] = []
    @Published var searchSuggestions: [SearchSuggestion] = []
    @Published var userProfile: UserProfile?
    
    // MARK: - UI State
    @Published var showProfileSheet = false
    @Published var showMessages = false
    @Published var showSearch = false
    @Published var isSearchActive = false
    @Published var searchText = ""
    @Published var isListeningForVoice = false
    
    // MARK: - Animation State
    @Published var lastInteractionTime = Date()
    @Published var shouldAutoMinimize = true
    
    // MARK: - Private Properties
    private var autoMinimizeTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let autoMinimizeDelay: TimeInterval = 5.0
    
    // MARK: - Services
    private let storiesService = StoriesService()
    private let messagesService = MessagesService()
    private let searchService = SearchService()
    private let userService = UserService()
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadInitialData()
    }
    
    deinit {
        autoMinimizeTimer?.invalidate()
        autoMinimizeTimer = nil
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Auto-minimize timer management
        $lastInteractionTime
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.startAutoMinimizeTimer()
            }
            .store(in: &cancellables)
        
        // Update unread messages count
        $conversations
            .map { conversations in
                conversations.filter { $0.hasUnreadMessages }.count
            }
            .assign(to: &$unreadMessagesCount)
        
        // Search suggestions based on search text
        $searchText
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.updateSearchSuggestions(for: searchText)
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        // Load stories
        stories = Story.sampleStories
        
        // Load conversations
        conversations = Conversation.sampleConversations
        
        // Load search suggestions
        searchSuggestions = SearchSuggestion.sampleSuggestions
        
        // Load user profile
        userProfile = UserProfile.sampleProfile
        
        // Simulate real-time updates
        startRealTimeUpdates()
    }
    
    // MARK: - Public Methods
    
    func handleHeaderTap() {
        recordInteraction()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            switch headerState {
            case .minimized:
                headerState = .expanded
            case .expanded:
                if isStoryDrawerOpen {
                    isStoryDrawerOpen = false
                } else {
                    headerState = .minimized
                }
            case .storyDrawerOpen:
                isStoryDrawerOpen = false
                headerState = .minimized
            }
        }
    }
    
    func handleIconTap() {
        recordInteraction()
        expandIfNeeded()
    }
    
    func toggleStoryDrawer() {
        recordInteraction()
        expandIfNeeded()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isStoryDrawerOpen.toggle()
            headerState = isStoryDrawerOpen ? .storyDrawerOpen : .expanded
        }
    }
    
    func openSearch() {
        recordInteraction()
        showSearch = true
        isSearchActive = true
    }
    
    func closeSearch() {
        showSearch = false
        isSearchActive = false
        searchText = ""
        isListeningForVoice = false
    }
    
    func openMessages() {
        recordInteraction()
        showMessages = true
        
        // Mark messages as read after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.markAllMessagesAsRead()
        }
    }
    
    func closeMessages() {
        showMessages = false
    }
    
    func openProfile() {
        recordInteraction()
        showProfileSheet = true
    }
    
    func closeProfile() {
        showProfileSheet = false
    }
    
    func handleStoryTap(_ story: Story) {
        recordInteraction()
        
        // Mark story as watched
        if let index = stories.firstIndex(where: { $0.id == story.id }) {
            stories[index] = Story(
                id: story.id,
                username: story.username,
                displayName: story.displayName,
                initials: story.initials,
                avatarColors: story.avatarColors,
                hasUnwatchedStory: false,
                storyType: story.storyType,
                timestamp: story.timestamp,
                previewImageURL: story.previewImageURL
            )
        }
        
        // TODO: Open story viewer
        print("Opening story for: \(story.displayName)")
    }
    
    func handleConversationTap(_ conversation: Conversation) {
        recordInteraction()
        
        // Mark conversation as read
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index].hasUnreadMessages = false
        }
        
        // TODO: Open chat view
        print("Opening conversation with: \(conversation.name)")
    }
    
    func startVoiceSearch() {
        recordInteraction()
        isListeningForVoice = true
        
        // TODO: Implement voice recognition
        
        // Simulate voice input
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isListeningForVoice = false
            self.searchText = "What is quantum physics?"
        }
    }
    
    func stopVoiceSearch() {
        isListeningForVoice = false
    }
    
    func executeSearch(_ query: String) {
        recordInteraction()
        searchText = query
        
        // TODO: Implement AI-powered search
        print("Executing search for: \(query)")
    }
    
    // MARK: - Private Methods
    
    private func recordInteraction() {
        lastInteractionTime = Date()
    }
    
    private func expandIfNeeded() {
        if headerState == .minimized {
            withAnimation(.easeInOut(duration: 0.3)) {
                headerState = .expanded
            }
        }
    }
    
    private func startAutoMinimizeTimer() {
        guard shouldAutoMinimize else { return }
        
        stopAutoMinimizeTimer()
        
        autoMinimizeTimer = Timer.scheduledTimer(withTimeInterval: autoMinimizeDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                // Don't auto-minimize if any modals are open
                guard !self.showSearch && !self.showMessages && !self.showProfileSheet else { return }
                
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.headerState = .minimized
                    self.isStoryDrawerOpen = false
                }
            }
        }
    }
    
    private func stopAutoMinimizeTimer() {
        autoMinimizeTimer?.invalidate()
        autoMinimizeTimer = nil
    }
    
    private func updateSearchSuggestions(for searchText: String) {
        guard !searchText.isEmpty else {
            searchSuggestions = SearchSuggestion.sampleSuggestions
            return
        }
        
        // Filter suggestions based on search text
        let filtered = SearchSuggestion.sampleSuggestions.filter { suggestion in
            suggestion.query.localizedCaseInsensitiveContains(searchText)
        }
        
        // Add dynamic suggestions
        let dynamicSuggestion = SearchSuggestion(
            query: searchText,
            category: .general,
            popularity: 0,
            isPersonalized: false
        )
        
        searchSuggestions = [dynamicSuggestion] + filtered
    }
    
    private func markAllMessagesAsRead() {
        for index in conversations.indices {
            conversations[index].hasUnreadMessages = false
        }
    }
    
    private func startRealTimeUpdates() {
        // Simulate new messages
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if Bool.random() {
                    self.simulateNewMessage()
                }
                
                if Bool.random() {
                    self.simulateNewStory()
                }
            }
        }
    }
    
    private func simulateNewMessage() {
        let randomConversation = conversations.randomElement()
        guard let conversation = randomConversation else { return }
        
        // Mark a random conversation as having new messages
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index].hasUnreadMessages = true
        }
    }
    
    private func simulateNewStory() {
        let randomStory = stories.randomElement()
        guard let story = randomStory else { return }
        
        // Mark a random story as having new content
        if let index = stories.firstIndex(where: { $0.id == story.id }) {
            stories[index] = Story(
                id: story.id,
                username: story.username,
                displayName: story.displayName,
                initials: story.initials,
                avatarColors: story.avatarColors,
                hasUnwatchedStory: true,
                storyType: story.storyType,
                timestamp: Date(),
                previewImageURL: story.previewImageURL
            )
        }
    }
}

// MARK: - Mock Services

class StoriesService {
    func fetchStories() async -> [Story] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return Story.sampleStories
    }
    
    func markStoryAsWatched(_ storyId: UUID) async {
        // Simulate API call
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

class MessagesService {
    func fetchConversations() async -> [Conversation] {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return Conversation.sampleConversations
    }
    
    func markConversationAsRead(_ conversationId: UUID) async {
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func sendMessage(_ message: String, to conversationId: UUID) async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

class SearchService {
    func searchContent(_ query: String) async -> [SearchResult] {
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        return [] // TODO: Implement search results
    }
    
    func getSuggestions(for query: String) async -> [SearchSuggestion] {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return SearchSuggestion.sampleSuggestions.filter { suggestion in
            suggestion.query.localizedCaseInsensitiveContains(query)
        }
    }
}

class UserService {
    func fetchUserProfile() async -> UserProfile? {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return UserProfile.sampleProfile
    }
    
    func updateUserProfile(_ profile: UserProfile) async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

// MARK: - Search Result Model

struct SearchResult: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: ResultType
    let relevanceScore: Double
    let url: String?
    
    enum ResultType: String, CaseIterable {
        case course = "course"
        case video = "video"
        case article = "article"
        case book = "book"
        case user = "user"
        case discussion = "discussion"
        
        var icon: String {
            switch self {
            case .course:
                return "graduationcap"
            case .video:
                return "play.rectangle"
            case .article:
                return "doc.text"
            case .book:
                return "book"
            case .user:
                return "person"
            case .discussion:
                return "bubble.left.and.bubble.right"
            }
        }
    }
}