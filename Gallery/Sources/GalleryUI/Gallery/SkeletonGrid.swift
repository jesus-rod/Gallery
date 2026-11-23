import SwiftUI

struct SkeletonGrid: View {
    var showsHero = false

    var body: some View {
        ScrollView {
            if showsHero {
                Rectangle()
                    .fill(.quaternary)
                    .containerRelativeFrame(.vertical) { length, _ in
                        min(length * 0.6, Design.Hero.regularWidthMaximumHeight)
                    }
            }
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
