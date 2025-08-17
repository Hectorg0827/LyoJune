import SwiftUI

/// A view for composing and uploading a new post.
struct ComposerView: View {

    @StateObject private var viewModel: ComposerViewModel
    @Binding var isPresented: Bool

    init(viewModel: ComposerViewModel, isPresented: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _isPresented = isPresented
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                mediaSelector

                TextField("Write a caption...", text: $viewModel.caption, axis: .vertical)
                    .lineLimit(5...10)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                if viewModel.uploadState != .idle {
                    uploadProgressView
                }

                Spacer()

                Button(action: viewModel.createPost) {
                    Text("Post")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.uploadState != .idle)
            }
            .padding()
            .navigationTitle("New Post")
            .navigationBarItems(leading: Button("Cancel") { isPresented = false })
            .toast(toast: $viewModel.errorToast)
            .onChange(of: viewModel.uploadState) { newState in
                if newState == .success {
                    // Dismiss the view on successful post.
                    isPresented = false
                }
            }
        }
    }

    @ViewBuilder
    private var mediaSelector: some View {
        Button(action: {
            // In a real app, this would open a PHPickerViewController.
            // For now, we'll just simulate selecting some data.
            viewModel.selectedMedia = "FakeVideoData".data(using: .utf8)
        }) {
            ZStack {
                if let _ = viewModel.selectedMedia {
                    Rectangle()
                        .fill(Color.blue)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                } else {
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundColor(.secondary)
                        .font(.largeTitle)
                }
            }
            .frame(height: 200)
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private var uploadProgressView: some View {
        VStack {
            ProgressView(value: progressValue, total: 1.0)
            Text(progressText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var progressValue: Double {
        switch viewModel.uploadState {
        case .uploading(let progress):
            return progress
        case .success:
            return 1.0
        default:
            return 0.0
        }
    }

    private var progressText: String {
        switch viewModel.uploadState {
        case .idle:
            return ""
        case .presigning:
            return "Preparing upload..."
        case .uploading:
            return "Uploading..."
        case .committing:
            return "Finishing up..."
        case .posting:
            return "Posting..."
        case .success:
            return "Success!"
        }
    }
}
