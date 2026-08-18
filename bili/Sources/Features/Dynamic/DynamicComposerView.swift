import SwiftUI
import PhotosUI
import UIKit

struct DynamicComposerView: View {
    let api: BiliAPIClient
    let onPublished: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var content = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
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
                            Text("Share something...")
                                .foregroundStyle(.secondary)
                                .padding(.top, 20)
                                .padding(.leading, 18)
                                .allowsHitTesting(false)
                        }
                    }
                Text("Text dynamic")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(imageData == nil ? "Add image" : "Image selected", systemImage: "photo")
                }
                if let imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Publish dynamic")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publish") { Task { await publish() } }
                        .disabled(isPublishing || (content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && imageData == nil))
                }
            }
            .overlay { if isPublishing { ProgressView() } }
            .task(id: selectedPhoto) {
                imageData = try? await selectedPhoto?.loadTransferable(type: Data.self)
            }
            .alert("Publish failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func publish() async {
        isPublishing = true
        defer { isPublishing = false }
        do {
            if let imageData {
                try await api.publishImageDynamic(content, imageData: imageData)
            } else {
                try await api.publishTextDynamic(content)
            }
            onPublished()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
