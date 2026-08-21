import Foundation
import zlib

/// Compression used by an NBT document.
public enum NBTCompression: Sendable {
    case automatic
    case none
    case gzip
}

enum NBTCompressionCodec {
    private static let gzipWindowBits: Int32 = 15 + 16
    private static let outputBufferSize = 64 * 1024

    static func decode(_ data: Data, compression: NBTCompression) throws -> Data {
        switch compression {
        case .none:
            data
        case .gzip:
            try inflate(data)
        case .automatic:
            if data.starts(with: [0x1F, 0x8B]) {
                try inflate(data)
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
            try deflate(data)
        }
    }

    private static func inflate(_ data: Data) throws -> Data {
        guard data.count <= Int(uInt.max) else {
            throw NBTError.compressionFailed("Input is too large for zlib")
        }

        var stream = z_stream()
        let status = inflateInit2_(&stream, gzipWindowBits, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard status == Z_OK else {
            throw NBTError.compressionFailed("Unable to initialize zlib decoder: \(status)")
        }
        defer { inflateEnd(&stream) }

        return try data.withUnsafeBytes { inputBuffer in
            stream.next_in = UnsafeMutablePointer(mutating: inputBuffer.bindMemory(to: Bytef.self).baseAddress)
            stream.avail_in = uInt(data.count)
            var output = Data()

            while true {
                var buffer = [UInt8](repeating: 0, count: outputBufferSize)
                let result = buffer.withUnsafeMutableBytes { outputBuffer in
                    stream.next_out = outputBuffer.bindMemory(to: Bytef.self).baseAddress
                    stream.avail_out = uInt(outputBuffer.count)
                    return zlib.inflate(&stream, Z_NO_FLUSH)
                }
                output.append(buffer, count: outputBufferSize - Int(stream.avail_out))

                if result == Z_STREAM_END {
                    return output
                }
                guard result == Z_OK, stream.avail_in > 0 else {
                    throw NBTError.compressionFailed("Unable to decode gzip data: \(result)")
                }
            }
        }
    }

    private static func deflate(_ data: Data) throws -> Data {
        guard data.count <= Int(uInt.max) else {
            throw NBTError.compressionFailed("Input is too large for zlib")
        }

        var stream = z_stream()
        let status = deflateInit2_(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, gzipWindowBits, 8, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard status == Z_OK else {
            throw NBTError.compressionFailed("Unable to initialize zlib encoder: \(status)")
        }
        defer { deflateEnd(&stream) }

        return try data.withUnsafeBytes { inputBuffer in
            stream.next_in = UnsafeMutablePointer(mutating: inputBuffer.bindMemory(to: Bytef.self).baseAddress)
            stream.avail_in = uInt(data.count)
            var output = Data()

            while true {
                var buffer = [UInt8](repeating: 0, count: outputBufferSize)
                let result = buffer.withUnsafeMutableBytes { outputBuffer in
                    stream.next_out = outputBuffer.bindMemory(to: Bytef.self).baseAddress
                    stream.avail_out = uInt(outputBuffer.count)
                    return zlib.deflate(&stream, Z_FINISH)
                }
                output.append(buffer, count: outputBufferSize - Int(stream.avail_out))

                if result == Z_STREAM_END {
                    return output
                }
                guard result == Z_OK else {
                    throw NBTError.compressionFailed("Unable to encode gzip data: \(result)")
                }
            }
        }
    }
}
