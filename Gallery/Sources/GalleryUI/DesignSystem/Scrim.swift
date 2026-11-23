import SwiftUI

struct Scrim: View {
    var body: some View {
        LinearGradient(colors: [.clear, .black.opacity(Design.Opacity.scrim)], startPoint: .top, endPoint: .bottom)
    }
}
