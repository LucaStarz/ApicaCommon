const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");

const OPERATOR_NAME: []const u8 = "!";

pub fn logicalNot(operand: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    const result = switch (operand.value) {
        .Null => true,
        .Integer => |value| value == null or value.? == 0,
        .UnsignedInteger => |value| value == null or value.? == 0,
        .Float => |value| value == null or value.? == 0.0,
        .Boolean => |value| value == null or value.? == false,
        .Character => |value| value == null or value.? == 0,
        .String => |value| value == null or value.?.len == 0,
        .Error => |value| value.name == null,
        .Type => null,
        .Reference => |value| value.index == null,
        .List => |value| value.items == null,
    };

    if (result) |boolean| {
        return results.OperationResult{ .success = results.Element.init(values.Value{ .Boolean = boolean }) };
    } else {
        return results.OperationResult{ .failure = try results.Signal.unaryOperationError(OPERATOR_NAME, operand, allocator) };
    }
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "logicalNot Null value" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var a = results.Element{
        .modifier = .{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&a, allocator);

    var res = try logicalNot(&a, allocator);
    defer operations.delete.deleteResult(&res, allocator);

    try std.testing.expect(res == .success);
    try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
}

test "logicalNot Integer (null, 0, non-zero)" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // 1. null -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = null } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. 0 -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0 } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 3. non-zero -> false
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 42 } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }
}

test "logicalNot UnsignedInteger (null, 0, non-zero)" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // 1. null -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = null } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. 0 -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 0 } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 3. non-zero -> false
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 10 } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }
}

test "logicalNot Float (null, 0.0, non-zero)" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // 1. null -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Float = null } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. 0.0 -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.0 } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 3. non-zero -> false
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 3.14 } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }
}

test "logicalNot Boolean (null, false, true)" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // 1. null -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = null } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. false -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 3. true -> false
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }
}

test "logicalNot Character (null, 0, non-zero)" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // 1. null -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Character = null } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. 0 -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0 } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 3. non-zero -> false
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 'A' } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }
}

test "logicalNot String (null, empty, non-empty)" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // 1. null -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .String = null } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. empty string -> true
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "") } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 3. non-empty string -> false
    {
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "hello") } };
        defer operations.delete.deleteElement(&a, allocator);
        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }
}

test "logicalNot Error (null name, non-null name)" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // 1. name == null -> true
    {
        const err_ptr = try allocator.create(values.ErrorValue);
        err_ptr.* = values.ErrorValue{
            .name = null,
            .details = null,
            .stack_trace = std.ArrayList([]const u8).empty,
        };
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Error = err_ptr } };
        defer operations.delete.deleteElement(&a, allocator);

        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. name != null -> false
    {
        const err_ptr = try allocator.create(values.ErrorValue);
        err_ptr.* = values.ErrorValue{
            .name = try allocator.dupe(u8, "RuntimeError"),
            .details = null,
            .stack_trace = std.ArrayList([]const u8).empty,
        };
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Error = err_ptr } };
        defer operations.delete.deleteElement(&a, allocator);

        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }
}

test "logicalNot Type fails (unaryOperationError)" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

    const type_ptr = try allocator.create(values.TypeValue);
    type_ptr.* = values.TypeValue{
        .kind = TypeBytecode.Int,
        .is_nullable = false,
        .contained = std.ArrayList(values.TypeValue).empty,
    };
    var a = results.Element{ .modifier = .{}, .value = values.Value{ .Type = type_ptr } };
    defer operations.delete.deleteElement(&a, allocator);

    var res = try logicalNot(&a, allocator);
    defer operations.delete.deleteResult(&res, allocator);

    try std.testing.expect(res == .failure);
}

test "logicalNot Reference (null index, non-null index)" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

    // 1. index == null -> true
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
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Reference = ref_ptr } };
        defer operations.delete.deleteElement(&a, allocator);

        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. index != null -> false
    {
        const ref_ptr = try allocator.create(values.ReferenceValue);
        ref_ptr.* = values.ReferenceValue{
            .index = 5,
            .type = values.TypeValue{
                .kind = TypeBytecode.Int,
                .is_nullable = false,
                .contained = std.ArrayList(values.TypeValue).empty,
            },
        };
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .Reference = ref_ptr } };
        defer operations.delete.deleteElement(&a, allocator);

        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }
}

test "logicalNot List (null items, non-null items)" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

    // 1. items == null -> true
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
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .List = list_ptr } };
        defer operations.delete.deleteElement(&a, allocator);

        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. items != null -> false (even if list is empty, items != null)
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
        var a = results.Element{ .modifier = .{}, .value = values.Value{ .List = list_ptr } };
        defer operations.delete.deleteElement(&a, allocator);

        var res = try logicalNot(&a, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }
}
