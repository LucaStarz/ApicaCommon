pub const BuiltinMethodBytecode = enum(u32) {
    Length = 0x00_00_00_00,
    IsEmpty = 0x00_00_00_01,

    BinaryRepresentation = 0x00_00_00_02,
    OctalRepresentation = 0x00_00_00_03,
    HexadecimalRepresentation = 0x00_00_00_04,

    Name = 0x00_00_00_05,
    Details = 0x00_00_00_06,
    StackTrace = 0x00_00_00_07,
};

pub const BuiltinMethodBytecodeCount = @backingInt(BuiltinMethodBytecode.StackTrace) + 1;
