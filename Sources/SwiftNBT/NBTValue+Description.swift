extension NBTValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .byte(value): "\(value)b"
        case let .short(value): "\(value)s"
        case let .int(value): "\(value)"
        case let .long(value): "\(value)L"
        case let .float(value): "\(value)f"
        case let .double(value): "\(value)d"
        case let .string(value): value
        case let .byteArray(values): "ByteArray[\(values.count)]"
        case let .intArray(values): "IntArray[\(values.count)]"
        case let .longArray(values): "LongArray[\(values.count)]"
        case let .list(values): "List[\(values.count)]"
        case let .compound(values): "Compound{\(values.count)}"
        }
    }
}
