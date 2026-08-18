import SwiftUI

struct DynamicFeedActionBar: View {
    let display: DynamicFeedCardDisplayModel
    let initialIsLiked: Bool
    let initialLikeCount: Int
    let onShowComments: () -> Void
    let api: BiliAPIClient
    let dynamicID: String
    @State private var isLiked: Bool
    @State private var likeCount: Int
    @State private var actionMessage: String?
    @State private var actionMessageTask: Task<Void, Never>?
    @State private var showingRepostComposer = false

    init(
        display: DynamicFeedCardDisplayModel,
        initialIsLiked: Bool,
        initialLikeCount: Int,
        api: BiliAPIClient,
        dynamicID: String,
        onShowComments: @escaping () -> Void
    ) {
        self.display = display
        self.initialIsLiked = initialIsLiked
        self.initialLikeCount = initialLikeCount
        self.api = api
        self.dynamicID = dynamicID
        self.onShowComments = onShowComments
        _isLiked = State(initialValue: initialIsLiked)
        _likeCount = State(initialValue: initialLikeCount)
    }

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                repostActionPill
                    .frame(maxWidth: .infinity)

                DynamicActionPill(
                    title: display.commentTitle,
                    systemImage: "bubble.left",
                    isSelected: false
                ) {
                    playActionFeedback()
                    onShowComments()
                }
                .frame(maxWidth: .infinity)

                DynamicActionPill(
                    title: DynamicFeedCardDisplayModel.statTitle(count: likeCount, fallback: "点赞"),
                    systemImage: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup",
                    isSelected: isLiked
                ) {
                    Task { @MainActor in await toggleLike() }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 3)
        .overlay(alignment: .bottomTrailing) {
            if let actionMessage {
                DynamicActionFeedbackToast(message: actionMessage)
                    .padding(.trailing, 12)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .bottomTrailing)))
                    .allowsHitTesting(false)
            }
        }
        .onDisappear {
            actionMessageTask?.cancel()
            actionMessageTask = nil
        }
        .sheet(isPresented: $showingRepostComposer) {
            DynamicRepostComposerView(api: api, dynamicID: dynamicID) {
                showActionMessage("Reposted")
            }
        }
    }

    private var repostActionPill: some View {
        DynamicActionPill(title: display.repostTitle, systemImage: "arrowshape.turn.up.right", isSelected: false) {
            playActionFeedback()
            showingRepostComposer = true
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var shareActionPill: some View {
        if let url = display.shareURL {
            ShareLink(
                item: url,
                subject: Text(display.shareTitle),
                message: Text(display.shareMessage)
            ) {
                DynamicActionPillLabel(
                    title: display.repostTitle,
                    systemImage: "arrowshape.turn.up.right"
                )
            }
            .biliGlassButtonStyle()
            .controlSize(.small)
            .tint(.secondary)
            .frame(maxWidth: .infinity)
            .simultaneousGesture(TapGesture().onEnded { playActionFeedback() })
            .accessibilityLabel("分享动态")
        } else {
            DynamicActionPill(
                title: display.repostTitle,
                systemImage: "arrowshape.turn.up.right",
                isSelected: false
            ) {
                showActionMessage("暂无可分享链接")
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func toggleLike() async {
        playActionFeedback()
        let nextIsLiked = !isLiked
        withAnimation(.snappy(duration: 0.2)) {
            isLiked = nextIsLiked
            likeCount = max(0, likeCount + (nextIsLiked ? 1 : -1))
        }
        do {
            try await api.setDynamicLike(id: dynamicID, liked: nextIsLiked)
            showActionMessage(nextIsLiked ? "Liked" : "Unliked", playsFeedback: false)
        } catch {
            withAnimation(.snappy(duration: 0.2)) {
                isLiked = !nextIsLiked
                likeCount = max(0, likeCount + (nextIsLiked ? -1 : 1))
            }
            showActionMessage(error.localizedDescription, playsFeedback: false)
        }
        showActionMessage(nextIsLiked ? "已点赞" : "已取消点赞", playsFeedback: false)
    }

    private func playActionFeedback() {
        Haptics.light()
    }

    private func showActionMessage(_ message: String, playsFeedback: Bool = true) {
        if playsFeedback {
            playActionFeedback()
        }
        actionMessageTask?.cancel()
        withAnimation(.snappy(duration: 0.18)) {
            actionMessage = message
        }
        actionMessageTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.snappy(duration: 0.18)) {
                actionMessage = nil
            }
        }
    }
}
