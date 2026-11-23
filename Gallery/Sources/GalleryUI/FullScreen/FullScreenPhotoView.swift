import GalleryCore
import SwiftUI

struct FullScreenPhotoView: View {
    let route: FullScreenRoute
    let photos: [Photo]
    let images: PhotoImages
    let referralAppName: String
    let windowTopInset: CGFloat?
    let onPhotoAppear: (Photo) -> Void
    @Binding var currentID: String

    @State private var scrolledID: String?
    @State private var isChromeVisible = true
    @State private var isInfoPresented = false
    @State private var isZoomed = false
    @State private var dismissTranslation = CGSize.zero

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(
        route: FullScreenRoute,
        photos: [Photo],
        images: PhotoImages,
        referralAppName: String,
        currentID: Binding<String>,
        windowTopInset: CGFloat? = nil,
        onPhotoAppear: @escaping (Photo) -> Void = { _ in }
    ) {
        self.route = route
        self.photos = photos
        self.images = images
        self.referralAppName = referralAppName
        self.windowTopInset = windowTopInset
        self.onPhotoAppear = onPhotoAppear
        _currentID = currentID
        _scrolledID = State(initialValue: route.photo.id)
    }

    var body: some View {
        ZStack {
            backdrop
                .ignoresSafeArea()
            pager
                .offset(y: dismissTranslation.height)
                .ignoresSafeArea()
                .accessibilitySortPriority(2)
            FullScreenChromeLayer(
                caption: caption(for: current),
                photographer: current.photographer,
                shareURL: shareURL(for: current, appName: referralAppName),
                appName: referralAppName,
                isVisible: isChromeVisible,
                isInfoPresented: $isInfoPresented
            )
            .topInset(windowTopInset)
            .accessibilitySortPriority(3)
        }
        .accessibilityAction(.escape, close)
        .sheet(isPresented: $isInfoPresented) {
            PhotoInfoSheet(
                details: PhotoDetails(current),
                photographer: current.photographer,
                appName: referralAppName
            )
        }
        .onChange(of: scrolledID) { _, id in
            guard let id, let photo = pages.first(where: { $0.id == id }) else { return }
            currentID = id
            isZoomed = false
            onPhotoAppear(photo)
        }
        #if os(iOS)
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarBackButtonHidden(true)
            .statusBarHidden(!isChromeVisible)
        #endif
    }

    private var pages: [Photo] {
        photos.contains(where: { $0.id == route.photo.id }) ? photos : [route.photo]
    }

    private var currentIndex: Int {
        pages.firstIndex(where: { $0.id == currentID }) ?? pages.firstIndex(of: route.photo) ?? 0
    }

    private var current: Photo {
        pages[currentIndex]
    }

    private var dismissProgress: Double {
        ZoomTransform.dismissProgress(for: dismissTranslation)
    }

    private var backdrop: some View {
        ZStack {
            Color.black.opacity(1 - dismissProgress)
            AmbientBackdrop(
                preview: images.preview(current),
                opacity: AmbientBackdrop.opacity(
                    isChromeVisible: isChromeVisible,
                    dismissProgress: dismissProgress,
                    reduceTransparency: reduceTransparency
                )
            )
            .id(current.id)
            .transition(.opacity)
        }
        .animation(Design.Motion.chromeToggle(reduceMotion: reduceMotion), value: isChromeVisible)
        .animation(Design.Motion.pageCrossFade(reduceMotion: reduceMotion), value: current.id)
    }

    private var pager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, photo in
                    ZoomablePhotoPage(
                        photo: photo,
                        images: images,
                        gridSize: route.gridSize,
                        isCurrent: index == currentIndex,
                        loadsFullImage: abs(index - currentIndex) <= 1,
                        isChromeVisible: $isChromeVisible,
                        isZoomed: $isZoomed,
                        dismissTranslation: $dismissTranslation,
                        isInfoPresented: $isInfoPresented
                    )
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrolledID)
        .scrollDisabled(isZoomed)
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("full-screen-pager")
    }

    private func close() {
        dismiss()
    }
}

extension View {
    @ViewBuilder
    fileprivate func topInset(_ inset: CGFloat?) -> some View {
        if let inset {
            padding(.top, inset).ignoresSafeArea(.container, edges: .top)
        } else {
            self
        }
    }
}
