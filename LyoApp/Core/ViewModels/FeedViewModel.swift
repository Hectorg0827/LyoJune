import SwiftUI

@MainActor
class FeedViewModel: ObservableObject {
    @Published var videos: [EducationalVideo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMoreContent = true
    
    private var currentPage = 0
    private let pageSize = 10
    
    func loadVideos() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let newVideos = EducationalVideo.mockVideos()
            videos = newVideos
            currentPage = 1
        } catch {
            errorMessage = "Failed to load videos: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadMoreVideos() async {
        guard !isLoading && hasMoreContent else { return }
        
        isLoading = true
        
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
            
            let newVideos = EducationalVideo.mockVideos(offset: currentPage * pageSize)
            videos.append(contentsOf: newVideos)
            currentPage += 1
            
            if newVideos.count < pageSize {
                hasMoreContent = false
            }
        } catch {
            errorMessage = "Failed to load more videos"
        }
        
        isLoading = false
    }
    
    func refreshVideos() async {
        currentPage = 0
        hasMoreContent = true
        videos.removeAll()
        await loadVideos()
    }
}