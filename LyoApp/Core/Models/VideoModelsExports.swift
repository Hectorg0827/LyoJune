// This is a simple helper file to make VideoModels types visible to the rest of the app
// We're implementing this to fix the "No such module 'VideoModels'" error

// Re-export necessary types
@_exported import struct Foundation.Date
@_exported import struct Foundation.UUID
@_exported import class Foundation.NSObject

public typealias Video = VideoModels.Video
public typealias VideoTranscript = VideoModels.VideoTranscript
public typealias VideoNote = VideoModels.VideoNote
public typealias WatchProgressResponse = VideoModels.WatchProgressResponse
public typealias UpdateWatchProgressRequest = VideoModels.UpdateWatchProgressRequest
public typealias CreateVideoNoteRequest = VideoModels.CreateVideoNoteRequest

// This is a namespace type to make sure the compiler finds our types
public struct VideoModels {
    private init() {}
    
    public typealias Video = VideoModels.Video
    public typealias VideoTranscript = VideoModels.VideoTranscript
    public typealias VideoNote = VideoModels.VideoNote
    public typealias WatchProgressResponse = VideoModels.WatchProgressResponse
    public typealias UpdateWatchProgressRequest = VideoModels.UpdateWatchProgressRequest
    public typealias CreateVideoNoteRequest = VideoModels.CreateVideoNoteRequest
}
