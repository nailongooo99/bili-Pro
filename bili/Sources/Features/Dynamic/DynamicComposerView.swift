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
    @State private var isPoll = false
    @State private var isReserve = false
    @State private var reserveID = ""
    @State private var reserveSource = "0"
    @State private var createReservation = false
    @State private var reservationTitle = ""
    @State private var reservationDate = Date().addingTimeInterval(3600)
    @State private var pollTitle = ""
    @State private var pollOptions = ["", ""]
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
                Toggle("Add seven-day poll", isOn: $isPoll)
                    .disabled(isReserve)
                if isPoll {
                    TextField("Poll title", text: $pollTitle)
                    ForEach(pollOptions.indices, id: \.self) { index in
                        HStack {
                            TextField("Option \(index + 1)", text: $pollOptions[index])
                            if pollOptions.count > 2 {
                                Button { pollOptions.remove(at: index) } label: { Image(systemName: "minus.circle") }
                            }
                        }
                    }
                    Button("Add option") { pollOptions.append("") }
                        .font(.caption)
                }
                Toggle("Attach existing reservation card", isOn: $isReserve)
                    .disabled(isPoll)
                if isReserve {
                    Toggle("Create a new live reservation card", isOn: $createReservation)
                    if createReservation {
                        TextField("Reservation title", text: $reservationTitle)
                        DatePicker("Start time", selection: $reservationDate, in: Date()...)
                    }
                    TextField("Reservation ID", text: $reserveID)
                        .keyboardType(.numberPad)
                        .disabled(createReservation)
                    TextField("Reservation source (optional)", text: $reserveSource)
                        .keyboardType(.numberPad)
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
                    .disabled(isPublishing || (content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && imageData == nil && !isPoll && !isReserve))
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
            if isReserve {
                let id: Int
                if createReservation {
                    id = try await api.createLiveReservation(title: reservationTitle, startTime: reservationDate)
                } else {
                    guard let existingID = Int(reserveID.trimmingCharacters(in: .whitespacesAndNewlines)), existingID > 0 else {
                        throw BiliAPIError.api(code: -1, message: "请输入有效的预约卡 ID")
                    }
                    id = existingID
                }
                try await api.publishReserveDynamic(
                    content: content,
                    reserveID: id,
                    source: Int(reserveSource) ?? 0
                )
            } else if isPoll {
                try await api.publishPollDynamic(content: content, title: pollTitle, options: pollOptions)
            } else if let imageData {
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
