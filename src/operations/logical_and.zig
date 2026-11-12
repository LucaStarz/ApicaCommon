const results = @import("../results.zig");
const values = @import("../values.zig");
const booleanState = @import("../utils.zig").booleanState;

pub fn logicalAnd(left: *const results.Element, right: *const results.Element) results.Element {
    return switch (left.value) {
        .Null => results.Element.init(values.Value{ .Boolean = false }),
        .Integer => |value| logicalAndInteger(value, &right.value),
        .UnsignedInteger => |value| logicalAndUnsignedInteger(value, &right.value),
        .Float => |value| logicalAndFloat(value, &right.value),
        .Boolean => |value| logicalAndBoolean(value, &right.value),
        .Character => |value| logicalAndCharacter(value, &right.value),
        .String => |value| logicalAndString(value, &right.value),
        .Error => |value| logicalAndError(value, &right.value),
        .Type => results.Element.init(values.Value{ .Boolean = booleanState(&right.value) }),
        .Reference => |value| logicalAndReference(value, &right.value),
        .List => |value| logicalAndList(value, &right.value),
    };
}

fn logicalAndInteger(left: ?i64, right: *const values.Value) results.Element {
    if ((left orelse 0) == 0) {
        return results.Element.init(values.Value{ .Boolean = false });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalAndUnsignedInteger(left: ?u64, right: *const values.Value) results.Element {
    if ((left orelse 0) == 0) {
        return results.Element.init(values.Value{ .Boolean = false });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalAndFloat(left: ?f64, right: *const values.Value) results.Element {
    if ((left orelse 0.0) == 0.0) {
        return results.Element.init(values.Value{ .Boolean = false });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalAndBoolean(left: ?bool, right: *const values.Value) results.Element {
    if (!(left orelse false)) {
        return results.Element.init(values.Value{ .Boolean = false });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalAndCharacter(left: ?u32, right: *const values.Value) results.Element {
    if ((left orelse 0) == 0) {
        return results.Element.init(values.Value{ .Boolean = false });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalAndString(left: ?[]const u8, right: *const values.Value) results.Element {
    if (left == null or left.?.len == 0) {
        return results.Element.init(values.Value{ .Boolean = false });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalAndError(left: *const values.ErrorValue, right: *const values.Value) results.Element {
    if (left.name == null) {
        return results.Element.init(values.Value{ .Boolean = false });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalAndReference(left: *const values.ReferenceValue, right: *const values.Value) results.Element {
    if (left.index == null) {
        return results.Element.init(values.Value{ .Boolean = false });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalAndList(left: *const values.ListValue, right: *const values.Value) results.Element {
    if (left.items == null or left.items.?.items.len == 0) {
        return results.Element.init(values.Value{ .Boolean = false });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "logicalAnd Null left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&left, allocator);

    var right_true = results.Element{
        .modifier = .{},
        .value = values.Value{ .Boolean = true },
    };
    defer operations.delete.deleteElement(&right_true, allocator);

    var result = logicalAnd(&left, &right_true);
    defer operations.delete.deleteElement(&result, allocator);

    try std.testing.expectEqual(false, result.value.Boolean.?);
}

test "logicalAnd Integer left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is 0 -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0 } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is null -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = null } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is non-zero, right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 42 } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is non-zero, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = -1 } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalAnd UnsignedInteger left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is 0 -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 0 } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is null -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = null } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is non-zero, right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 10 } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is non-zero, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 10 } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalAnd Float left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is 0.0 -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.0 } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is null -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Float = null } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is non-zero, right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 3.14 } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is non-zero, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Float = -2.5 } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalAnd Boolean left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is null -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = null } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is true, right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is true, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalAnd Character left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is 0 -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0 } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is null -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Character = null } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is non-zero, right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 'A' } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is non-zero, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 'A' } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalAnd String left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is null -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .String = null } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is empty string "" -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "") } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is non-empty string, right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "hello") } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is non-empty string, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "hello") } };
        defer operations.delete.deleteElement(&left, allocator);
        var res = logicalAnd(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalAnd Error left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left.name is null -> false
    {
        const err_ptr = try allocator.create(values.ErrorValue);
        err_ptr.* = values.ErrorValue{
            .name = null,
            .details = null,
            .stack_trace = std.ArrayList([]const u8).empty,
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Error = err_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left.name is non-null, right is true -> true
    {
        const err_ptr = try allocator.create(values.ErrorValue);
        err_ptr.* = values.ErrorValue{
            .name = try allocator.dupe(u8, "CustomError"),
            .details = null,
            .stack_trace = std.ArrayList([]const u8).empty,
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Error = err_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left.name is non-null, right is false -> false
    {
        const err_ptr = try allocator.create(values.ErrorValue);
        err_ptr.* = values.ErrorValue{
            .name = try allocator.dupe(u8, "CustomError"),
            .details = null,
            .stack_trace = std.ArrayList([]const u8).empty,
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Error = err_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalAnd(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalAnd Type left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

    const type_ptr = try allocator.create(values.TypeValue);
    type_ptr.* = values.TypeValue{
        .kind = TypeBytecode.Int,
        .is_nullable = false,
        .contained = std.ArrayList(values.TypeValue).empty,
    };
    var left = results.Element{ .modifier = .{}, .value = values.Value{ .Type = type_ptr } };
    defer operations.delete.deleteElement(&left, allocator);

    // right is true -> true
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = logicalAnd(&left, &right);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // right is false -> false
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = logicalAnd(&left, &right);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalAnd Reference left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left.index is null -> false
    {
        const ref_ptr = try allocator.create(values.ReferenceValue);
        ref_ptr.* = values.ReferenceValue{
            .index = null,
            .type = values.TypeValue{
                .kind = TypeBytecode.Int,
                .is_nullable = false,
                .contained = std.ArrayList(values.TypeValue).empty,
            },
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Reference = ref_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left.index is non-null, right is true -> true
    {
        const ref_ptr = try allocator.create(values.ReferenceValue);
        ref_ptr.* = values.ReferenceValue{
            .index = 12,
            .type = values.TypeValue{
                .kind = TypeBytecode.Int,
                .is_nullable = false,
                .contained = std.ArrayList(values.TypeValue).empty,
            },
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Reference = ref_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left.index is non-null, right is false -> false
    {
        const ref_ptr = try allocator.create(values.ReferenceValue);
        ref_ptr.* = values.ReferenceValue{
            .index = 12,
            .type = values.TypeValue{
                .kind = TypeBytecode.Int,
                .is_nullable = false,
                .contained = std.ArrayList(values.TypeValue).empty,
            },
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Reference = ref_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalAnd(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalAnd List left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left.items is null -> false
    {
        const list_ptr = try allocator.create(values.ListValue);
        list_ptr.* = values.ListValue{
            .items = null,
            .type = values.TypeValue{
                .kind = TypeBytecode.List,
                .is_nullable = false,
                .contained = std.ArrayList(values.TypeValue).empty,
            },
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .List = list_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left.items is empty list (len == 0) -> false
    {
        const list_ptr = try allocator.create(values.ListValue);
        list_ptr.* = values.ListValue{
            .items = std.ArrayList(values.Value).empty,
            .type = values.TypeValue{
                .kind = TypeBytecode.List,
                .is_nullable = false,
                .contained = std.ArrayList(values.TypeValue).empty,
            },
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .List = list_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left.items has elements, right is true -> true
    {
        var items = std.ArrayList(values.Value).empty;
        try items.append(allocator, values.Value{ .Integer = 1 });

        const list_ptr = try allocator.create(values.ListValue);
        list_ptr.* = values.ListValue{
            .items = items,
            .type = values.TypeValue{
                .kind = TypeBytecode.List,
                .is_nullable = false,
                .contained = std.ArrayList(values.TypeValue).empty,
            },
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .List = list_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalAnd(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left.items has elements, right is false -> false
    {
        var items = std.ArrayList(values.Value).empty;
        try items.append(allocator, values.Value{ .Integer = 1 });

        const list_ptr = try allocator.create(values.ListValue);
        list_ptr.* = values.ListValue{
            .items = items,
            .type = values.TypeValue{
                .kind = TypeBytecode.List,
                .is_nullable = false,
                .contained = std.ArrayList(values.TypeValue).empty,
            },
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .List = list_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalAnd(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}
