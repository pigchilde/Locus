import Foundation

public final class StateRepository {
    public let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let root = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? FileManager.default.homeDirectoryForCurrentUser
            self.fileURL = root
                .appendingPathComponent("Locus", isDirectory: true)
                .appendingPathComponent("state.json", isDirectory: false)
        }

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
    }

    public func load() throws -> PersistedState? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try decoder.decode(PersistedState.self, from: Data(contentsOf: fileURL))
    }

    public func save(_ state: PersistedState) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: [.atomic])
    }
}
