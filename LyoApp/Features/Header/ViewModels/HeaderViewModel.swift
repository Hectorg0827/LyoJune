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
    @Published var selectedStory: Story?
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
    private let apiService: EnhancedAPIService
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
        webSocketManager.messagesPublisher
            .compactMap { [weak self] message in
                self?.handleWebSocketMessage(message)
            }
            .sink { _ in }
            .store(in: &cancellables)
    }
    
    private func handleWebSocketMessage(_ message: WebSocketMessage) {
        switch message.type {
        case "new_message":
            unreadMessagesCount += 1
            Task { await loadConversations() }
        case "new_story":
            Task { await loadStories() }
        case "story_update":
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
            let fetchedStories = try await apiService.getStories()
            stories = fetchedStories
            coreDataManager.cacheStories(fetchedStories)
        } catch {
            // Fall back to cached data if API fails
            if let cachedStories = coreDataManager.fetchCachedStories() {
                stories = cachedStories
            } else {
                stories = Story.sampleStories
            }
            print("Failed to load stories: \(error.localizedDescription)")
        }
    }
    
    private func loadConversations() async {
        do {
            let fetchedConversations = try await apiService.getConversations()
            conversations = fetchedConversations
            coreDataManager.cacheConversations(fetchedConversations)
        } catch {
            // Fall back to cached data if API fails
            if let cachedConversations = coreDataManager.fetchCachedConversations() {
                conversations = cachedConversations
            } else {
                conversations = Conversation.sampleConversations
            }
            print("Failed to load conversations: \(error.localizedDescription)")
        }
    }
    
    private func loadUserProfile() async {
        do {
            let fetchedProfile = try await apiService.getUserProfile()
            userProfile = fetchedProfile
            coreDataManager.cacheUserProfile(fetchedProfile)
        } catch {
            // Fall back to cached data if API fails
            if let cachedProfile = coreDataManager.fetchCachedUserProfile() {
                userProfile = cachedProfile
            }
            print("Failed to load user profile: \(error.localizedDescription)")
        }
    }
    
    private func loadSearchSuggestions() async {
        do {
            let fetchedSuggestions = try await apiService.getSearchSuggestions(query: "")
            searchSuggestions = fetchedSuggestions
        } catch {
            // Fall back to sample data if API fails
            searchSuggestions = SearchSuggestion.sampleSuggestions
            print("Failed to load search suggestions: \(error.localizedDescription)")
        }
    }
    
    private func updateStory(storyId: String) async {
        do {
            let updatedStory = try await apiService.getStory(storyId: storyId)
            if let index = stories.firstIndex(where: { $0.id == storyId }) {
                stories[index] = updatedStory
                coreDataManager.cacheStories(stories)
            }
        } catch {
            print("Failed to update story: \(error.localizedDescription)")
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
            await voiceManager.startListening()
            
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
                let results = try await searchService.performAISearch(query: query)
                await MainActor.run {
                    self.searchSuggestions = results.suggestions
                    // Navigate to search results or update UI accordingly
                    self.isSearchActive = true
                    self.showSearch = true
                }
            } catch {
                print("Search failed: \(error)")
            }
        }
    }
    
    // MARK: - Public API Methods
    
    func markStoryAsWatched(_ storyId: UUID) {
        Task {
            do {
                try await storiesService.markStoryAsWatched(storyId)
                
                // Update local state
                if let index = stories.firstIndex(where: { $0.id == storyId }) {
                    stories[index] = Story(
                        id: stories[index].id,
                        username: stories[index].username,
                        avatarColors: stories[index].avatarColors,
                        hasUnwatchedStory: false,
                        storyType: stories[index].storyType,
                        timestamp: stories[index].timestamp,
                        previewImageURL: stories[index].previewImageURL
                    )
                }
            } catch {
                print("Failed to mark story as watched: \(error.localizedDescription)")
            }
        }
    }
    
    func markConversationAsRead(_ conversationId: UUID) {
        Task {
            do {
                try await messagesService.markConversationAsRead(conversationId)
                
                // Update local state
                if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                    conversations[index] = Conversation(
                        id: conversations[index].id,
                        otherParticipant: conversations[index].otherParticipant,
                        lastMessage: conversations[index].lastMessage,
                        timestamp: conversations[index].timestamp,
                        hasUnreadMessages: false,
                        unreadCount: 0
                    )
                }
            } catch {
                print("Failed to mark conversation as read: \(error.localizedDescription)")
            }
        }
    }
    
    func sendMessage(_ message: String, to conversationId: UUID) {
        Task {
            do {
                let newMessage = try await messagesService.sendMessage(message, to: conversationId)
                
                // Update local conversation
                if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                    conversations[index] = Conversation(
                        id: conversations[index].id,
                        otherParticipant: conversations[index].otherParticipant,
                        lastMessage: message,
                        timestamp: newMessage.timestamp,
                        hasUnreadMessages: false,
                        unreadCount: 0
                    )
                }
            } catch {
                print("Failed to send message: \(error.localizedDescription)")
            }
        }
    }
    
    func performSearch(_ query: String) {
        Task {
            do {
                try await searchService.saveSearch(query)
                // Additional search logic can be added here
            } catch {
                print("Failed to save search: \(error.localizedDescription)")
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
                let suggestions = try await apiService.getSearchSuggestions(query: searchText)
                
                // Add dynamic suggestion at the top
                var allSuggestions = [
                    SearchSuggestion(
                        id: UUID(),
                        text: searchText,
                        type: .searchQuery,
                        icon: "magnifyingglass"
                    )
                ]
                allSuggestions.append(contentsOf: suggestions)
                
                self.searchSuggestions = allSuggestions
            } catch {
                // Generate suggestions based on search text
                let dynamicSuggestion = SearchSuggestion(
                    id: UUID(),
                    text: searchText,
                    type: .searchQuery,
                    icon: "magnifyingglass"
                )
                
                self.searchSuggestions = [dynamicSuggestion] + SearchSuggestion.sampleSuggestions.filter {
                    $0.text.localizedCaseInsensitiveContains(searchText)
                }.prefix(5)
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
        
        // Simulate occasional new content for demo purposes
        Timer.scheduledTimer(withTimeInterval: 120.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                // Randomly add demo content occasionally
                if Bool.random() && self.stories.count < 10 {
                    self.simulateNewStory()
                }
                
                if Bool.random() && self.conversations.count < 10 {
                    self.simulateNewMessage()
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
    
    func closeStoryViewer() {
        selectedStory = nil
        isShowingStoryViewer = false
    }
    
    func closeChatView() {
        selectedConversation = nil
        isShowingChatView = false
    }
}