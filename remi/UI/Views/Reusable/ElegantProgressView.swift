import SwiftUI

struct ElegantProgressView: View {
    var body: some View {
        VStack(spacing: 15) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Remi is thinking...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Material.ultraThick)
        .transition(.opacity.animation(.easeInOut))
    }
}

struct ElegantProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ElegantProgressView()
    }
}
