import SwiftUI

extension View {
    @ViewBuilder
    func zoomTransitionSource(id: String, in namespace: Namespace.ID) -> some View {
        #if os(iOS)
            if #available(iOS 18, *) {
                matchedTransitionSource(id: id, in: namespace)
            } else {
                self
            }
        #else
            self
        #endif
    }

    @ViewBuilder
    func zoomTransition(sourceID: String, in namespace: Namespace.ID) -> some View {
        #if os(iOS)
            if #available(iOS 18, *) {
                navigationTransition(.zoom(sourceID: sourceID, in: namespace))
            } else {
                self
            }
        #else
            self
        #endif
    }
}
