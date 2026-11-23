import SwiftUI

struct SquareGrid<Content: View>: View {
    @ViewBuilder let content: (_ cellSide: CGFloat) -> Content

    @State private var width: CGFloat = 0

    #if os(iOS)
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        private var columnCount: Int { horizontalSizeClass == .regular ? 3 : 2 }
    #else
        private let columnCount = 3
    #endif

    private var cellSide: CGFloat {
        let spacing = Design.Spacing.gridGap * CGFloat(columnCount - 1)
        return max(0, ((width - spacing) / CGFloat(columnCount)).rounded(.down))
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Design.Spacing.gridGap), count: columnCount),
            spacing: Design.Spacing.gridGap
        ) {
            content(cellSide)
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.size.width
        } action: {
            width = $0
        }
    }
}
