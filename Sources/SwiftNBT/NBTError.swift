/// Errors raised while decoding, encoding, or compressing NBT data.
public enum NBTError: Error, Equatable, Sendable {
    case emptyData
    case invalidRootType(UInt8)
    case insufficientData
    case invalidString
    case invalidList
    case invalidValue(String)
    case unsupportedCompression
    case compressionFailed(String)
}
