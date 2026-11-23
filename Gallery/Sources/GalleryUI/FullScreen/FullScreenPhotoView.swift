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

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale

    init(route: FullScreenRoute, images: PhotoImages, referralAppName: String) {
        self.route = route
        self.referralAppName = referralAppName
        _model = State(initialValue: FullScreenImageModel(photo: route.photo, images: images, gridSize: route.gridSize))
    }

    var body: some View {
        ZStack {
            ZStack {
                Color.black.opacity(1 - ZoomTransform.dismissProgress(for: dismissTranslation))
                photo
            }
            .contentShape(Rectangle())
            .gesture(tapGesture)
            .simultaneousGesture(magnifyGesture)
            .simultaneousGesture(dragGesture)
            chrome
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGSize.self) {
            $0.size
        } action: {
            container = $0
        }
        .accessibilityAction(.escape) { dismiss() }
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
        ZStack {
            if let preview = model.preview {
                Image(decorative: preview, scale: 1)
                    .resizable()
                    .scaledToFill()
            }
            if let image = sharperImage {
                Image(decorative: image, scale: displayScale)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
        .frame(width: content.width, height: content.height)
        .clipped()
        .animation(.easeOut(duration: 0.25), value: model.state)
        .accessibilityElement()
        .accessibilityLabel(caption(for: route.photo))
        .accessibilityValue(model.isFullImageShown ? Text(verbatim: "") : Text("Loading", bundle: .module))
        .accessibilityAddTraits(.isImage)
        .accessibilityIdentifier("full-screen-photo")
    }

    private var sharperImage: CGImage? {
        switch model.state {
        case .preview:
            nil
        case .gridImage(let image), .fullImage(let image):
            image
        }
    }

    private var chrome: some View {
        VStack {
            HStack {
                closeButton
                Spacer()
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: caption(for: route.photo))
                    .font(.headline)
                    .lineLimit(3)
                PhotoCreditView(photographer: route.photo.photographer, appName: referralAppName)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
        }
        .safeAreaPadding()
        .foregroundStyle(.white)
        .opacity(isChromeVisible ? 1 : 0)
        .allowsHitTesting(isChromeVisible)
        .accessibilityHidden(!isChromeVisible)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.black.opacity(0.4), in: .circle)
                .contentShape(.circle)
        }
        .foregroundStyle(.white)
        .accessibilityLabel(Text("Close", bundle: .module))
        .accessibilityIdentifier("full-screen-close")
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
                panStart = nil
                guard dismissTranslation != .zero else { return }
                if ZoomTransform.shouldDismiss(
                    translation: value.translation,
                    predictedEnd: value.predictedEndTranslation
                ) {
                    dismiss()
                } else {
                    withAnimation(.spring) {
                        dismissTranslation = .zero
                    }
                }
            }
    }

    private func apply(_ next: ZoomTransform) {
        transform = next
        if next.isZoomed {
            isChromeVisible = false
        }
    }
}
