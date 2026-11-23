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

struct LoadErrorView: View {
    let error: LoadError
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(error.title, systemImage: error.systemImage)
        } description: {
            Text(error.message)
        } actions: {
            Button(action: onRetry) {
                Text("Retry", bundle: .module)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("retry-button")
        }
        .accessibilityIdentifier("feed-error")
    }
}

struct EmptySearchView: View {
    let query: String

    var body: some View {
        ContentUnavailableView {
            Label(String(localized: "No photos for “\(query)”", bundle: .module), systemImage: "magnifyingglass")
        } description: {
            Text("Try a different search.", bundle: .module)
        }
        .accessibilityIdentifier("search-empty")
    }
}

struct RefreshErrorBanner: View {
    let error: LoadError
    let onDismiss: () -> Void

    var body: some View {
        Text(error.title)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
            .task {
                try? await Task.sleep(for: .seconds(3))
                onDismiss()
            }
            .accessibilityIdentifier("refresh-error")
    }
}

struct OfflineBanner: View {
    let reason: LoadError

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: reason.systemImage)
            text
        }
        .font(.subheadline)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.thinMaterial, in: Capsule())
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("offline-banner")
    }

    private var text: Text {
        reason == .offline
            ? Text("You're offline · Showing saved photos", bundle: .module)
            : Text("Showing saved photos", bundle: .module)
    }
}

extension LoadError {
    var title: String {
        switch self {
        case .offline: String(localized: "You're offline", bundle: .module)
        case .rateLimited: String(localized: "Taking a short break", bundle: .module)
        case .invalidKey: String(localized: "Access key not accepted", bundle: .module)
        case .generic: String(localized: "Something went wrong", bundle: .module)
        }
    }

    var message: String {
        switch self {
        case .offline:
            String(localized: "Check your connection and try again.", bundle: .module)
        case .rateLimited:
            String(
                localized: "We've reached the hourly limit for new photos. Try again in a few minutes.",
                bundle: .module
            )
        case .invalidKey:
            String(
                localized: "Check the Unsplash access key in Config/Secrets.xcconfig, then try again.",
                bundle: .module
            )
        case .generic:
            String(localized: "We couldn't load photos. Please try again.", bundle: .module)
        }
    }

    var systemImage: String {
        switch self {
        case .offline: "wifi.slash"
        case .rateLimited: "hourglass"
        case .invalidKey: "key"
        case .generic: "exclamationmark.triangle"
        }
    }
}
