const values = @import("../values.zig");

pub const ElementModifier = packed struct(u8) {
    CONSTANT: bool = false,
    ANY: bool = false,
    NOT_NULLABLE: bool = false,
    DEREFERENCED: bool = false,
    _reserved: u4 = 0,
};

pub const Element = struct {
    modifier: ElementModifier,
    value: values.Value,

    pub fn init(value: values.Value) Element {
        return Element{
            .modifier = .{},
            .value = value,
        };
    }
};
