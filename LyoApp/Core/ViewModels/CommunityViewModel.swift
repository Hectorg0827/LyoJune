import SwiftUI

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var localEvents: [CommunityEvent] = []
    @Published var studyGroups: [StudyGroup] = []
    @Published var learningLocations: [LearningLocation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            localEvents = CommunityEvent.mockEvents()
            studyGroups = StudyGroup.mockGroups()
            learningLocations = LearningLocation.mockLocations()
        } catch {
            errorMessage = "Failed to load community data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        localEvents.removeAll()
        studyGroups.removeAll()
        learningLocations.removeAll()
        await loadData()
    }
    
    func joinEvent(_ event: CommunityEvent) async {
        // Simulate joining event API call
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Update event attendance
        if let index = localEvents.firstIndex(where: { $0.id == event.id }) {
            // In a real app, you'd update the event's attendee count
        }
    }
    
    func joinStudyGroup(_ group: StudyGroup) async {
        // Simulate joining study group API call
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Update group membership
        if let index = studyGroups.firstIndex(where: { $0.id == group.id }) {
            // In a real app, you'd update the group's member count
        }
    }
    
    func createEvent(title: String, description: String, date: String, location: String) async {
        // Simulate creating event API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let newEvent = CommunityEvent(
            title: title,
            description: description,
            organizer: "You",
            date: date,
            location: location,
            attendees: 1,
            maxAttendees: 50,
            category: .programming, // Default category
            isOnline: location.lowercased().contains("online"),
            price: nil
        )
        
        localEvents.insert(newEvent, at: 0)
    }
}