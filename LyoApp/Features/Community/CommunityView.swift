import SwiftUI
import MapKit

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var selectedTab = 0
    @State private var showingCreateEvent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Glass background effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom tab selector
                    CommunityTabSelector(selectedTab: $selectedTab)
                    
                    // Tab content
                    TabView(selection: $selectedTab) {
                        LocalEventsView(events: viewModel.localEvents)
                            .tag(0)
                        
                        StudyGroupsView(groups: viewModel.studyGroups)
                            .tag(1)
                        
                        CommunityMapView(locations: viewModel.learningLocations)
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateEvent = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateEventView()
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
}

struct CommunityTabSelector: View {
    @Binding var selectedTab: Int
    private let tabs = ["Events", "Groups", "Map"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(.body)
                            .fontWeight(selectedTab == index ? .semibold : .medium)
                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.blue : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Material.ultraThin)
    }
}

struct LocalEventsView: View {
    let events: [CommunityEvent]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(events) { event in
                    EventCard(event: event)
                        .padding(.horizontal)
                }
            }
            .padding(.top)
        }
    }
}

struct EventCard: View {
    let event: CommunityEvent
    @State private var isJoined = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(event.organizer)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isJoined.toggle()
                    }
                }) {
                    Text(isJoined ? "Joined" : "Join")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Material.ultraThin)
                        .background(isJoined ? Color.clear : Color.blue.opacity(0.8))
                        )
                        .foregroundColor(.white)
                }
            }
            
            // Event details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text(event.date, style: .date)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.blue)
                    Text(event.location)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                HStack {
                    Image(systemName: "person.2")
                        .foregroundColor(.blue)
                    Text("\(event.attendees) attending")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            Text(event.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct StudyGroupsView: View {
    let groups: [StudyGroup]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groups) { group in
                    StudyGroupCard(group: group)
                        .padding(.horizontal)
                }
            }
            .padding(.top)
        }
    }
}

struct StudyGroupCard: View {
    let group: StudyGroup
    @State private var isJoined = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group header
            HStack {
                Circle()
                    .fill(group.category.gradient)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: group.category.icon)
                            .foregroundColor(.white)
                            .font(.title3)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("\(group.memberCount) members")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isJoined.toggle()
                    }
                }) {
                    Text(isJoined ? "Joined" : "Join")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Material.ultraThin)
                        .background(isJoined ? Color.clear : Color.blue.opacity(0.8))
                        )
                        .foregroundColor(.white)
                }
            }
            
            Text(group.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
            
            // Group stats
            HStack {
                GroupStatItem(icon: "clock", value: "Weekly") // Default frequency
                
                Spacer()
                
                GroupStatItem(icon: "star.fill", value: "4.5") // Default rating
                
                Spacer()
                
                GroupStatItem(icon: "message", value: !group.isPrivate ? "Public" : "Private")
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct GroupStatItem: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(value)
        }
    }
}

struct CommunityMapView: View {
    let locations: [LearningLocation]
    
    var body: some View {
        ZStack {
            Map {
                ForEach(locations) { location in
                    Annotation(location.name, coordinate: location.coordinate) {
                        MapPinView(location: location)
                    }
                }
            }
            .mapStyle(.standard)
            .cornerRadius(0)
            
            // Floating info card
            VStack {
                Spacer()
                
                HStack {
                    MapInfoCard()
                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct MapPinView: View {
    let location: LearningLocation
    
    var body: some View {
        VStack {
            Circle()
                .fill(location.type.color)
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: location.type.icon)
                        .foregroundColor(.white)
                        .font(.caption)
                )
            
            Text(location.name)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Material.ultraThin)
                )
        }
    }
}

struct MapInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Learning Locations")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Discover study spots and learning events near you")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThin)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var eventTitle = ""
    @State private var eventDescription = ""
    @State private var eventDate = Date()
    @State private var eventLocation = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Glass background effect
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Create Event")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    VStack(spacing: 16) {
                        GlassFormField(
                            title: "Event Title",
                            text: $eventTitle,
                            placeholder: "Enter event title",
                            icon: "textformat"
                        )
                        
                        GlassFormField(
                            title: "Location",
                            text: $eventLocation,
                            placeholder: "Enter location",
                            icon: "location"
                        )
                        
                        // Date picker would go here
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $eventDescription)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .frame(height: 100)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Material.ultraThin)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Create Event")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Material.ultraThin, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    CommunityView()
}