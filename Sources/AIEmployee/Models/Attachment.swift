import Foundation

/// A file attachment delivered with a chat message (e.g. via `present_file`).
/// Mirrors the orchestrator `presented_files` payload.
struct ChatAttachment: Identifiable, Codable, Hashable {
    let path: String
    let filename: String
    let mediaType: String?
    let size: Int?
    let caption: String?

    var id: String { path }

    enum CodingKeys: String, CodingKey {
        case path
        case filename
        case mediaType = "media_type"
        case size
        case caption
    }

    var isAudio: Bool { (mediaType ?? "").hasPrefix("audio/") || filename.lowercased().hasSuffix(".mp3") || filename.lowercased().hasSuffix(".m4a") || filename.lowercased().hasSuffix(".wav") || filename.lowercased().hasSuffix(".ogg") }
    var isImage: Bool { (mediaType ?? "").hasPrefix("image/") }
    var isPDF: Bool { (mediaType ?? "") == "application/pdf" || filename.lowercased().hasSuffix(".pdf") }
    var isVideo: Bool { (mediaType ?? "").hasPrefix("video/") }

    var sizeFormatted: String? {
        guard let size, size > 0 else { return nil }
        let fmt = ByteCountFormatter()
        fmt.allowedUnits = [.useKB, .useMB, .useGB]
        fmt.countStyle = .file
        return fmt.string(fromByteCount: Int64(size))
    }

    var systemIconName: String {
        if isAudio { return "music.note" }
        if isImage { return "photo" }
        if isPDF { return "doc.richtext" }
        if isVideo { return "film" }
        return "doc"
    }
}
