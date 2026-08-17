import SwiftUI

enum AccountLibraryKind: Hashable, Identifiable {
    case history
    case watchLater
    case favorites

    var id: Self { self }

    var title: String {
        switch self {
        case .history: return "Watch history"
        case .watchLater: return "Watch later"
        case .favorites: return "Favorites"
        }
    }

    var systemImage: String {
        switch self {
        case .history: return "clock.arrow.circlepath"
        case .watchLater: return "bookmark"
        case .favorites: return "star"
        }
    }

    var timestampTitle: String {
        switch self {
        case .history: return "Watched"
        case .watchLater: return "Saved"
        case .favorites: return "Favorited"
        }
    }

    var emptyTitle: String {
        switch self {
        case .history: return "No watch history"
        case .watchLater: return "No videos saved for later"
        case .favorites: return "No favorite videos"
        }
    }

    var loggedOutTitle: String { "Log in to view (title.lowercased())" }
    var loadingTitle: String { "Loading (title.lowercased())" }
    var errorTitle: String { "Unable to load (title.lowercased())" }
    var loadMoreTitle: String { "Loading more (title.lowercased())" }
    var loadMoreErrorTitle: String { "Unable to load more (title.lowercased())" }
}

struct AccountLibraryButtonRow: View {
    @Environment(\.appThemeTintColor) private var appTintColor

    let title: String
    let systemImage: String
    let badgeText: String?

    init(title: String, systemImage: String, badgeText: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.badgeText = badgeText
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(appTintColor)
                .frame(width: 28, height: 28)
            Text(title)
                .appTypography(.settingsRow, fallback: .subheadline)
                .foregroundStyle(.primary)
            Spacer(minLength: 8)
            if let badgeText {
                Text(badgeText)
                    .appTypography(.badge, fallback: .caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(.red, in: Capsule())
            }
        }
    }
}
