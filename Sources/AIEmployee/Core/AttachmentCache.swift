import Foundation
import CryptoKit

/// Persistent on-disk cache for chat attachments.
/// Files are stored under `~/Library/Caches/AIEmployee/attachments/<sha256(path)>.<ext>`.
/// Provides synchronous local-path lookup and async download + persist via APIClient.
@MainActor
final class AttachmentCache {
    static let shared = AttachmentCache()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSizeBytes: Int = 500 * 1024 * 1024

    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        cacheDirectory = caches.appendingPathComponent("AIEmployee/attachments", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func cacheKey(for serverPath: String) -> String {
        let digest = SHA256.hash(data: Data(serverPath.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func cacheURL(for attachment: ChatAttachment) -> URL {
        let ext = (attachment.filename as NSString).pathExtension
        let key = cacheKey(for: attachment.path)
        let filename = ext.isEmpty ? key : "\(key).\(ext)"
        return cacheDirectory.appendingPathComponent(filename)
    }

    /// Returns the local file URL if the attachment is already cached, else nil.
    func cachedURL(for attachment: ChatAttachment) -> URL? {
        let url = cacheURL(for: attachment)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    /// Downloads the attachment via APIClient if not already cached, then returns the local URL.
    func ensureCached(_ attachment: ChatAttachment, agentId: String) async throws -> URL {
        if let existing = cachedURL(for: attachment) {
            return existing
        }
        let data = try await APIClient.shared.downloadFile(agentId: agentId, path: attachment.path)
        let target = cacheURL(for: attachment)
        try data.write(to: target, options: .atomic)
        Task.detached { [weak self] in await self?.evictIfNeeded() }
        return target
    }

    /// LRU-style eviction: deletes the least-recently-accessed files until total size is under the limit.
    func evictIfNeeded() async {
        let keys: [URLResourceKey] = [.contentAccessDateKey, .fileSizeKey]
        let contents = (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: keys)) ?? []
        let entries: [(URL, Date, Int)] = contents.compactMap { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            let date = values?.contentAccessDate ?? .distantPast
            let size = values?.fileSize ?? 0
            return (url, date, size)
        }
        let totalSize = entries.reduce(0) { $0 + $1.2 }
        guard totalSize > maxCacheSizeBytes else { return }
        let sorted = entries.sorted { $0.1 < $1.1 }
        var remaining = totalSize
        for (url, _, size) in sorted {
            try? fileManager.removeItem(at: url)
            remaining -= size
            if remaining <= maxCacheSizeBytes { break }
        }
    }

    func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}
