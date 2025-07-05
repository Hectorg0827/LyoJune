import SwiftUI
import Foundation
import Combine

@MainActor
class HeaderViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var headerState: HeaderState = .minimized
    @Published var isStoryDrawerOpen = false
    @Published var unreadMessagesCount = 0
    @Published var stories: [LearningStory] = []
    @Published var conversations: [HeaderConversation] = []
    @Published var searchSuggestions: [SearchSuggestion] = []
    @Published var userProfile: HeaderUserProfile?
    @Published var isOffline = false
    @Published var lastSyncTime: Date?
    
    // MARK: - UI State
    @Published var showProfileSheet = false
    @Published var showMessages = false
    @Published var showSearch = false
    @Published var isSearchActive = false
    @Published var searchText = ""
    @Published var isListeningForVoice = false
    @Published var selectedStory: LearningStory?
    @Published var isShowingStoryViewer = false
    @Published var selectedConversation: HeaderConversation?
    @Published var isShowingChatView = false
    
    // MARK: - Animation State
    @Published var lastInteractionTime = Date()
    @Published var shouldAutoMinimize = true
    
    // MARK: - Private Properties
    private var autoMinimizeTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let autoMinimizeDelay: TimeInterval = 5.0
    
    // MARK: - Services
    private let apiService: EnhancedNetworkManager
    private let coreDataManager: CoreDataManager
    private let webSocketManager: WebSocketManager
    private let voiceManager = GemmaVoiceManager.shared
    
    // MARK: - Initialization
    init(serviceFactory: EnhancedServiceFactory? = nil) {
        let factory: EnhancedServiceFactory
        if let serviceFactory = serviceFactory {
            factory = serviceFactory
        } else {
            factory = EnhancedServiceFactory.shared
        }
        self.apiService = factory.apiService
        self.coreDataManager = factory.coreDataManager
        self.webSocketManager = factory.webSocketManager
        setupBindings()
        setupWebSocketListeners()
        loadInitialData()
    }
    
    deinit {
        autoMinimizeTimer?.invalidate()
        autoMinimizeTimer = nil
        cancellables.removeAll()
    }
    
    // MARK: - Setup Methods
    private func setupWebSocketListeners() {
        // Set up real-time message listening
        if let messagesPublisher = webSocketManager.messagesPublisher {
            messagesPublisher
                .sink { [weak self] message in
                    self?.handleWebSocketMessage(message)
                }
                .store(in: &cancellables)
        }
        
        print("WebSocket listeners set up successfully")
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        switch message.type {
        case .chat:
            unreadMessagesCount += 1
            Task { await loadConversations() }
        case .notification:
            Task { await loadStories() }
        case .userUpdate:
            if let storyId = message.data["storyId"] as? String {
                Task { await updateStory(storyId: storyId) }
            }
        default:
            break
        }
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
        Task {
            await loadStories()
            await loadConversations()
            await loadUserProfile()
            await loadSearchSuggestions()
            
            // Start real-time updates after initial data is loaded
            startRealTimeUpdates()
        }
    }
    
    private func loadStories() async {
        do {
            let storiesData = try await apiClient.getStories()
            DispatchQueue.main.async {
                self.stories = storiesData
            }
            print("Loaded \(storiesData.count) stories from API")
        } catch {
            print("Error loading stories: \(error)")
            DispatchQueue.main.async {
                self.stories = []
            }
        }
    }
    
    private func loadConversations() async {
        do {
            let conversationsData = try await apiClient.getConversations()
            DispatchQueue.main.async {
                self.conversations = conversationsData
                self.unreadMessagesCount = conversationsData.reduce(0) { $0 + $1.unreadCount }
            }
            print("Loaded \(conversationsData.count) conversations from API")
        } catch {
            print("Error loading conversations: \(error)")
            DispatchQueue.main.async {
                self.conversations = []
            }
        }
    }
    
    private func loadUserProfile() async {
        do {
            let profile = try await apiClient.getUserProfile()
            DispatchQueue.main.async {
                self.userProfile = profile
            }
            print("Loaded user profile from API")
        } catch {
            print("Error loading user profile: \(error)")
            DispatchQueue.main.async {
                self.userProfile = nil
            }
        }
    }
    
    private func loadSearchSuggestions() async {
        do {
            let suggestions = try await apiClient.getSearchSuggestions()
            DispatchQueue.main.async {
                self.searchSuggestions = suggestions
            }
            print("Loaded \(suggestions.count) search suggestions from API")
        } catch {
            print("Error loading search suggestions: \(error)")
            DispatchQueue.main.async {
                self.searchSuggestions = []
            }
        }
    }
    
    private func updateStory(storyId: String) async {
        do {
            let updatedStory = try await apiClient.getStory(storyId: storyId)
            DispatchQueue.main.async {
                if let index = self.stories.firstIndex(where: { $0.id.uuidString == storyId }) {
                    self.stories[index] = updatedStory
                }
            }
            print("Updated story: \(storyId)")
        } catch {
            print("Error updating story: \(error)")
        }
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
    
    func handleStoryTap(_ story: LearningStory) {
        recordInteraction()
        
        // Mark story as watched by updating local state
        if let index = stories.firstIndex(where: { $0.id == story.id }) {
            // Update story viewing status without recreating the object
            stories[index] = LearningStory(
                id: story.id,
                userId: story.userId,
                username: story.username,
                userAvatar: story.userAvatar,
                mediaURL: story.mediaURL,
                mediaType: story.mediaType,
                duration: story.duration,
                caption: story.caption,
                createdAt: story.createdAt,
                viewsCount: story.viewsCount + 1,
                isViewed: true
            )
        }
        
        // Open story viewer
        selectedStory = story
        isShowingStoryViewer = true
    }
    
    func handleConversationTap(_ conversation: HeaderConversation) {
        recordInteraction()
        
        // Mark conversation as read
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index].hasUnreadMessages = false
        }
        
        // Open chat view
        selectedConversation = conversation
        isShowingChatView = true
    }
    
    func startVoiceSearch() {
        recordInteraction()
        isListeningForVoice = true
        
        // Implement voice recognition
        Task {
            voiceManager.startListening()
            
            // Wait for the transcript to be updated
            try await Task.sleep(for: .seconds(0.5))
            
            await MainActor.run {
                let transcript = voiceManager.currentTranscript
                self.isListeningForVoice = false
                if !transcript.isEmpty {
                    self.searchText = transcript
                    self.executeSearch(transcript)
                }
            }
        }
    }
    
    func stopVoiceSearch() {
        isListeningForVoice = false
        voiceManager.stopListening()
    }
    
    func executeSearch(_ query: String) {
        recordInteraction()
        searchText = query
        
        // Implement AI-powered search
        Task {
            do {
                let results = try await apiClient.performAISearch(query: query)
                await MainActor.run {
                    self.searchSuggestions = results
                    self.isSearchActive = true
                    self.showSearch = true
                }
            } catch {
                print("Error performing AI search: \(error)")
                await MainActor.run {
                    self.searchSuggestions = []
                    self.isSearchActive = true
                    self.showSearch = true
                }
            }
        }
    }
    
    // MARK: - Public API Methods
    
    func markStoryAsWatched(_ storyId: UUID) {
        Task {
            do {
                try await apiClient.markStoryAsWatched(storyId: storyId)
                
                // Update local state
                DispatchQueue.main.async {
                    if let index = self.stories.firstIndex(where: { $0.id == storyId }) {
                        self.stories[index].isWatched = true
                    }
                }
                
                print("Marked story as watched: \(storyId)")
                
            } catch {
                print("Error marking story as watched: \(error)")
            }
        }
    }
    
    func markConversationAsRead(_ conversationId: UUID) {
        Task {
            do {
                try await apiClient.markConversationAsRead(conversationId: conversationId)
                
                // Update local state
                DispatchQueue.main.async {
                    if let index = self.conversations.firstIndex(where: { $0.id == conversationId }) {
                        self.conversations[index].hasUnreadMessages = false
                        self.unreadMessagesCount = max(0, self.unreadMessagesCount - 1)
                    }
                }
                
                print("Marked conversation as read: \(conversationId)")
                
            } catch {
                print("Error marking conversation as read: \(error)")
            }
        }
    }
    
    func sendMessage(_ message: String, to conversationId: UUID) {
        Task {
            do {
                let newMessage = try await apiClient.sendMessage(
                    message: message,
                    to: conversationId
                )
                
                // Update local conversation
                DispatchQueue.main.async {
                    if let index = self.conversations.firstIndex(where: { $0.id == conversationId }) {
                        self.conversations[index].lastMessage = message
                        self.conversations[index].timestamp = newMessage.timestamp
                        self.conversations[index].hasUnreadMessages = false
                    }
                }
                
                print("Sent message: \(message) to conversation: \(conversationId)")
                
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
    
    func performSearch(_ query: String) {
        Task {
            do {
                try await apiClient.saveSearch(query: query)
                print("Saved search: \(query)")
                
                // Trigger search results update
                await handleAIAssist(query)
                
            } catch {
                print("Error saving search: \(error)")
            }
        }
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
            Task {
                await loadSearchSuggestions()
            }
            return
        }
        
        Task {
            do {
                let suggestions = try await apiClient.getSearchSuggestions(for: searchText)
                
                // Add dynamic suggestion at the top
                var allSuggestions = [
                    SearchSuggestion(
                        query: searchText,
                        category: .general,
                        popularity: 75,
                        isPersonalized: true
                    )
                ]
                allSuggestions.append(contentsOf: suggestions)
                
                DispatchQueue.main.async {
                    self.searchSuggestions = allSuggestions
                }
                
            } catch {
                print("Error loading search suggestions: \(error)")
                DispatchQueue.main.async {
                    self.searchSuggestions = [
                        SearchSuggestion(
                            query: searchText,
                            category: .general,
                            popularity: 75,
                            isPersonalized: true
                        )
                    ]
                }
            }
        }
    }
    
    private func markAllMessagesAsRead() {
        for index in conversations.indices {
            conversations[index].hasUnreadMessages = false
        }
    }
    
    private func startRealTimeUpdates() {
        // Set up periodic refresh for stories and conversations
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                // Refresh data periodically
                await self.loadStories()
                await self.loadConversations()
            }
        }
    }
    
    func closeStoryViewer() {
        selectedStory = nil
        isShowingStoryViewer = false
    }
    
    func closeChatView() {
        selectedConversation = nil
        isShowingChatView = false
    }
}