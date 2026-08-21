/// Values supported by Minecraft's Named Binary Tag format.
public indirect enum NBTValue: Hashable, Sendable {
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

    // MARK: - Typed accessors

    public var byteValue: Int8? {
        guard case let .byte(value) = self else { return nil }
        return value
    }

    public var shortValue: Int16? {
        guard case let .short(value) = self else { return nil }
        return value
    }

    public var intValue: Int32? {
        guard case let .int(value) = self else { return nil }
        return value
    }

    public var longValue: Int64? {
        guard case let .long(value) = self else { return nil }
        return value
    }

    public var floatValue: Float? {
        guard case let .float(value) = self else { return nil }
        return value
    }

    public var doubleValue: Double? {
        guard case let .double(value) = self else { return nil }
        return value
    }

    public var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }

    public var byteArrayValue: [Int8]? {
        guard case let .byteArray(value) = self else { return nil }
        return value
    }

    public var intArrayValue: [Int32]? {
        guard case let .intArray(value) = self else { return nil }
        return value
    }

    public var longArrayValue: [Int64]? {
        guard case let .longArray(value) = self else { return nil }
        return value
    }

    public var listValue: [NBTValue]? {
        guard case let .list(value) = self else { return nil }
        return value
    }

    public var compoundValue: [String: NBTValue]? {
        guard case let .compound(value) = self else { return nil }
        return value
    }

    // MARK: - Unified numeric access

    /// The value coerced to `Int64` for any integer tag type.
    public var int64Value: Int64? {
        switch self {
        case let .byte(value): Int64(value)
        case let .short(value): Int64(value)
        case let .int(value): Int64(value)
        case let .long(value): value
        default: nil
        }
    }

    /// The value as a boolean, where any non-zero integer is `true`.
    public var boolValue: Bool? {
        guard let value = int64Value else { return nil }
        return value != 0
    }
}

public typealias NBTCompound = [String: NBTValue]
