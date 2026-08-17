import SwiftUI

struct MineDisplaySettingsSection: View {
    @ObservedObject var libraryStore: LibraryStore
    @AppStorage(VideoCoverBadgeContrastBacking.storageKey) private var videoCoverBadgeContrastBackingOpacity = VideoCoverBadgeContrastBacking.defaultOpacity

    var body: some View {
        Section("显示") {
            Picker(selection: Binding(
                get: { libraryStore.appearanceMode },
                set: { libraryStore.setAppearanceMode($0) }
            )) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            } label: {
                Label("外观", systemImage: "sun.max")
            }
            .tint(libraryStore.appTintColor)

            Picker(selection: Binding(
                get: { libraryStore.appIconPreference },
                set: { libraryStore.setAppIconPreference($0) }
            )) {
                ForEach(AppIconPreference.allCases) { preference in
                    Text(preference.title).tag(preference)
                }
            } label: {
                Label("应用图标", systemImage: "app")
            }
            .pickerStyle(.navigationLink)

            MineThemeColorControl(libraryStore: libraryStore)

            Picker(selection: Binding(
                get: { libraryStore.remoteImageQualityPreference },
                set: { libraryStore.setRemoteImageQualityPreference($0) }
            )) {
                ForEach(RemoteImageQualityPreference.allCases) { preference in
                    Text(preference.title).tag(preference)
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Label("图片质量", systemImage: "photo")

                    Text(libraryStore.remoteImageQualityPreference.detail)
                        .appTypography(.settingsSubtitle, fallback: .caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .pickerStyle(.navigationLink)

            MineImageCacheControl()

            Toggle(isOn: Binding(
                get: { libraryStore.thumbnailLongPressPreviewExperimentEnabled },
                set: { libraryStore.setThumbnailLongPressPreviewExperimentEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("缩略图按住预览实验", systemImage: "hand.tap")

                    Text("打开后，按住动态或消息里的缩略图会弹出系统图片预览；普通点击仍会打开完整大图。")
                        .appTypography(.settingsSubtitle, fallback: .caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Toggle(isOn: Binding(
                get: { libraryStore.showsVideoCoverDurationBadges },
                set: { libraryStore.setShowsVideoCoverDurationBadges($0) }
            )) {
                Label("显示视频封面时长", systemImage: "timer")
            }

            Toggle(isOn: Binding(
                get: { libraryStore.unifiedVideoCoverBorderExperimentEnabled },
                set: { libraryStore.setUnifiedVideoCoverBorderExperimentEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("统一视频封面描边实验", systemImage: "rectangle.dashed")

                    Text("开着后视频封面用 iOS 自适应分隔线做一层更清楚的细描边，保留轻阴影，不给整张图盖玻璃。")
                        .appTypography(.settingsSubtitle, fallback: .caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Toggle(isOn: Binding(
                get: { libraryStore.fastScrollImageLoadSuppressionExperimentEnabled },
                set: { libraryStore.setFastScrollImageLoadSuppressionExperimentEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("快速滚动图片负载抑制实验", systemImage: "photo.stack")

                    Text("开着时猛刷列表会先顾屏幕里的封面，后台预取等停下来再做，滑动更稳；关掉后预取会边滑边跑。")
                        .appTypography(.settingsSubtitle, fallback: .caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Toggle(isOn: Binding(
                get: { libraryStore.remoteImageCDNFailoverExperimentEnabled },
                set: { libraryStore.setRemoteImageCDNFailoverExperimentEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("图片 CDN 自动切换实验", systemImage: "arrow.triangle.branch")

                    Text("开着时某个图片节点临时抽风会短暂换别的节点拿图，封面更不容易卡住；关掉后只用原节点。")
                        .appTypography(.settingsSubtitle, fallback: .caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Toggle(isOn: Binding(
                get: { libraryStore.remoteImageDiagnosticsEnabled },
                set: { libraryStore.setRemoteImageDiagnosticsEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("记录图片加载诊断", systemImage: "chart.bar.xaxis")

                    Text("开着会记缓存、滚动和 CDN 的汇总数字，方便复制给我分析；不记图片、链接、账号或 Cookie。关掉后不再记数，图片照常加载。")
                        .appTypography(.settingsSubtitle, fallback: .caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            NavigationLink {
                RemoteImageDiagnosticsView(libraryStore: libraryStore)
            } label: {
                Label("图片加载诊断", systemImage: "chart.bar.xaxis")
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("封面角标暗色底", systemImage: "circle.lefthalf.filled")
                    Spacer(minLength: 8)
                    Text(videoCoverBadgeContrastBackingOpacityTitle)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(
                        get: {
                            VideoCoverBadgeContrastBacking.normalized(videoCoverBadgeContrastBackingOpacity)
                        },
                        set: { value in
                            videoCoverBadgeContrastBackingOpacity = VideoCoverBadgeContrastBacking.normalized(value)
                        }
                    ),
                    in: VideoCoverBadgeContrastBacking.opacityRange,
                    step: 0.05
                )
            }
            .disabled(!libraryStore.showsVideoCoverDurationBadges)

            Toggle(isOn: Binding(
                get: { libraryStore.minimizesTabBarOnScroll },
                set: { libraryStore.setMinimizesTabBarOnScroll($0) }
            )) {
                Label("滑动时缩小底部 Tab", systemImage: "arrow.down.right.and.arrow.up.left")
            }

            Toggle(isOn: Binding(
                get: { libraryStore.homeNavigationModeSwitcherExperimentEnabled },
                set: { libraryStore.setHomeNavigationModeSwitcherExperimentEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("首页推荐/热门胶囊实验", systemImage: "rectangle.split.2x1")

                    Text("开着后推荐和热门系统切换控件会显示在首页顶部正中间，消息按钮保持在右侧；下滑时会一起收起，来回切换不会自动刷新推荐。关掉后恢复原来的更多按钮。")
                        .appTypography(.settingsSubtitle, fallback: .caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Picker(selection: Binding(
                get: { libraryStore.scrollEdgeEffectPreference },
                set: { libraryStore.setScrollEdgeEffectPreference($0) }
            )) {
                ForEach(AppScrollEdgeEffectPreference.allCases) { preference in
                    Text(preference.title).tag(preference)
                }
            } label: {
                Label("滚动边缘效果", systemImage: "rectangle.dashed")
            }
            .pickerStyle(.navigationLink)

            Toggle(isOn: Binding(
                get: { libraryStore.force120HzScrollingEnabled },
                set: { libraryStore.setForce120HzScrollingEnabled($0) }
            )) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("强制滑动 120Hz 刷新率", systemImage: "speedometer")

                    Text("开启后滑动会强制使用 120Hz，可能会引起耗电增加，请谨慎开启。")
                        .appTypography(.settingsSubtitle, fallback: .caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var videoCoverBadgeContrastBackingOpacityTitle: String {
        "\(Int((VideoCoverBadgeContrastBacking.normalized(videoCoverBadgeContrastBackingOpacity) * 100).rounded()))%"
    }
}

private struct MineThemeColorControl: View {
    @ObservedObject var libraryStore: LibraryStore
    @State private var selectionMode: ThemeColorSelectionMode = .tone
    @State private var tintHexDraft = ""

    private let swatchHexes = AppThemeTintColor.toneHexes
    private let swatchColumns = Array(repeating: GridItem(.fixed(32), spacing: 12), count: 6)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("主色调", systemImage: "paintpalette")

            Picker("选择方式", selection: $selectionMode) {
                ForEach(ThemeColorSelectionMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            selectedModeContent

            currentSelectionFooter

            Text("影响 App 选中状态、系统控件高亮和首页点击刷新颜色。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            tintHexDraft = libraryStore.appTintColorHex
            selectionMode = mode(for: libraryStore.appTintColorHex)
        }
        .onChange(of: libraryStore.appTintColorHex) { _, hex in
            tintHexDraft = hex
        }
        .tint(libraryStore.appTintColor)
    }

    @ViewBuilder
    private var selectedModeContent: some View {
        switch selectionMode {
        case .tone:
            LazyVGrid(columns: swatchColumns, alignment: .leading, spacing: 12) {
                ForEach(swatchHexes, id: \.self) { hex in
                    Button {
                        libraryStore.setAppTintColorHex(hex)
                        tintHexDraft = libraryStore.appTintColorHex
                    } label: {
                        colorSwatch(hex)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("选择颜色 \(hex)")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .palette:
            VStack(alignment: .leading, spacing: 10) {
                ColorPicker(
                    selection: Binding(
                        get: { libraryStore.appTintColor },
                        set: { color in
                            libraryStore.setAppTintColor(color)
                            tintHexDraft = libraryStore.appTintColorHex
                        }
                    ),
                    supportsOpacity: false
                ) {
                    Label("直接从色板选", systemImage: "eyedropper")
                }

                HStack(spacing: 10) {
                    TextField(AppThemeTintColor.defaultHex, text: $tintHexDraft)
                        .font(.body.monospaced())
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .onSubmit(commitDraftHex)

                    Button {
                        commitDraftHex()
                    } label: {
                        Label("应用", systemImage: "checkmark.circle")
                    }
                    .disabled(normalizedDraftHex == nil)
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    private var currentSelectionFooter: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(libraryStore.appTintColor)
                .frame(width: 18, height: 18)
                .overlay {
                    Circle()
                        .stroke(Color(.separator).opacity(0.30), lineWidth: 0.8)
                }

            Text(libraryStore.appTintColorHex)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Button("恢复默认") {
                libraryStore.resetAppTintColor()
                tintHexDraft = libraryStore.appTintColorHex
                selectionMode = .tone
            }
            .buttonStyle(.borderless)
        }
    }

    private var normalizedDraftHex: String? {
        AppThemeTintColor.normalizedHex(tintHexDraft)
    }

    private func commitDraftHex() {
        guard let normalizedDraftHex else { return }
        libraryStore.setAppTintColorHex(normalizedDraftHex)
        tintHexDraft = libraryStore.appTintColorHex
    }

    private func mode(for hex: String) -> ThemeColorSelectionMode {
        swatchHexes.contains(hex) ? .tone : .palette
    }

    private func colorSwatch(_ hex: String) -> some View {
        let color = AppThemeTintColor.color(for: hex)
        let isSelected = libraryStore.appTintColorHex == hex
        return Circle()
            .fill(color)
            .frame(width: 24, height: 24)
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .overlay {
                Circle()
                    .stroke(Color(.separator).opacity(0.30), lineWidth: 0.8)
            }
    }
}

private struct MineImageCacheControl: View {
    @State private var statistics: RemoteImageCacheStatistics?
    @State private var isWorking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label("图片缓存", systemImage: "photo.on.rectangle")

                Spacer(minLength: 8)

                if isWorking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(summaryTitle)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Text(summaryDetail)
                .appTypography(.settingsSubtitle, fallback: .caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(role: .destructive) {
                Task {
                    await clearImageCache()
                }
            } label: {
                Label("清理图片缓存", systemImage: "trash")
            }
            .buttonStyle(.borderless)
            .disabled(isWorking)
        }
        .task {
            await reload()
        }
    }

    private var summaryTitle: String {
        guard let statistics else { return "读取中" }
        return ResourceCacheByteFormatter.bytes(statistics.diskUsage)
    }

    private var summaryDetail: String {
        guard let statistics else {
            return "正在读取内存和磁盘图片缓存。"
        }
        return "\(statistics.memoryEntryCount) 张 · 磁盘 \(ResourceCacheByteFormatter.bytes(statistics.diskUsage)) / \(ResourceCacheByteFormatter.bytes(statistics.diskCapacity))"
    }

    @MainActor
    private func reload() async {
        statistics = await RemoteImageCache.shared.statistics()
    }

    @MainActor
    private func clearImageCache() async {
        isWorking = true
        await ResourceCacheCenter.clearImages(includeDisk: true)
        await reload()
        isWorking = false
    }
}

private enum ThemeColorSelectionMode: String, CaseIterable, Identifiable {
    case tone
    case palette

    var id: Self { self }

    var title: String {
        switch self {
        case .tone:
            "色调"
        case .palette:
            "色板"
        }
    }
}
