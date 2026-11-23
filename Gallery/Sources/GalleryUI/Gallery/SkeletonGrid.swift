import SwiftUI

struct SkeletonGrid: View {
    var body: some View {
        ScrollView {
            SquareGrid { _ in
                ForEach(0..<12, id: \.self) { _ in
                    Rectangle()
                        .fill(.quaternary)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .scrollDisabled(true)
        .accessibilityElement()
        .accessibilityLabel(Text("Loading photos", bundle: .module))
        .accessibilityIdentifier("skeleton")
    }
}
