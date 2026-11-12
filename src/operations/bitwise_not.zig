const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");

const OPERATOR_NAME: []const u8 = "~";

pub fn bitwiseNot(operand: *results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (operand.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.nullOperationError(OPERATOR_NAME, allocator) };
    }

    const result = switch (operand.value) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = ~value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = ~value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = !value.? }),
        .Character => |value| results.Element.init(values.Value{ .Character = ~value.? }),

        else => null,
    };

    if (result) |element| {
        return results.OperationResult{ .success = element };
    } else {
        return results.OperationResult{ .failure = try results.Signal.unaryOperationError(OPERATOR_NAME, operand, allocator) };
    }
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "bitwiseNot null operand checks" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // 1. Literal Null value
    var null_literal = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&null_literal, allocator);

    var res1 = try bitwiseNot(&null_literal, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);

    // 2. Optional Null (Integer)
    var null_optional = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = null },
    };
    defer operations.delete.deleteElement(&null_optional, allocator);

    var res2 = try bitwiseNot(&null_optional, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2 == .failure);
}

test "bitwiseNot Integer" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var a = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 5 },
    };
    defer operations.delete.deleteElement(&a, allocator);

    var result = try bitwiseNot(&a, allocator);
    defer operations.delete.deleteResult(&result, allocator);

    try std.testing.expect(result == .success);
    try std.testing.expectEqual(@as(?i64, -6), result.success.value.Integer);
}

test "bitwiseNot UnsignedInteger" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var a = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .UnsignedInteger = 0 },
    };
    defer operations.delete.deleteElement(&a, allocator);

    var result = try bitwiseNot(&a, allocator);
    defer operations.delete.deleteResult(&result, allocator);

    try std.testing.expect(result == .success);
    try std.testing.expectEqual(@as(?u64, ~@as(u64, 0)), result.success.value.UnsignedInteger);
}

test "bitwiseNot Boolean" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // true -> false
    {
        var a = results.Element{
            .modifier = results.ElementModifier{},
            .value = values.Value{ .Boolean = true },
        };
        defer operations.delete.deleteElement(&a, allocator);

        var result = try bitwiseNot(&a, allocator);
        defer operations.delete.deleteResult(&result, allocator);

        try std.testing.expect(result == .success);
        try std.testing.expectEqual(@as(?bool, false), result.success.value.Boolean);
    }

    // false -> true
    {
        var a = results.Element{
            .modifier = results.ElementModifier{},
            .value = values.Value{ .Boolean = false },
        };
        defer operations.delete.deleteElement(&a, allocator);

        var result = try bitwiseNot(&a, allocator);
        defer operations.delete.deleteResult(&result, allocator);

        try std.testing.expect(result == .success);
        try std.testing.expectEqual(@as(?bool, true), result.success.value.Boolean);
    }
}

test "bitwiseNot Character" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var a = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Character = 0x000000FF },
    };
    defer operations.delete.deleteElement(&a, allocator);

    var result = try bitwiseNot(&a, allocator);
    defer operations.delete.deleteResult(&result, allocator);

    try std.testing.expect(result == .success);
    try std.testing.expectEqual(@as(?u32, ~@as(u32, 0x000000FF)), result.success.value.Character);
}

test "bitwiseNot unsupported types fail" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // 1. Float operand -> unaryOperationError failure
    {
        var a = results.Element{
            .modifier = results.ElementModifier{},
            .value = values.Value{ .Float = 3.14 },
        };
        defer operations.delete.deleteElement(&a, allocator);

        var result = try bitwiseNot(&a, allocator);
        defer operations.delete.deleteResult(&result, allocator);

        try std.testing.expect(result == .failure);
    }

    // 2. String operand -> unaryOperationError failure
    {
        var a = results.Element{
            .modifier = results.ElementModifier{},
            .value = values.Value{ .String = try allocator.dupe(u8, "test") },
        };
        defer operations.delete.deleteElement(&a, allocator);

        var result = try bitwiseNot(&a, allocator);
        defer operations.delete.deleteResult(&result, allocator);

        try std.testing.expect(result == .failure);
    }
}
