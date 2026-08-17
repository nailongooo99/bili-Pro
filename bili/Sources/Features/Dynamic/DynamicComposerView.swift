import SwiftUI

struct DynamicComposerView: View {
    let api: BiliAPIClient
    let onPublished: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var isPublishing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $content)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .frame(minHeight: 180)
                    .overlay(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("分享此刻的想法…")
                                .foregroundStyle(.secondary)
                                .padding(.top, 20)
                                .padding(.leading, 18)
                                .allowsHitTesting(false)
                        }
                    }
                Text("纯文字动态")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding()
            .navigationTitle("发布动态")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发布") { Task { await publish() } }
                        .disabled(isPublishing || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .overlay { if isPublishing { ProgressView() } }
            .alert("发布失败", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("好", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func publish() async {
        isPublishing = true
        defer { isPublishing = false }
        do {
            try await api.publishTextDynamic(content)
            onPublished()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
