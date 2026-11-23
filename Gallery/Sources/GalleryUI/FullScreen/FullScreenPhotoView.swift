import GalleryCore
import SwiftUI

struct FullScreenPhotoView: View {
    let route: FullScreenRoute
    let referralAppName: String

    @State private var model: FullScreenImageModel
    @State private var container = CGSize.zero
    @State private var transform = ZoomTransform()
    @State private var pinchStart: ZoomTransform?
    @State private var panStart: ZoomTransform?
    @State private var dismissTranslation = CGSize.zero
    @State private var isChromeVisible = true
    @State private var isInfoPresented = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(route: FullScreenRoute, images: PhotoImages, referralAppName: String) {
        self.route = route
        self.referralAppName = referralAppName
        _model = State(initialValue: FullScreenImageModel(photo: route.photo, images: images, gridSize: route.gridSize))
    }

    var body: some View {
        ZStack {
            ZStack {
                Color.black.opacity(1 - ZoomTransform.dismissProgress(for: dismissTranslation))
                AmbientBackdrop(
                    preview: model.preview,
                    opacity: AmbientBackdrop.opacity(
                        isChromeVisible: isChromeVisible,
                        dismissProgress: ZoomTransform.dismissProgress(for: dismissTranslation),
                        reduceTransparency: reduceTransparency
                    )
                )
                .animation(Design.Motion.chromeToggle(reduceMotion: reduceMotion), value: isChromeVisible)
                photo
            }
            .contentShape(Rectangle())
            .gesture(tapGesture)
            .simultaneousGesture(magnifyGesture)
            .simultaneousGesture(dragGesture)
            .ignoresSafeArea()
            .onGeometryChange(for: CGSize.self) {
                $0.size
            } action: {
                container = $0
            }
            .accessibilitySortPriority(2)
            FullScreenChromeLayer(
                caption: caption(for: route.photo),
                photographer: route.photo.photographer,
                shareURL: shareURL(for: route.photo, appName: referralAppName),
                appName: referralAppName,
                isVisible: isChromeVisible,
                isInfoPresented: $isInfoPresented
            )
            .accessibilitySortPriority(3)
        }
        .accessibilityAction(.escape, close)
        .sheet(isPresented: $isInfoPresented) {
            PhotoInfoSheet(
                details: PhotoDetails(route.photo),
                photographer: route.photo.photographer,
                appName: referralAppName
            )
        }
        .task(id: fittingSize) {
            guard fittingSize.width > 0, fittingSize.height > 0 else { return }
            await model.load(fitting: fittingSize)
        }
        #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            .statusBarHidden(!isChromeVisible)
        #endif
    }

    private var fittingSize: FittingSize {
        FittingSize(width: container.width, height: container.height, scale: displayScale)
    }

    private var content: CGSize {
        ContentFit.size(of: route.photo, in: container)
    }

    private var photo: some View {
        photoImage
            .scaleEffect(transform.scale)
            .offset(
                CGSize(
                    width: transform.offset.width,
                    height: transform.offset.height + dismissTranslation.height
                ))
    }

    private var photoImage: some View {
        Color.clear
            .frame(width: content.width, height: content.height)
            .accessibilityElement()
            .accessibilityLabel(caption(for: route.photo))
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

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let start = panStart ?? transform
                panStart = start
                if start.isZoomed {
                    transform = start.panned(by: value.translation, container: container, content: content)
                } else {
                    dismissTranslation = CGSize(width: 0, height: max(0, value.translation.height))
                }
            }
            .onEnded { value in
                let wasZoomed = (panStart ?? transform).isZoomed
                panStart = nil
                guard !wasZoomed else { return }
                if ZoomTransform.shouldShowInfo(
                    translation: value.translation,
                    predictedEnd: value.predictedEndTranslation
                ) {
                    isInfoPresented = true
                    return
                }
                guard dismissTranslation != .zero else { return }
                if ZoomTransform.shouldDismiss(
                    translation: value.translation,
                    predictedEnd: value.predictedEndTranslation
                ) {
                    dismiss()
                } else {
                    withAnimation(reduceMotion ? nil : .spring) {
                        dismissTranslation = .zero
                    }
                }
            }
    }

    private func close() {
        dismiss()
    }

    private func apply(_ next: ZoomTransform) {
        transform = next
        if next.isZoomed {
            isChromeVisible = false
        }
    }
}
