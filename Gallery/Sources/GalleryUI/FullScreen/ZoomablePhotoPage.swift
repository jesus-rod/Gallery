import GalleryCore
import SwiftUI

struct ZoomablePhotoPage: View {
    let photo: Photo
    let isCurrent: Bool
    let loadsFullImage: Bool
    @Binding var isChromeVisible: Bool
    @Binding var isZoomed: Bool
    let dismissDrag: DismissDrag
    @Binding var isInfoPresented: Bool

    @State private var model: FullScreenImageModel
    @State private var container = CGSize.zero
    @State private var transform = ZoomTransform()
    @State private var pinchStart: ZoomTransform?
    @State private var panStart: ZoomTransform?
    @State private var dragAxis: Axis?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        photo: Photo,
        images: PhotoImages,
        gridSize: ImageSize,
        isCurrent: Bool,
        loadsFullImage: Bool,
        isChromeVisible: Binding<Bool>,
        isZoomed: Binding<Bool>,
        dismissDrag: DismissDrag,
        isInfoPresented: Binding<Bool>
    ) {
        self.photo = photo
        self.isCurrent = isCurrent
        self.loadsFullImage = loadsFullImage
        _isChromeVisible = isChromeVisible
        _isZoomed = isZoomed
        self.dismissDrag = dismissDrag
        _isInfoPresented = isInfoPresented
        _model = State(initialValue: FullScreenImageModel(photo: photo, images: images, gridSize: gridSize))
    }

    var body: some View {
        Color.clear
            .overlay { zoomedPhoto }
            .contentShape(Rectangle())
            .gesture(tapGesture)
            .simultaneousGesture(magnifyGesture)
            .pagePan(isZoomed: transform.isZoomed, onChanged: dragChanged, onEnded: dragEnded)
            .visualEffect { content, proxy in
                content.offset(
                    x: Parallax.offset(
                        pageMinX: proxy.frame(in: .scrollView).minX,
                        pageWidth: proxy.size.width,
                        factor: Design.Motion.parallaxFactor
                    ))
            }
            .clipped()
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: {
                container = $0
            }
            .task(id: FullImageRequest(fitting: fittingSize, isWanted: loadsFullImage)) {
                guard loadsFullImage, fittingSize.width > 0, fittingSize.height > 0 else { return }
                await model.load(fitting: fittingSize)
            }
            .onDisappear(perform: model.release)
            .onChange(of: isCurrent) { _, isCurrent in
                if !isCurrent { transform = ZoomTransform() }
            }
            .accessibilityHidden(!isCurrent)
    }

    private struct FullImageRequest: Equatable {
        let fitting: FittingSize
        let isWanted: Bool
    }

    private var fittingSize: FittingSize {
        FittingSize(width: container.width, height: container.height, scale: displayScale)
    }

    private var content: CGSize {
        ContentFit.size(of: photo, in: container)
    }

    private var zoomedPhoto: some View {
        photoImage
            .scaleEffect(transform.scale)
            .offset(transform.offset)
    }

    private var photoImage: some View {
        Color.clear
            .frame(width: content.width, height: content.height)
            .accessibilityElement()
            .accessibilityLabel(caption(for: photo))
            .accessibilityValue(model.isFullImageShown ? Text(verbatim: "") : Text("Loading", bundle: .module))
            .accessibilityAddTraits(.isImage)
            .accessibilityIdentifier("full-screen-photo")
            .overlay {
                images
                    .accessibilityHidden(true)
            }
            .clipped()
    }

    private var images: some View {
        ZStack {
            if let preview = model.preview {
                Image(decorative: preview, scale: 1)
                    .filling()
            }
            if let image = sharperImage {
                Image(decorative: image, scale: displayScale)
                    .filling()
                    .transition(.opacity)
            }
        }
        .animation(Design.Motion.imageFade(reduceMotion: reduceMotion), value: model.state)
    }

    private var sharperImage: CGImage? {
        switch model.state {
        case .preview:
            nil
        case .gridImage(let image), .fullImage(let image):
            image
        }
    }

    private var tapGesture: some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                apply(transform.toggled(at: value.location, container: container, content: content))
            }
            .exclusively(
                before: SpatialTapGesture()
                    .onEnded { _ in isChromeVisible.toggle() }
            )
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let start = pinchStart ?? transform
                pinchStart = start
                apply(
                    start.magnified(
                        by: value.magnification,
                        anchor: value.startLocation,
                        container: container,
                        content: content
                    ))
            }
            .onEnded { _ in
                pinchStart = nil
            }
    }

    private func dragChanged(_ translation: CGSize) {
        let start = panStart ?? transform
        panStart = start
        if start.isZoomed {
            transform = start.panned(by: translation, container: container, content: content)
            return
        }
        let axis = dragAxis ?? Self.axis(of: translation)
        dragAxis = axis
        if axis == .vertical {
            dismissDrag.translation = CGSize(width: 0, height: max(0, translation.height))
        }
    }

    private func dragEnded(_ pan: PagePan) {
        let wasZoomed = (panStart ?? transform).isZoomed
        let axis = dragAxis
        panStart = nil
        dragAxis = nil
        guard !wasZoomed, axis == .vertical else { return }
        if ZoomTransform.shouldShowInfo(translation: pan.translation, predictedEnd: pan.predictedEnd) {
            isInfoPresented = true
            return
        }
        guard dismissDrag.translation != .zero else { return }
        if ZoomTransform.shouldDismiss(translation: pan.translation, predictedEnd: pan.predictedEnd) {
            dismiss()
        } else {
            withAnimation(reduceMotion ? nil : .spring) {
                dismissDrag.translation = .zero
            }
        }
    }

    private static func axis(of translation: CGSize) -> Axis {
        abs(translation.height) > abs(translation.width) ? .vertical : .horizontal
    }

    private func apply(_ next: ZoomTransform) {
        transform = next
        isZoomed = next.isZoomed
        if next.isZoomed {
            isChromeVisible = false
        }
    }
}
