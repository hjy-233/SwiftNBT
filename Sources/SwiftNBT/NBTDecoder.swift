import Foundation

/// Decodes binary NBT documents into typed Swift values.
public struct NBTDecoder: Sendable {
    public init() {}

    public func decode(_ data: Data, compression: NBTCompression = .automatic) throws -> NBTDocument {
        let rawData = try NBTCompressionCodec.decode(data, compression: compression)
        guard !rawData.isEmpty else { throw NBTError.emptyData }

        return try rawData.withUnsafeBytes { buffer in
            var reader = NBTReader(buffer: buffer)
            let rootType = try reader.readByte()
            guard rootType == NBTType.compound.rawValue else {
                throw NBTError.invalidRootType(rootType)
            }

            let rootName = try reader.readString()
            let root = try reader.readCompound()
            return NBTDocument(rootName: rootName, root: root)
        }
    }
}

private enum NBTType: UInt8 {
    case end = 0
    case byte = 1
    case short = 2
    case int = 3
    case long = 4
    case float = 5
    case double = 6
    case byteArray = 7
    case string = 8
    case list = 9
    case compound = 10
    case intArray = 11
    case longArray = 12
}

private struct NBTReader {
    let buffer: UnsafeRawBufferPointer
    var offset = 0

    mutating func readByte() throws -> UInt8 {
        guard offset < buffer.count else { throw NBTError.insufficientData }
        defer { offset += 1 }
        return buffer[offset]
    }

    mutating func readInt8() throws -> Int8 {
        try Int8(bitPattern: readByte())
    }

    mutating func readInt16() throws -> Int16 {
        try Int16(bitPattern: readUInt16())
    }

    mutating func readUInt16() throws -> UInt16 {
        guard offset + 2 <= buffer.count else { throw NBTError.insufficientData }
        let value = UInt16(buffer[offset]) << 8 | UInt16(buffer[offset + 1])
        offset += 2
        return value
    }

    mutating func readInt32() throws -> Int32 {
        let value = try readUInt32()
        return Int32(bitPattern: value)
    }

    mutating func readUInt32() throws -> UInt32 {
        guard offset + 4 <= buffer.count else { throw NBTError.insufficientData }
        var value: UInt32 = 0
        for _ in 0 ..< 4 {
            value = value << 8 | UInt32(buffer[offset])
            offset += 1
        }
        return value
    }

    mutating func readInt64() throws -> Int64 {
        let value = try readUInt64()
        return Int64(bitPattern: value)
    }

    mutating func readUInt64() throws -> UInt64 {
        guard offset + 8 <= buffer.count else { throw NBTError.insufficientData }
        var value: UInt64 = 0
        for _ in 0 ..< 8 {
            value = value << 8 | UInt64(buffer[offset])
            offset += 1
        }
        return value
    }

    mutating func readFloat() throws -> Float {
        try Float(bitPattern: readUInt32())
    }

    mutating func readDouble() throws -> Double {
        try Double(bitPattern: readUInt64())
    }

    mutating func readString() throws -> String {
        let length = try Int(readUInt16())
        guard offset + length <= buffer.count else { throw NBTError.insufficientData }
        guard let value = String(bytes: buffer[offset ..< offset + length], encoding: .utf8) else {
            throw NBTError.invalidString
        }
        offset += length
        return value
    }

    mutating func readCompound() throws -> NBTCompound {
        var result = NBTCompound(minimumCapacity: 16)
        while true {
            let rawType = try readByte()
            guard let type = NBTType(rawValue: rawType) else {
                throw NBTError.invalidValue("unknown tag type: \(rawType)")
            }
            if type == .end {
                return result
            }
            let name = try readString()
            result[name] = try readValue(type: type)
        }
    }

    mutating func readValue(type: NBTType) throws -> NBTValue {
        switch type {
        case .end:
            throw NBTError.invalidValue("end tag cannot have a value")
        case .byte:
            try .byte(readInt8())
        case .short:
            try .short(readInt16())
        case .int:
            try .int(readInt32())
        case .long:
            try .long(readInt64())
        case .float:
            try .float(readFloat())
        case .double:
            try .double(readDouble())
        case .byteArray:
            try .byteArray(readByteArray())
        case .string:
            try .string(readString())
        case .list:
            try readList()
        case .compound:
            try .compound(readCompound())
        case .intArray:
            try .intArray(readIntArray())
        case .longArray:
            try .longArray(readLongArray())
        }
    }

    mutating func readList() throws -> NBTValue {
        let rawType = try readByte()
        guard let type = NBTType(rawValue: rawType) else {
            throw NBTError.invalidList
        }
        let count = try readInt32()
        guard count >= 0 else { throw NBTError.invalidList }
        if count == 0 {
            return .list([])
        }
        guard type != .end else { throw NBTError.invalidList }
        var values = [NBTValue]()
        values.reserveCapacity(Int(count))
        for _ in 0 ..< count {
            try values.append(readValue(type: type))
        }
        return .list(values)
    }

    mutating func readByteArray() throws -> [Int8] {
        let count = try readArrayCount()
        guard offset + count <= buffer.count else { throw NBTError.insufficientData }
        let values = Array(buffer[offset ..< offset + count].bindMemory(to: Int8.self))
        offset += count
        return values
    }

    mutating func readIntArray() throws -> [Int32] {
        let count = try readArrayCount()
        var values = [Int32]()
        values.reserveCapacity(count)
        for _ in 0 ..< count {
            try values.append(readInt32())
        }
        return values
    }

    mutating func readLongArray() throws -> [Int64] {
        let count = try readArrayCount()
        var values = [Int64]()
        values.reserveCapacity(count)
        for _ in 0 ..< count {
            try values.append(readInt64())
        }
        return values
    }

    mutating func readArrayCount() throws -> Int {
        let count = try readInt32()
        guard count >= 0 else { throw NBTError.invalidValue("negative array length") }
        return Int(count)
    }
}
