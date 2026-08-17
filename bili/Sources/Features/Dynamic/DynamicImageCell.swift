import SwiftUI

struct DynamicImageCell: View {
    let image: DynamicImageItem
    let previewItems: [ZoomyImagePreviewItem]
    let previewItemID: String?
    let previewGroup: ZoomyImagePreviewGroup?
    let displayMode: DisplayMode
    @State private var thumbnailShadowOpacityScale = 1.0
    private let normalizedURLString: String?
    private let imageAspectRatio: CGFloat

    init(
        image: DynamicImageItem,
        previewItems: [ZoomyImagePreviewItem] = [],
        previewItemID: String? = nil,
        previewGroup: ZoomyImagePreviewGroup? = nil,
        displayMode: DisplayMode
    ) {
        self.image = image
        self.previewItems = previewItems
        self.previewItemID = previewItemID
        self.previewGroup = previewGroup
        self.displayMode = displayMode
        let normalizedURLString = image.normalizedURL
        self.normalizedURLString = normalizedURLString
        self.imageAspectRatio = Self.aspectRatio(for: image, normalizedURLString: normalizedURLString)
    }

    var body: some View {
        baseImageContent
            .overlay(alignment: .bottomTrailing) {
                DynamicImageBadgeRow(
                    mediaBadgeText: image.mediaBadgeText,
                    showsLongImage: displayMode.isLongImage
                )
                .padding(8)
            }
    }

    @ViewBuilder
    private var baseImageContent: some View {
        switch displayMode {
        case .single:
            imageContent
                .aspectRatio(displayAspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipped()
                .videoCoverSurface(
                    cornerRadius: 8,
                    shadowLevel: .regular,
                    shadowOpacityScale: thumbnailShadowOpacityScale,
                    borderOpacityScale: thumbnailShadowOpacityScale,
                    appliesUnifiedBorderExperiment: false
                )
        case .longImage(let cornerRadius):
            imageContent
                .aspectRatio(9 / 16, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()
                .videoCoverSurface(
                    cornerRadius: cornerRadius,
                    shadowLevel: .regular,
                    shadowOpacityScale: thumbnailShadowOpacityScale,
                    borderOpacityScale: thumbnailShadowOpacityScale,
                    appliesUnifiedBorderExperiment: false
                )
        case .square(let cornerRadius):
            imageContent
                .aspectRatio(1, contentMode: .fill)
                .clipped()
                .videoCoverSurface(
                    cornerRadius: cornerRadius,
                    shadowLevel: .subtle,
                    shadowOpacityScale: thumbnailShadowOpacityScale,
                    borderOpacityScale: thumbnailShadowOpacityScale,
                    appliesUnifiedBorderExperiment: false
                )
        case .hero(let aspectRatio, let cornerRadius):
            imageContent
                .aspectRatio(aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipped()
                .videoCoverSurface(
                    cornerRadius: cornerRadius,
                    shadowLevel: .regular,
                    shadowOpacityScale: thumbnailShadowOpacityScale,
                    borderOpacityScale: thumbnailShadowOpacityScale,
                    appliesUnifiedBorderExperiment: false
                )
        case .fixedHeight(let height, let cornerRadius):
            imageContent
                .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
                .frame(height: height)
                .clipped()
                .videoCoverSurface(
                    cornerRadius: cornerRadius,
                    shadowLevel: .regular,
                    shadowOpacityScale: thumbnailShadowOpacityScale,
                    borderOpacityScale: thumbnailShadowOpacityScale,
                    appliesUnifiedBorderExperiment: false
                )
        }
    }

    private var imageContent: some View {
        DynamicImageCellRemoteContent(
            normalizedURLString: normalizedURLString,
            previewItems: previewItems,
            previewItemID: previewItemID,
            previewGroup: previewGroup,
            targetPixelSize: thumbnailMaxSide,
            cornerRadius: displayMode.cornerRadius,
            contentMode: thumbnailContentMode,
            contentAlignment: thumbnailContentAlignment,
            onViewerPresentationChange: updateThumbnailShadowVisibility
        )
    }

    private func updateThumbnailShadowVisibility(isViewerPresented: Bool) {
        if isViewerPresented {
            thumbnailShadowOpacityScale = 0
        } else {
            withAnimation(.easeOut(duration: 0.18)) {
                thumbnailShadowOpacityScale = 1
            }
        }
    }

    private var thumbnailContentMode: ZoomyImageContentMode {
        displayMode.thumbnailContentMode
    }

    private var thumbnailContentAlignment: ZoomyImageContentAlignment {
        displayMode.thumbnailContentAlignment
    }

    private var displayAspectRatio: CGFloat {
        displayMode.displayAspectRatio(imageAspectRatio: imageAspectRatio)
    }

    private var thumbnailMaxSide: Int {
        let usesCompactImages = PlaybackEnvironment.current.shouldPreferConservativePlayback
        return displayMode.thumbnailMaxSide(usesCompactImages: usesCompactImages)
    }

    private static func aspectRatio(for image: DynamicImageItem, normalizedURLString: String?) -> CGFloat {
        if let width = image.width, let height = image.height, width > 0, height > 0 {
            return max(CGFloat(width) / CGFloat(height), 0.1)
        }
        if let ratio = normalizedURLString?.biliImageURLAspectRatio {
            return max(CGFloat(ratio), 0.1)
        }
        return 1
    }
}
