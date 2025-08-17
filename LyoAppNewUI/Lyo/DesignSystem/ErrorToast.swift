import SwiftUI

/// A model to define the content of a toast notification.
struct Toast: Equatable {
    let message: String
    let style: Style

    enum Style {
        case error
        case success
        case info

        var iconName: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .error: return .red
            case .success: return .green
            case .info: return .blue
            }
        }
    }
}

/// A view that displays a toast notification at the top of the screen.
private struct ErrorToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: toast.style.iconName)
                .font(.headline)
                .foregroundColor(toast.style.color)

            Text(toast.message)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 12)
        )
        .padding(.horizontal)
    }
}

/// A view modifier that presents a toast when a binding is active.
private struct ToastModifier: ViewModifier {

    @Binding var toast: Toast?

    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                ZStack {
                    if let toast = toast {
                        VStack {
                            ErrorToastView(toast: toast)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            Spacer()
                        }
                    }
                }
                .animation(.spring(), value: toast)
            )
            .onChange(of: toast) { _ in
                showToast()
            }
    }

    private func showToast() {
        guard toast != nil else { return }

        // Dismiss after a delay
        let task = DispatchWorkItem {
            withAnimation {
                toast = nil
            }
        }

        workItem?.cancel()
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: task)
    }
}

// MARK: - View Extension

extension View {
    /// Presents a toast notification.
    /// - Parameter toast: A binding to an optional `Toast` item. When the item is non-nil, the toast is presented.
    func toast(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}


#if DEBUG
struct ErrorToast_Previews: PreviewProvider {
    static var previews: some View {

        struct PreviewWrapper: View {
            @State private var toast: Toast? = nil

            var body: some View {
                VStack(spacing: 20) {
                    Button("Show Error Toast") {
                        toast = Toast(message: "Failed to upload post. Please try again.", style: .error)
                    }
                    Button("Show Success Toast") {
                        toast = Toast(message: "Your profile has been updated.", style: .success)
                    }
                    Button("Show Info Toast") {
                        toast = Toast(message: "A new version of the app is available.", style: .info)
                    }
                }
                .toast(toast: $toast)
            }
        }

        return PreviewWrapper()
    }
}
#endif
