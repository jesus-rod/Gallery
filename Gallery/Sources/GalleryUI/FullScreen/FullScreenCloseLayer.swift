import SwiftUI

struct FullScreenCloseLayer: View {
    let isVisible: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Color.clear
            .overlay(alignment: .topLeading) {
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.title3.weight(.semibold))
                        .frame(width: Design.Size.hitTarget, height: Design.Size.hitTarget)
                        .background(.black.opacity(Design.Opacity.controlFill), in: .circle)
                        .contentShape(.circle)
                }
                .foregroundStyle(.white)
                .accessibilityLabel(Text("Close", bundle: .module))
                .accessibilityIdentifier("full-screen-close")
            }
            .safeAreaPadding()
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
            .accessibilityElement(children: .contain)
            .accessibilityHidden(!isVisible)
    }

    private func close() {
        dismiss()
    }
}
