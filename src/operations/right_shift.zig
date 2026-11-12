const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");
const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

const OPERATOR_NAME: []const u8 = ">>";

pub fn rightShift(left: *const results.Element, right: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (left.value.isNull() or right.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.nullOperationError(OPERATOR_NAME, allocator) };
    }

    const result = switch (left.value) {
        .Integer => |value| rightShiftInteger(value.?, &right.value),
        .UnsignedInteger => |value| rightShiftUnsignedInteger(value.?, &right.value),
        .Boolean => |value| rightShiftBoolean(value.?, &right.value),
        .Character => |value| rightShiftCharacter(value.?, &right.value),

        else => InternalError.UndefinedOperation,
    } catch |err| {
        switch (err) {
            InternalError.UndefinedOperation => return results.OperationResult{ .failure = try results.Signal.binaryOperationError(OPERATOR_NAME, left, right, allocator) },
            InternalError.UndefinedNegativeOperation => return results.OperationResult{ .failure = try results.Signal.negativeRightOperandError(allocator) },
            else => return err,
        }
    };

    return results.OperationResult{ .success = result };
}

fn extractShiftAmount(right: *const values.Value) InternalError!u64 {
    return switch (right.*) {
        .Integer => |value| if (value.? < 0) {
            return InternalError.UndefinedNegativeOperation;
        } else @as(u64, @intCast(value.?)),
        .UnsignedInteger => |value| value.?,
        .Boolean => |value| @as(u64, @intFromBool(value.?)),
        .Character => |value| @as(u64, value.?),
        else => InternalError.UndefinedOperation,
    };
}

fn rightShiftInteger(left: i64, right: *const values.Value) InternalError!results.Element {
    const shift = try extractShiftAmount(right);
    if (shift >= 64) {
        return results.Element.init(values.Value{ .Integer = if (left < 0) -1 else 0 });
    }
    const shift_u6: u6 = @as(u6, @intCast(shift));
    return results.Element.init(values.Value{ .Integer = left >> shift_u6 });
}

fn rightShiftUnsignedInteger(left: u64, right: *const values.Value) InternalError!results.Element {
    const shift = try extractShiftAmount(right);
    if (shift >= 64) {
        return results.Element.init(values.Value{ .UnsignedInteger = 0 });
    }
    const shift_u6: u6 = @as(u6, @intCast(shift));
    return results.Element.init(values.Value{ .UnsignedInteger = left >> shift_u6 });
}

fn rightShiftBoolean(left: bool, right: *const values.Value) InternalError!results.Element {
    const int_val: u64 = @as(u64, @intFromBool(left));
    const shift = try extractShiftAmount(right);
    if (shift >= 64) {
        return results.Element.init(values.Value{ .UnsignedInteger = 0 });
    }
    const shift_u6: u6 = @as(u6, @intCast(shift));
    return results.Element.init(values.Value{ .UnsignedInteger = int_val >> shift_u6 });
}

fn rightShiftCharacter(left: u32, right: *const values.Value) InternalError!results.Element {
    const shift = try extractShiftAmount(right);
    if (shift >= 32) {
        return results.Element.init(values.Value{ .Character = 0 });
    }
    const shift_u5: u5 = @as(u5, @intCast(shift));
    return results.Element.init(values.Value{ .Character = left >> shift_u5 });
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "rightShift null operands fail" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var num = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 16 },
    };
    defer operations.delete.deleteElement(&num, allocator);

    var null_lit = results.Element{
        .modifier = .{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&null_lit, allocator);

    var null_opt = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = null },
    };
    defer operations.delete.deleteElement(&null_opt, allocator);

    var res1 = try rightShift(&null_lit, &num, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);

    var res2 = try rightShift(&num, &null_lit, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2 == .failure);

    var res3 = try rightShift(&null_opt, &num, allocator);
    defer operations.delete.deleteResult(&res3, allocator);
    try std.testing.expect(res3 == .failure);

    var res4 = try rightShift(&num, &null_opt, allocator);
    defer operations.delete.deleteResult(&res4, allocator);
    try std.testing.expect(res4 == .failure);
}

test "rightShift Float operand fails" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var flt = results.Element{
        .modifier = .{},
        .value = values.Value{ .Float = 8.0 },
    };
    defer operations.delete.deleteElement(&flt, allocator);

    var int_elem = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 2 },
    };
    defer operations.delete.deleteElement(&int_elem, allocator);

    // Float >> Integer
    var res_left = try rightShift(&flt, &int_elem, allocator);
    defer operations.delete.deleteResult(&res_left, allocator);
    try std.testing.expect(res_left == .failure);

    // Integer >> Float
    var res_right = try rightShift(&int_elem, &flt, allocator);
    defer operations.delete.deleteResult(&res_right, allocator);
    try std.testing.expect(res_right == .failure);
}

test "rightShift Integer positive, negative, and saturation" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 32 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Integer >> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 2 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 8), res.success.value.Integer);
    }

    // 2. Integer >> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 3 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 4), res.success.value.Integer);
    }

    // 3. Integer >> Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } }; // 1
        defer operations.delete.deleteElement(&right, allocator);
        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 16), res.success.value.Integer);
    }

    // 4. Integer >> Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 1), res.success.value.Integer);
    }

    // 5. Negative shift amount fails
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = -1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }

    // 6. Positive int with shift >= 64 -> 0
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 64 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0), res.success.value.Integer);
    }

    // 7. Negative int arithmetic shift & saturation >= 64 -> -1
    {
        var left_neg = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = -16 } };
        defer operations.delete.deleteElement(&left_neg, allocator);

        var right_small = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 2 } };
        defer operations.delete.deleteElement(&right_small, allocator);
        var res_arith = try rightShift(&left_neg, &right_small, allocator);
        defer operations.delete.deleteResult(&res_arith, allocator);
        try std.testing.expectEqual(@as(?i64, -4), res_arith.success.value.Integer);

        var right_large = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 70 } };
        defer operations.delete.deleteElement(&right_large, allocator);
        var res_sat = try rightShift(&left_neg, &right_large, allocator);
        defer operations.delete.deleteResult(&res_sat, allocator);
        try std.testing.expectEqual(@as(?i64, -1), res_sat.success.value.Integer);
    }

    // 8. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "rightShift UnsignedInteger combinations" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .UnsignedInteger = 64 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // UnsignedInteger >> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 3 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 8), res.success.value.UnsignedInteger);
    }

    // Shift >= 64 -> 0
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 100 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 0), res.success.value.UnsignedInteger);
    }
}

test "rightShift Boolean and Character" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // Boolean >> 0 -> 1
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } }; // 1
        defer operations.delete.deleteElement(&left, allocator);
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0 } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 1), res.success.value.UnsignedInteger);
    }

    // Boolean >> 1 -> 0
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } }; // 1
        defer operations.delete.deleteElement(&left, allocator);
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 1 } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 0), res.success.value.UnsignedInteger);
    }

    // Character >> 2 -> Character
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 40 } };
        defer operations.delete.deleteElement(&left, allocator);
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 2 } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 10), res.success.value.Character);
    }

    // Character shift >= 32 -> 0
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 40 } };
        defer operations.delete.deleteElement(&left, allocator);
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 35 } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try rightShift(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 0), res.success.value.Character);
    }
}

test "rightShift unsupported left operand type fails" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .String = try allocator.dupe(u8, "test") },
    };
    defer operations.delete.deleteElement(&left, allocator);

    var right = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 2 },
    };
    defer operations.delete.deleteElement(&right, allocator);

    var res = try rightShift(&left, &right, allocator);
    defer operations.delete.deleteResult(&res, allocator);
    try std.testing.expect(res == .failure);
}
