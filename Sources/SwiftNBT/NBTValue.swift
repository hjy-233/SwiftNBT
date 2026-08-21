/// Values supported by Minecraft's Named Binary Tag format.
public indirect enum NBTValue: Sendable {
    case byte(Int8)
    case short(Int16)
    case int(Int32)
    case long(Int64)
    case float(Float)
    case double(Double)
    case byteArray([Int8])
    case string(String)
    case list([NBTValue])
    case compound([String: NBTValue])
    case intArray([Int32])
    case longArray([Int64])

    public var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }

    public var int64Value: Int64? {
        switch self {
        case let .byte(value): Int64(value)
        case let .short(value): Int64(value)
        case let .int(value): Int64(value)
        case let .long(value): value
        default: nil
        }
    }

    public var boolValue: Bool? {
        guard let value = int64Value else { return nil }
        return value != 0
    }

    public var compoundValue: [String: NBTValue]? {
        guard case let .compound(value) = self else { return nil }
        return value
    }
}

public typealias NBTCompound = [String: NBTValue]
