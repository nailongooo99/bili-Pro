import SwiftUI

struct AccountLibraryListPage: View {
    let kind: AccountLibraryKind
    @ObservedObject var viewModel: MineViewModel
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var searchText = ""

    var body: some View {
        List {
            Section {
                content
            }
        }
        .nativeTopScrollEdgeEffect()
        .hiddenInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await reload() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(!sessionStore.isLoggedIn || state.isLoading)
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: kind == .history ? .always : .automatic), prompt: "Search history")
        .onChange(of: kind) { _, _ in searchText = "" }
        .task {
            await loadIfNeeded()
        }
        .refreshable {
            await reload()
        }
    }

    @ViewBuilder
    private var content: some View {
        if !sessionStore.isLoggedIn {
            LibraryEmptyRow(title: kind.loggedOutTitle, systemImage: kind.systemImage)
        } else if items.isEmpty && state.isLoading {
            LibraryLoadingRow(title: kind.loadingTitle)
        } else if items.isEmpty, case .failed(let message) = state {
            LibraryErrorRow(title: kind.errorTitle, message: message) {
                Task { await reload() }
            }
        } else if kind == .favorites {
            favoriteFolderContent
        } else if items.isEmpty {
            LibraryEmptyRow(title: kind.emptyTitle, systemImage: kind.systemImage)
        } else {
            ForEach(items) { item in
                VideoRouteLink(item.videoItem) {
                    LibraryVideoRow(item: item, timestampTitle: kind.timestampTitle)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if kind == .watchLater {
                        Button(role: .destructive) {
                            Task { await viewModel.removeWatchLater(item) }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
                .task {
                    await loadMoreIfNeeded(current: item)
                }
            }

            if state.isLoading {
                LibraryLoadingRow(title: kind.loadingTitle)
            } else if loadMoreState.isLoading {
                LibraryLoadingRow(title: kind.loadMoreTitle)
            } else if case .failed(let message) = state {
                LibraryErrorRow(title: kind.errorTitle, message: message) {
                    Task { await reload() }
                }
            } else if case .failed(let message) = loadMoreState {
                LibraryErrorRow(title: kind.loadMoreErrorTitle, message: message) {
                    Task { await loadMore() }
                }
            } else if hasMore {
                LibraryLoadMoreTriggerRow(title: kind.loadMoreTitle) {
                    Task { await loadMore() }
                }
            }
        }
    }

    @ViewBuilder
    private var favoriteFolderContent: some View {
        if favoriteFolders.isEmpty {
            LibraryEmptyRow(title: kind.emptyTitle, systemImage: kind.systemImage)
        } else {
            ForEach(favoriteFolders) { folder in
                NavigationLink {
                    FavoriteFolderContentPage(folder: folder, viewModel: viewModel)
                } label: {
                    FavoriteFolderRow(folder: folder)
                }
            }
        }
    }

    private var items: [AccountVideoEntry] {
        let source: [AccountVideoEntry]
        switch kind {
        case .history:
            source = viewModel.accountHistory
        case .watchLater:
            source = viewModel.watchLater
        case .favorites:
            source = viewModel.accountFavorites
        }
        guard kind == .history, !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return source }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return source.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    private var state: LoadingState {
        switch kind {
        case .history:
            return viewModel.historyState
        case .watchLater:
            return viewModel.watchLaterState
        case .favorites:
            return viewModel.favoriteState
        }
    }

    private var favoriteFolders: [FavoriteFolder] {
        viewModel.favoriteFolders
    }

    private var loadMoreState: LoadingState {
        switch kind {
        case .history:
            return viewModel.historyLoadMoreState
        case .watchLater:
            return .idle
        case .favorites:
            return .idle
        }
    }

    private var hasMore: Bool {
        switch kind {
        case .history:
            return viewModel.historyHasMore
        case .watchLater:
            return false
        case .favorites:
            return false
        }
    }

    private func loadIfNeeded() async {
        guard sessionStore.isLoggedIn, items.isEmpty, !state.isLoading else { return }
        await reload()
    }

    private func reload() async {
        switch kind {
        case .history:
            await viewModel.refreshHistory()
        case .watchLater:
            await viewModel.refreshWatchLater()
        case .favorites:
            await viewModel.refreshFavorites()
        }
    }

    private func loadMoreIfNeeded(current item: AccountVideoEntry) async {
        switch kind {
        case .history:
            await viewModel.loadMoreHistoryIfNeeded(current: item)
        case .watchLater:
            break
        case .favorites:
            break
        }
    }

    private func loadMore() async {
        switch kind {
        case .history:
            await viewModel.loadMoreHistory()
        case .watchLater:
            break
        case .favorites:
            break
        }
    }
}
