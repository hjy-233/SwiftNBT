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

@Test("describes NBT values")
func testValueDescriptions() {
    #expect(NBTValue.byte(-1).description == "-1b")
    #expect(NBTValue.short(32000).description == "32000s")
    #expect(NBTValue.int(42).description == "42")
    #expect(NBTValue.long(42).description == "42L")
    #expect(NBTValue.float(1.5).description == "1.5f")
    #expect(NBTValue.double(2.5).description == "2.5d")
    #expect(NBTValue.string("SwiftNBT").description == "SwiftNBT")
    #expect(NBTValue.byteArray([-1, 0, 1]).description == "ByteArray[3]")
    #expect(NBTValue.intArray([1, 2, 3]).description == "IntArray[3]")
    #expect(NBTValue.longArray([4, 5, 6]).description == "LongArray[3]")
    #expect(NBTValue.list([.int(1), .int(2)]).description == "List[2]")
    #expect(NBTValue.compound(["Enabled": .byte(1)]).description == "Compound{1}")
}

@Test("exposes typed accessors for each tag type")
func testTypedAccessors() {
    #expect(NBTValue.byte(-1).byteValue == -1)
    #expect(NBTValue.byte(-1).intValue == nil)
    #expect(NBTValue.short(32000).shortValue == 32000)
    #expect(NBTValue.int(42).intValue == 42)
    #expect(NBTValue.long(9).longValue == 9)
    #expect(NBTValue.float(1.5).floatValue == 1.5)
    #expect(NBTValue.double(2.5).doubleValue == 2.5)
    #expect(NBTValue.string("a").stringValue == "a")
    #expect(NBTValue.byteArray([1, 2]).byteArrayValue == [1, 2])
    #expect(NBTValue.intArray([1, 2]).intArrayValue == [1, 2])
    #expect(NBTValue.longArray([1, 2]).longArrayValue == [1, 2])
    #expect(NBTValue.list([.int(1)]).listValue == [.int(1)])
    #expect(NBTValue.compound(["k": .int(1)]).compoundValue?["k"] == .int(1))
}

@Test("unifies numeric and boolean access across integer widths")
func testUnifiedNumericAccessors() {
    #expect(NBTValue.int(42).int64Value == 42)
    #expect(NBTValue.byte(1).int64Value == 1)
    #expect(NBTValue.short(2).int64Value == 2)
    #expect(NBTValue.long(3).int64Value == 3)
    #expect(NBTValue.string("x").int64Value == nil)
    #expect(NBTValue.float(2.5).int64Value == nil)

    #expect(NBTValue.byte(1).boolValue == true)
    #expect(NBTValue.byte(0).boolValue == false)
    #expect(NBTValue.long(-1).boolValue == true)
    #expect(NBTValue.string("x").boolValue == nil)
}

@Test("values are hashable and equatable")
func testHashable() {
    let values: Set<NBTValue> = [
        .int(1), .int(1),
        .string("a"),
        .compound(["k": .int(1)]),
        .compound(["k": .int(1)]),
        .list([.byte(1)]),
    ]
    #expect(values.count == 4)
}
