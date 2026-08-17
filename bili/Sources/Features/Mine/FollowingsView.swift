import SwiftUI

struct FollowingsView: View {
    let api: BiliAPIClient
    @State private var users: [FollowingUser] = []
    @State private var tags: [FollowingTag] = []
    @State private var selectedTagID: Int?
    @State private var showingTagManager = false
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
                ContentUnavailableView("Unable to load following", systemImage: "person.2", description: Text(errorMessage))
            } else if users.isEmpty {
                ContentUnavailableView("No followed users", systemImage: "person.2", description: Text("Followed creators will appear here."))
            } else {
                List {
                    if !tags.isEmpty {
                        Picker("Group", selection: $selectedTagID) {
                            Text("All groups").tag(Optional<Int>.none)
                            ForEach(tags) { tag in Text(tag.name).tag(Optional(tag.tagID)) }
                        }
                    }
                    ForEach(users) { user in
                    HStack(spacing: 12) {
                        AsyncImage(url: user.face.flatMap(URL.init(string:))) { phase in
                            switch phase {
                            case .success(let image): image.resizable().scaledToFill()
                            default: Image(systemName: "person.crop.circle").resizable().scaledToFit().foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 42, height: 42)
                        .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(user.name).font(.body.weight(.medium))
                            if let sign = user.sign, !sign.isEmpty { Text(sign).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                        }
                        Spacer()
                        if user.special == true { Image(systemName: "pin.fill").foregroundStyle(.secondary) }
                    }
                    .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Following")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingTagManager = true } label: { Image(systemName: "folder.badge.gearshape") }
            }
        }
        .sheet(isPresented: $showingTagManager) {
            FollowingTagManagerView(api: api) { await load() }
        }
        .onChange(of: selectedTagID) { _, _ in Task { await loadUsers() } }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            tags = (try? await api.fetchFollowingTags()) ?? []
            await loadUsers()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadUsers() async {
        do { users = try await api.fetchFollowingUsers(tagID: selectedTagID).list }
        catch { errorMessage = error.localizedDescription }
    }
}

private struct FollowingTagManagerView: View {
    let api: BiliAPIClient
    let onChanged: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var tags: [FollowingTag] = []
    @State private var newName = ""
    @State private var editingTag: FollowingTag?
    @State private var editName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Create group") {
                    HStack {
                        TextField("Group name", text: $newName)
                        Button("Add") { Task { await create() } }.disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                Section("Groups") {
                    ForEach(tags) { tag in
                        HStack {
                            Text(tag.name)
                            Spacer()
                            Text("\(tag.count ?? 0)").foregroundStyle(.secondary)
                            Button { editingTag = tag; editName = tag.name } label: { Image(systemName: "pencil") }
                            Button { Task { try? await api.deleteFollowingTag(id: tag.tagID); await reload() } } label: { Image(systemName: "trash") }.tint(.red)
                        }
                    }
                }
            }
            .navigationTitle("Following Groups")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .sheet(item: $editingTag) { tag in
                NavigationStack {
                    Form { TextField("Group name", text: $editName) }
                        .navigationTitle("Rename Group")
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editingTag = nil } }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") { Task { try? await api.renameFollowingTag(id: tag.tagID, name: editName); editingTag = nil; await reload() } }
                                    .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                }
                .presentationDetents([.height(180)])
            }
            .task { await reload() }
        }
    }

    private func reload() async { tags = (try? await api.fetchFollowingTags()) ?? []; await onChanged() }
    private func create() async {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        try? await api.createFollowingTag(name: name)
        newName = ""
        await reload()
    }
}
