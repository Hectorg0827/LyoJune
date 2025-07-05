import SwiftUI

struct ModernOfflineIndicatorView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption)
                .foregroundColor(.white)
            
            Text("Offline")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange)
        )
        .shadow(radius: 2)
        .padding(.top, 8)
    }
}

#Preview {
    ModernOfflineIndicatorView()
}
