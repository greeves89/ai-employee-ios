import SwiftUI
import QuickLook

/// Displays a single chat attachment as a tappable card.
/// First tap downloads (and caches) the file, then opens it via QuickLook.
struct AttachmentRow: View {
    let attachment: ChatAttachment
    let agentId: String

    @State private var localURL: URL?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var previewURL: URL?

    var body: some View {
        Button {
            Task { await tap() }
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.appAccent.opacity(0.15))
                        .frame(width: 40, height: 40)
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.appAccent))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: localURL != nil ? "checkmark.circle.fill" : attachment.systemIconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.appAccent)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(attachment.filename)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    HStack(spacing: 6) {
                        if let size = attachment.sizeFormatted {
                            Text(size)
                        }
                        if attachment.sizeFormatted != nil && localURL != nil {
                            Text("·")
                        }
                        if localURL != nil {
                            Text("offline verfügbar")
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onAppear {
            localURL = AttachmentCache.shared.cachedURL(for: attachment)
        }
        .quickLookPreview($previewURL)
        .alert("Download fehlgeschlagen", isPresented: .constant(errorMessage != nil), actions: {
            Button("OK") { errorMessage = nil }
        }, message: {
            Text(errorMessage ?? "")
        })
    }

    private func tap() async {
        if let url = localURL {
            previewURL = url
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let url = try await AttachmentCache.shared.ensureCached(attachment, agentId: agentId)
            localURL = url
            previewURL = url
        } catch let err as APIError {
            errorMessage = err.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
