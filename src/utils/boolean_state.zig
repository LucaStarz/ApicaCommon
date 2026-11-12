const Value = @import("../values.zig").Value;

pub fn booleanState(value: *const Value) bool {
    return switch (value.*) {
        .Null => false,
        .Integer => |v| (v orelse 0) != 0,
        .UnsignedInteger => |v| (v orelse 0) != 0,
        .Float => |v| (v orelse 0.0) != 0.0,
        .Boolean => |v| (v orelse false),
        .Character => |v| (v orelse 0) != 0,
        .String => |v| v != null and v.?.len > 0,
        .Error => |v| v.name != null,
        .Type => true,
        .Reference => |v| v.index != null,
        .List => |v| v.items != null,
    };
}
