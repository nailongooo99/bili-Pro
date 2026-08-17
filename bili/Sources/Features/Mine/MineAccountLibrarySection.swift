import SwiftUI

struct MineAccountLibrarySection: View {
    @ObservedObject var viewModel: MineViewModel
    @ObservedObject var accountMessageViewModel: AccountMessageCenterViewModel
    let isLoggedIn: Bool
    let onOpenRoute: (MineOverlayRoute) -> Void

    var body: some View {
        Section {
            if isLoggedIn {
                MineOverlayNavigationButton {
                    onOpenRoute(.accountMessages)
                } label: {
                    AccountLibraryButtonRow(
                        title: "账号消息",
                        systemImage: "bell.badge",
                        badgeText: accountMessageViewModel.totalUnreadBadgeText
                    )
                }
            }

            MineOverlayNavigationButton {
                onOpenRoute(.history)
            } label: {
                AccountLibraryButtonRow(
                    title: "观看记录",
                    systemImage: "clock.arrow.circlepath"
                )
            }

            MineOverlayNavigationButton {
                onOpenRoute(.watchLater)
            } label: {
                AccountLibraryButtonRow(
                    title: "Watch later",
                    systemImage: "bookmark"
                )
            }

            MineOverlayNavigationButton {
                onOpenRoute(.favorites)
            } label: {
                AccountLibraryButtonRow(
                    title: "账号收藏",
                    systemImage: "star"
                )
            }

            MineOverlayNavigationButton {
                onOpenRoute(.offlineDownloads)
            } label: {
                AccountLibraryButtonRow(
                    title: "离线下载",
                    systemImage: "arrow.down.circle"
                )
            }
        } header: {
            Text("账号内容")
        }
    }
}
