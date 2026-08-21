import Foundation

/// Compression used by an NBT document.
public enum NBTCompression: Sendable {
    case automatic
    case none
    case gzip
}

enum NBTCompressionCodec {
    static func decode(_ data: Data, compression: NBTCompression) throws -> Data {
        switch compression {
        case .none:
            data
        case .gzip:
            try run("/usr/bin/gunzip", arguments: ["-c"], data: data)
        case .automatic:
            if data.starts(with: [0x1F, 0x8B]) {
                try run("/usr/bin/gunzip", arguments: ["-c"], data: data)
            } else {
                data
            }
        }
    }

    static func encode(_ data: Data, compression: NBTCompression) throws -> Data {
        switch compression {
        case .none, .automatic:
            data
        case .gzip:
            try run("/usr/bin/gzip", arguments: ["-c"], data: data)
        }
    }

    private static func run(_ executable: String, arguments: [String], data: Data) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let input = Pipe()
        let output = Pipe()
        let error = Pipe()
        process.standardInput = input
        process.standardOutput = output
        process.standardError = error

        do {
            try process.run()
            input.fileHandleForWriting.write(data)
            input.fileHandleForWriting.closeFile()
        } catch {
            throw NBTError.compressionFailed(error.localizedDescription)
        }

        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let message = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "unknown error"
            throw NBTError.compressionFailed(message.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return outputData
    }
}
