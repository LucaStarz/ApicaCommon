pub const TypeBytecode = enum(u8) {
    Null = 0x00,
    Any = 0x01,
    Int = 0x02,
    UnsignedInt = 0x03,
    Float = 0x04,
    Bool = 0x05,
    Char = 0x06,
    String = 0x07,
    Error = 0x08,
    Type = 0x09,
    Reference = 0x0A,
    List = 0x0B,

    pub fn repr(self: TypeBytecode) []const u8 {
        return switch (self) {
            .Null => "null",
            .Any => "any",
            .Int => "int",
            .UnsignedInt => "uint",
            .Float => "float",
            .Bool => "bool",
            .Char => "char",
            .String => "string",
            .Error => "error",
            .Type => "type",
            .Reference => "reference",
            .List => "list",
        };
    }
};

pub const TypeBytecodeCount: u16 = @backingInt(TypeBytecode.List) + 1;
