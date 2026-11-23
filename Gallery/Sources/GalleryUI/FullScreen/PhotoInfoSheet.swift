import GalleryCore
import SwiftUI

struct PhotoInfoSheet: View {
    let details: PhotoDetails
    let photographer: Photo.Photographer
    let appName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Design.Spacing.medium) {
                Text(verbatim: details.caption)
                    .font(.title2.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                if let description = details.description {
                    Text(verbatim: description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Divider()
                Label {
                    PhotoCreditView(photographer: photographer, appName: appName)
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "camera")
                }
                Label {
                    Text(verbatim: details.size)
                        .font(.subheadline.monospacedDigit())
                } icon: {
                    Image(systemName: "aspectratio")
                }
                .accessibilityLabel(Text("Size \(details.size)", bundle: .module))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Design.Spacing.medium)
            .padding(.top, Design.Spacing.small)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("photo-info")
    }
}
