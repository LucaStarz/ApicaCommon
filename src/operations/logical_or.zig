const results = @import("../results.zig");
const values = @import("../values.zig");
const booleanState = @import("../utils.zig").booleanState;

pub fn logicalOr(left: *const results.Element, right: *const results.Element) results.Element {
    return switch (left.value) {
        .Null => results.Element.init(values.Value{ .Boolean = booleanState(&right.value) }),
        .Integer => |value| logicalOrInteger(value, &right.value),
        .UnsignedInteger => |value| logicalOrUnsignedInteger(value, &right.value),
        .Float => |value| logicalOrFloat(value, &right.value),
        .Boolean => |value| logicalOrBoolean(value, &right.value),
        .Character => |value| logicalOrCharacter(value, &right.value),
        .String => |value| logicalOrString(value, &right.value),
        .Error => |value| logicalOrError(value, &right.value),
        .Type => results.Element.init(values.Value{ .Boolean = true }),
        .Reference => |value| logicalOrReference(value, &right.value),
        .List => |value| logicalOrList(value, &right.value),
    };
}

fn logicalOrInteger(left: ?i64, right: *const values.Value) results.Element {
    if ((left orelse 0) != 0) {
        return results.Element.init(values.Value{ .Boolean = true });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalOrUnsignedInteger(left: ?u64, right: *const values.Value) results.Element {
    if ((left orelse 0) != 0) {
        return results.Element.init(values.Value{ .Boolean = true });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalOrFloat(left: ?f64, right: *const values.Value) results.Element {
    if ((left orelse 0.0) != 0.0) {
        return results.Element.init(values.Value{ .Boolean = true });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalOrBoolean(left: ?bool, right: *const values.Value) results.Element {
    if (left orelse false) {
        return results.Element.init(values.Value{ .Boolean = true });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalOrCharacter(left: ?u32, right: *const values.Value) results.Element {
    if ((left orelse 0) != 0) {
        return results.Element.init(values.Value{ .Boolean = true });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalOrString(left: ?[]const u8, right: *const values.Value) results.Element {
    if (left != null and left.?.len > 0) {
        return results.Element.init(values.Value{ .Boolean = true });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalOrError(left: *const values.ErrorValue, right: *const values.Value) results.Element {
    if (left.name != null) {
        return results.Element.init(values.Value{ .Boolean = true });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalOrReference(left: *const values.ReferenceValue, right: *const values.Value) results.Element {
    if (left.index != null) {
        return results.Element.init(values.Value{ .Boolean = true });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

fn logicalOrList(left: *const values.ListValue, right: *const values.Value) results.Element {
    if (left.items != null and left.items.?.items.len > 0) {
        return results.Element.init(values.Value{ .Boolean = true });
    } else {
        return results.Element.init(values.Value{ .Boolean = booleanState(right) });
    }
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "logicalOr Null left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // Null || true -> true
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = logicalOr(&left, &right);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // Null || false -> false
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = logicalOr(&left, &right);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalOr Integer left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is non-zero -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 42 } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is 0, right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0 } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is 0, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0 } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is null, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = null } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalOr UnsignedInteger left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is non-zero -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 10 } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is 0, right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 0 } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is 0, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 0 } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is null, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = null } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalOr Float left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is non-zero -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 3.14 } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is 0.0, right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.0 } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is 0.0, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.0 } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is null, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Float = null } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalOr Boolean left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is false, right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is false, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is null, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = null } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalOr Character left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is non-zero -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 'A' } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is 0, right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0 } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is 0, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0 } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is null, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Character = null } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalOr String left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left is non-empty string -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "hello") } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is empty string "", right is true -> true
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "") } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left is empty string "", right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "") } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left is null, right is false -> false
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .String = null } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalOr Error left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left.name is non-null -> true
    {
        const err_ptr = try allocator.create(values.ErrorValue);
        err_ptr.* = values.ErrorValue{
            .name = try allocator.dupe(u8, "CustomError"),
            .details = null,
            .stack_trace = std.ArrayList([]const u8).empty,
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Error = err_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left.name is null, right is true -> true
    {
        const err_ptr = try allocator.create(values.ErrorValue);
        err_ptr.* = values.ErrorValue{
            .name = null,
            .details = null,
            .stack_trace = std.ArrayList([]const u8).empty,
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Error = err_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left.name is null, right is false -> false
    {
        const err_ptr = try allocator.create(values.ErrorValue);
        err_ptr.* = values.ErrorValue{
            .name = null,
            .details = null,
            .stack_trace = std.ArrayList([]const u8).empty,
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Error = err_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalOr Type left operand" {
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

    var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right, allocator);

    // Type is always truthy -> true
    var res = logicalOr(&left, &right);
    defer operations.delete.deleteElement(&res, allocator);
    try std.testing.expectEqual(true, res.value.Boolean.?);
}

test "logicalOr Reference left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left.index is non-null -> true
    {
        const ref_ptr = try allocator.create(values.ReferenceValue);
        ref_ptr.* = values.ReferenceValue{
            .index = 10,
            .type = values.TypeValue{
                .kind = TypeBytecode.Int,
                .is_nullable = false,
                .contained = std.ArrayList(values.TypeValue).empty,
            },
        };
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Reference = ref_ptr } };
        defer operations.delete.deleteElement(&left, allocator);

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left.index is null, right is true -> true
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

        var res = logicalOr(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left.index is null, right is false -> false
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

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}

test "logicalOr List left operand" {
    const std = @import("std");
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

    var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
    defer operations.delete.deleteElement(&right_true, allocator);

    var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
    defer operations.delete.deleteElement(&right_false, allocator);

    // left.items has elements -> true
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

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left.items is empty list (len == 0), right is true -> true
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

        var res = logicalOr(&left, &right_true);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(true, res.value.Boolean.?);
    }

    // left.items is empty list (len == 0), right is false -> false
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

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }

    // left.items is null, right is false -> false
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

        var res = logicalOr(&left, &right_false);
        defer operations.delete.deleteElement(&res, allocator);
        try std.testing.expectEqual(false, res.value.Boolean.?);
    }
}
