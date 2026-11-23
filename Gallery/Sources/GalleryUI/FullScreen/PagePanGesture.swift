import SwiftUI

struct PagePan {
    let translation: CGSize
    let predictedEnd: CGSize
}

extension View {
    func pagePan(
        isZoomed: Bool,
        onChanged: @escaping (CGSize) -> Void,
        onEnded: @escaping (PagePan) -> Void
    ) -> some View {
        modifier(PagePanModifier(isZoomed: isZoomed, onChanged: onChanged, onEnded: onEnded))
    }
}

private struct PagePanModifier: ViewModifier {
    let isZoomed: Bool
    let onChanged: (CGSize) -> Void
    let onEnded: (PagePan) -> Void

    func body(content: Content) -> some View {
        #if os(iOS)
            if #available(iOS 18, *) {
                content.gesture(PagePanGesture(isZoomed: isZoomed, onChanged: onChanged, onEnded: onEnded))
            } else {
                content.simultaneousGesture(dragGesture)
            }
        #else
            content.simultaneousGesture(dragGesture)
        #endif
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { onChanged($0.translation) }
            .onEnded { onEnded(PagePan(translation: $0.translation, predictedEnd: $0.predictedEndTranslation)) }
    }
}

#if os(iOS)
    @available(iOS 18, *)
    private struct PagePanGesture: UIGestureRecognizerRepresentable {
        let isZoomed: Bool
        let onChanged: (CGSize) -> Void
        let onEnded: (PagePan) -> Void

        func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
            Coordinator()
        }

        func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
            let recognizer = UIPanGestureRecognizer()
            recognizer.delegate = context.coordinator
            return recognizer
        }

        func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
            context.coordinator.isZoomed = isZoomed
        }

        func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
            let translation = recognizer.translation(in: recognizer.view)
            let size = CGSize(width: translation.x, height: translation.y)
            switch recognizer.state {
            case .began, .changed:
                onChanged(size)
            case .ended, .cancelled:
                let velocity = recognizer.velocity(in: recognizer.view)
                let predictedEnd = CGSize(
                    width: size.width + velocity.x * Self.decelerationTime,
                    height: size.height + velocity.y * Self.decelerationTime
                )
                onEnded(PagePan(translation: size, predictedEnd: predictedEnd))
            default:
                break
            }
        }

        private static let decelerationTime: CGFloat = 0.25

        final class Coordinator: NSObject, UIGestureRecognizerDelegate {
            var isZoomed = false

            func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
                guard !isZoomed, let pan = recognizer as? UIPanGestureRecognizer else { return true }
                let velocity = pan.velocity(in: pan.view)
                return abs(velocity.y) > abs(velocity.x)
            }

            func gestureRecognizer(
                _ recognizer: UIGestureRecognizer,
                shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
            ) -> Bool {
                true
            }
        }
    }
#endif
