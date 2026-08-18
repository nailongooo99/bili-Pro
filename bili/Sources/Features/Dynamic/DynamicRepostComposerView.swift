import SwiftUI

struct DynamicRepostComposerView: View {
    let api: BiliAPIClient
    let dynamicID: String
    let onReposted: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            TextEditor(text: $content)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding()
                .overlay(alignment: .topLeading) {
                    if content.isEmpty {
                        Text("Add a comment (optional)")
                            .foregroundStyle(.secondary)
                            .padding(.top, 30)
                            .padding(.leading, 30)
                            .allowsHitTesting(false)
                    }
                }
                .navigationTitle("Repost dynamic")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Repost") { Task { @MainActor in await submit() } }
                            .disabled(isSubmitting)
                    }
                }
                .overlay { if isSubmitting { ProgressView() } }
                .alert("Repost failed", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                    Button("OK", role: .cancel) { errorMessage = nil }
                } message: { Text(errorMessage ?? "") }
        }
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await api.repostDynamic(id: dynamicID, content: content.trimmingCharacters(in: .whitespacesAndNewlines))
            onReposted()
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
