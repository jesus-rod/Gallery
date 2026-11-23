import SwiftUI

struct Scrim: View {
    var opacity = Design.Opacity.scrim

    var body: some View {
        LinearGradient(colors: [.clear, .black.opacity(opacity)], startPoint: .top, endPoint: .bottom)
    }
}
