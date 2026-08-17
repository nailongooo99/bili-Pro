import SwiftUI

struct FollowingsView: View {
    let api: BiliAPIClient
    @State private var users: [FollowingUser] = []
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
                List(users) { user in
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
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Following")
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            users = try await api.fetchFollowingUsers().list
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
