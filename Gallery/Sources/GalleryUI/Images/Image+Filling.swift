import SwiftUI

extension Image {
    func filling() -> some View {
        Color.clear
            .overlay {
                resizable()
                    .scaledToFill()
            }
            .clipped()
    }
}
