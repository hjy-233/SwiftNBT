import Foundation
@testable import SwiftNBT
import Testing

@Test("round trips all scalar and container values")
func testRoundTrip() throws {
    let document = NBTDocument(
        rootName: "Level",
        root: [
            "Byte": .byte(-1),
            "Short": .short(32000),
            "Int": .int(42),
            "Long": .long(42_424_242),
            "Float": .float(1.5),
            "Double": .double(2.5),
            "String": .string("SwiftNBT"),
            "List": .list([.int(1), .int(2), .int(3)]),
            "Compound": .compound(["Enabled": .byte(1)]),
            "Bytes": .byteArray([-1, 0, 1]),
            "Ints": .intArray([1, 2, 3]),
            "Longs": .longArray([4, 5, 6]),
        ],
    )

    let encoded = try NBTEncoder().encode(document, compression: .none)
    let decoded = try NBTDecoder().decode(encoded, compression: .none)

    #expect(decoded.rootName == "Level")
    #expect(decoded["String"]?.stringValue == "SwiftNBT")
    #expect(decoded["Long"]?.int64Value == 42_424_242)
    #expect(decoded["Compound"]?.compoundValue?["Enabled"]?.boolValue == true)
}

@Test("round trips gzip compressed data")
func testGzipRoundTrip() throws {
    let document = NBTDocument(root: ["Name": .string("gzip")])
    let encoded = try NBTEncoder().encode(document, compression: .gzip)
    let decoded = try NBTDecoder().decode(encoded)

    #expect(decoded["Name"]?.stringValue == "gzip")
}

@Test("rejects invalid roots")
func testRejectsInvalidRoot() {
    #expect(throws: NBTError.invalidRootType(8)) {
        try NBTDecoder().decode(Data([8, 0, 0]), compression: .none)
    }
}
