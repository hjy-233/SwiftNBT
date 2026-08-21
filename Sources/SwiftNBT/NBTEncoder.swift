import Foundation

/// Encodes typed Swift values into binary NBT documents.
public struct NBTEncoder: Sendable {
    public init() {}

    public func encode(_ document: NBTDocument, compression: NBTCompression = .gzip) throws -> Data {
        var writer = NBTWriter()
        writer.writeByte(10)
        writer.writeString(document.rootName)
        try writer.writeCompound(document.root)
        return try NBTCompressionCodec.encode(writer.data, compression: compression)
    }
}

private struct NBTWriter {
    var data = Data()

    mutating func writeByte(_ value: UInt8) {
        data.append(value)
    }

    mutating func writeInt16(_ value: Int16) {
        writeUInt16(UInt16(bitPattern: value))
    }

    mutating func writeUInt16(_ value: UInt16) {
        writeByte(UInt8(value >> 8))
        writeByte(UInt8(value & 0xFF))
    }

    mutating func writeInt32(_ value: Int32) {
        writeUInt32(UInt32(bitPattern: value))
    }

    mutating func writeUInt32(_ value: UInt32) {
        for shift in stride(from: 24, through: 0, by: -8) {
            writeByte(UInt8((value >> UInt32(shift)) & 0xFF))
        }
    }

    mutating func writeInt64(_ value: Int64) {
        writeUInt64(UInt64(bitPattern: value))
    }

    mutating func writeUInt64(_ value: UInt64) {
        for shift in stride(from: 56, through: 0, by: -8) {
            writeByte(UInt8((value >> UInt64(shift)) & 0xFF))
        }
    }

    mutating func writeString(_ value: String) {
        let bytes = Array(value.utf8)
        writeUInt16(UInt16(bytes.count))
        data.append(contentsOf: bytes)
    }

    mutating func writeCompound(_ compound: NBTCompound) throws {
        for (name, value) in compound.sorted(by: { $0.key < $1.key }) {
            try writeValue(value, name: name)
        }
        writeByte(0)
    }

    mutating func writeValue(_ value: NBTValue, name: String) throws {
        writeByte(type(of: value))
        writeString(name)
        try writePayload(value)
    }

    mutating func writePayload(_ value: NBTValue) throws {
        switch value {
        case let .byte(value): writeByte(UInt8(bitPattern: value))
        case let .short(value): writeInt16(value)
        case let .int(value): writeInt32(value)
        case let .long(value): writeInt64(value)
        case let .float(value): writeUInt32(value.bitPattern)
        case let .double(value): writeUInt64(value.bitPattern)
        case let .byteArray(values): try writeByteArray(values)
        case let .string(value): writeString(value)
        case let .list(values): try writeList(values)
        case let .compound(value): try writeCompound(value)
        case let .intArray(values): try writeIntArray(values)
        case let .longArray(values): try writeLongArray(values)
        }
    }

    mutating func writeList(_ values: [NBTValue]) throws {
        guard let first = values.first else {
            writeByte(1)
            writeInt32(0)
            return
        }
        let elementType = type(of: first)
        guard values.allSatisfy({ type(of: $0) == elementType }) else {
            throw NBTError.invalidList
        }
        writeByte(elementType)
        writeInt32(Int32(values.count))
        for value in values {
            try writePayload(value)
        }
    }

    mutating func writeByteArray(_ values: [Int8]) throws {
        try validateArrayCount(values.count)
        writeInt32(Int32(values.count))
        values.forEach { writeByte(UInt8(bitPattern: $0)) }
    }

    mutating func writeIntArray(_ values: [Int32]) throws {
        try validateArrayCount(values.count)
        writeInt32(Int32(values.count))
        values.forEach { writeInt32($0) }
    }

    mutating func writeLongArray(_ values: [Int64]) throws {
        try validateArrayCount(values.count)
        writeInt32(Int32(values.count))
        values.forEach { writeInt64($0) }
    }

    func validateArrayCount(_ count: Int) throws {
        guard count <= Int(Int32.max) else {
            throw NBTError.invalidValue("array is too large")
        }
    }

    func type(of value: NBTValue) -> UInt8 {
        switch value {
        case .byte: 1
        case .short: 2
        case .int: 3
        case .long: 4
        case .float: 5
        case .double: 6
        case .byteArray: 7
        case .string: 8
        case .list: 9
        case .compound: 10
        case .intArray: 11
        case .longArray: 12
        }
    }
}
