/// A complete NBT document, including the optional name of its root tag.
public struct NBTDocument: Sendable {
    public let rootName: String
    public let root: NBTCompound

    public init(rootName: String = "", root: NBTCompound) {
        self.rootName = rootName
        self.root = root
    }

    public subscript(_ key: String) -> NBTValue? {
        root[key]
    }
}
