import SwiftUI

struct DynamicView: View {
    @EnvironmentObject private var dependencies: AppDependencies

    var body: some View {
        DynamicContentRoot(
            api: dependencies.api,
            libraryStore: dependencies.libraryStore,
            sessionStore: dependencies.sessionStore
        )
        .rootNavigationTitle("动态")
        .nativeTopNavigationChrome()
    }
}

private struct DynamicContentRoot: View {
    let api: BiliAPIClient
    @ObservedObject var libraryStore: LibraryStore
    @ObservedObject var sessionStore: SessionStore
    @StateObject private var holder = DynamicViewModelHolder()
    @StateObject private var pullRefreshSettings = PullRefreshRuntimeSettingsStore()
    @State private var isComposerPresented = false

    var body: some View {
        Group {
            if let viewModel = holder.viewModel {
                VStack(spacing: 0) {
                    if sessionStore.isLoggedIn {
                        Button {
                            isComposerPresented = true
                        } label: {
                            Label("发布动态", systemImage: "square.and.pencil")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    DynamicFeedScreenContent(
                        api: api,
                        viewModel: viewModel,
                        isLoggedIn: sessionStore.isLoggedIn,
                        pullRefreshTriggerDistance: CGFloat(pullRefreshSettings.triggerDistance)
                    )
                }
                .sheet(isPresented: $isComposerPresented) {
                    DynamicComposerView(api: api) {
                        Task { await viewModel.refresh() }
                    }
                }
            } else {
                DynamicInitialFeedContent(isLoggedIn: sessionStore.isLoggedIn)
                    .task {
                        holder.configure(
                            api: api,
                            libraryStore: libraryStore,
                            sessionStore: sessionStore
                        )
                    }
            }
        }
        .task {
            pullRefreshSettings.bind(libraryStore)
        }
        .onChange(of: DynamicFeedAccountContext(
            mainCredentialVersion: sessionStore.playbackCredentialVersion,
            dynamicFeedCredentialVersion: sessionStore.dynamicFeedAccountCredentialVersion,
            multiAccountExperimentEnabled: libraryStore.multiAccountExperimentEnabled
        )) { _, _ in
            holder.reconfigure(
                api: api,
                libraryStore: libraryStore,
                sessionStore: sessionStore
            )
        }
    }
}

private struct DynamicFeedAccountContext: Equatable {
    let mainCredentialVersion: Int
    let dynamicFeedCredentialVersion: Int
    let multiAccountExperimentEnabled: Bool
}

extension View {
    @ViewBuilder
    func dynamicLoadMoreTask<ID: Equatable>(
        if condition: Bool,
        id: ID,
        action: @escaping () async -> Void
    ) -> some View {
        if condition {
            task(id: id) {
                await action()
            }
        } else {
            self
        }
    }
}
