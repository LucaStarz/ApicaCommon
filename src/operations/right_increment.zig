const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");

const OPERATOR_NAME: []const u8 = "right ++";

pub fn rightIncrement(operand: *results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (operand.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.nullOperationError(OPERATOR_NAME, allocator) };
    }

    if (operand.modifier.CONSTANT) {
        return results.OperationResult{ .failure = try results.Signal.constantOperationError(OPERATOR_NAME, allocator) };
    }

    const result = switch (operand.value) {
        .Integer => |*value| rightIncrementInteger(value),
        .UnsignedInteger => |*value| rightIncrementUnsignedInteger(value),
        .Float => |*value| rightIncrementFloat(value),
        .Character => |*value| rightIncrementCharacter(value),

        else => null,
    };

    if (result) |element| {
        return results.OperationResult{ .success = element };
    } else {
        return results.OperationResult{ .failure = try results.Signal.unaryOperationError(OPERATOR_NAME, operand, allocator) };
    }
}

fn rightIncrementInteger(operand: *?i64) results.Element {
    const result = results.Element.init(values.Value{ .Integer = operand.*.? });
    operand.*.? += 1;
    return result;
}

fn rightIncrementUnsignedInteger(operand: *?u64) results.Element {
    const result = results.Element.init(values.Value{ .UnsignedInteger = operand.*.? });
    operand.*.? += 1;
    return result;
}

fn rightIncrementFloat(operand: *?f64) results.Element {
    const result = results.Element.init(values.Value{ .Float = operand.*.? });
    operand.*.? += 1.0;
    return result;
}

fn rightIncrementCharacter(operand: *?u32) results.Element {
    const result = results.Element.init(values.Value{ .Character = operand.*.? });
    operand.*.? += 1;
    return result;
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "rightIncrement null operand checks" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // 1. Literal Null value
    var null_literal = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&null_literal, allocator);

    var res1 = try rightIncrement(&null_literal, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);

    // 2. Optional Null (Integer)
    var null_optional = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = null },
    };
    defer operations.delete.deleteElement(&null_optional, allocator);

    var res2 = try rightIncrement(&null_optional, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2 == .failure);
}

test "rightIncrement CONSTANT modifier fails" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var a = results.Element{
        .modifier = results.ElementModifier{ .CONSTANT = true },
        .value = values.Value{ .Integer = 10 },
    };
    defer operations.delete.deleteElement(&a, allocator);

    var result = try rightIncrement(&a, allocator);
    defer operations.delete.deleteResult(&result, allocator);

    try std.testing.expect(result == .failure);
    try std.testing.expectEqual(@as(?i64, 10), a.value.Integer);
}

test "rightIncrement Integer" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var a = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 5 },
    };
    defer operations.delete.deleteElement(&a, allocator);

    var result = try rightIncrement(&a, allocator);
    defer operations.delete.deleteResult(&result, allocator);

    try std.testing.expect(result == .success);
    // Returns original value before increment
    try std.testing.expectEqual(@as(?i64, 5), result.success.value.Integer);
    // Mutates target operand
    try std.testing.expectEqual(@as(?i64, 6), a.value.Integer);
}

test "rightIncrement UnsignedInteger" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var a = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .UnsignedInteger = 10 },
    };
    defer operations.delete.deleteElement(&a, allocator);

    var result = try rightIncrement(&a, allocator);
    defer operations.delete.deleteResult(&result, allocator);

    try std.testing.expect(result == .success);
    // Returns original value before increment
    try std.testing.expectEqual(@as(?u64, 10), result.success.value.UnsignedInteger);
    // Mutates target operand
    try std.testing.expectEqual(@as(?u64, 11), a.value.UnsignedInteger);
}

test "rightIncrement Float" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var a = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Float = 5.5 },
    };
    defer operations.delete.deleteElement(&a, allocator);

    var result = try rightIncrement(&a, allocator);
    defer operations.delete.deleteResult(&result, allocator);

    try std.testing.expect(result == .success);
    // Returns original value before increment
    try std.testing.expectEqual(@as(?f64, 5.5), result.success.value.Float);
    // Mutates target operand
    try std.testing.expectEqual(@as(?f64, 6.5), a.value.Float);
}

test "rightIncrement Character" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var a = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Character = 65 }, // 'A'
    };
    defer operations.delete.deleteElement(&a, allocator);

    var result = try rightIncrement(&a, allocator);
    defer operations.delete.deleteResult(&result, allocator);

    try std.testing.expect(result == .success);
    // Returns original value before increment
    try std.testing.expectEqual(@as(?u32, 65), result.success.value.Character); // 'A'
    // Mutates target operand
    try std.testing.expectEqual(@as(?u32, 66), a.value.Character); // 'B'
}

test "rightIncrement unsupported types fail" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // 1. Boolean operand -> unaryOperationError failure
    {
        var a = results.Element{
            .modifier = results.ElementModifier{},
            .value = values.Value{ .Boolean = true },
        };
        defer operations.delete.deleteElement(&a, allocator);

        var result = try rightIncrement(&a, allocator);
        defer operations.delete.deleteResult(&result, allocator);

        try std.testing.expect(result == .failure);
    }

    // 2. String operand -> unaryOperationError failure
    {
        var a = results.Element{
            .modifier = results.ElementModifier{},
            .value = values.Value{ .String = try allocator.dupe(u8, "immutable_str") },
        };
        defer operations.delete.deleteElement(&a, allocator);

        var result = try rightIncrement(&a, allocator);
        defer operations.delete.deleteResult(&result, allocator);

        try std.testing.expect(result == .failure);
    }
}
