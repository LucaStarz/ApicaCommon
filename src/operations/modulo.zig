const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");
const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

const OPERATOR_NAME: []const u8 = "%";

pub fn modulo(left: *const results.Element, right: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (left.value.isNull() or right.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.nullOperationError(OPERATOR_NAME, allocator) };
    }

    const result = switch (left.value) {
        .Integer => |value| moduloInteger(value.?, &right.value),
        .UnsignedInteger => |value| moduloUnsignedInteger(value.?, &right.value),
        .Float => |value| moduloFloat(value.?, &right.value),
        .Boolean => |value| moduloBoolean(value.?, &right.value),
        .Character => |value| moduloCharacter(value.?, &right.value),

        else => InternalError.UndefinedOperation,
    } catch |err| {
        switch (err) {
            InternalError.UndefinedOperation => return results.OperationResult{ .failure = try results.Signal.binaryOperationError(OPERATOR_NAME, left, right, allocator) },
            InternalError.ZeroDivisionOperation => return results.OperationResult{ .failure = try results.Signal.zeroDivisionOperationError(allocator) },
            else => return err,
        }
    };

    return results.OperationResult{ .success = result };
}

fn moduloInteger(left: i64, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @rem(left, value.?) }),
        .UnsignedInteger => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @rem(left, @as(i64, @intCast(value.?))) }),
        .Float => |value| if (value.? == 0.0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @rem(@as(f64, @floatFromInt(left)), value.?) }),
        .Boolean => |value| if (!value.?) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = 0 }),
        .Character => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @rem(left, @as(i64, @intCast(value.?))) }),

        else => InternalError.UndefinedOperation,
    };
}

fn moduloUnsignedInteger(left: u64, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @rem(@as(i64, @intCast(left)), value.?) }),
        .UnsignedInteger => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = left % value.? }),
        .Float => |value| if (value.? == 0.0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @rem(@as(f64, @floatFromInt(left)), value.?) }),
        .Boolean => |value| if (!value.?) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = 0 }),
        .Character => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = left % @as(u64, @intCast(value.?)) }),

        else => InternalError.UndefinedOperation,
    };
}

fn moduloFloat(left: f64, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @rem(left, @as(f64, @floatFromInt(value.?))) }),
        .UnsignedInteger => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @rem(left, @as(f64, @floatFromInt(value.?))) }),
        .Float => |value| if (value.? == 0.0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @rem(left, value.?) }),
        .Boolean => |value| if (!value.?) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @rem(left, 1.0) }),
        .Character => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @rem(left, @as(f64, @floatFromInt(value.?))) }),

        else => InternalError.UndefinedOperation,
    };
}

fn moduloBoolean(left: bool, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @rem(@as(i64, @intFromBool(left)), value.?) }),
        .UnsignedInteger => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intFromBool(left)) % value.? }),
        .Float => |value| if (value.? == 0.0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @rem(@as(f64, @floatFromInt(@intFromBool(left))), value.?) }),
        .Boolean => |value| if (!value.?) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = 0 }),
        .Character => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Character = @as(u32, @intFromBool(left)) % value.? }),

        else => InternalError.UndefinedOperation,
    };
}

fn moduloCharacter(left: u32, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @rem(@as(i64, @intCast(left)), value.?) }),
        .UnsignedInteger => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intCast(left)) % value.? }),
        .Float => |value| if (value.? == 0.0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @rem(@as(f64, @floatFromInt(left)), value.?) }),
        .Boolean => |value| if (!value.?) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Character = 0 }),
        .Character => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Character = left % value.? }),

        else => InternalError.UndefinedOperation,
    };
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "modulo null operands fail" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var num = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 10 },
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

    var res1 = try modulo(&null_lit, &num, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);

    var res2 = try modulo(&num, &null_lit, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2 == .failure);

    var res3 = try modulo(&null_opt, &num, allocator);
    defer operations.delete.deleteResult(&res3, allocator);
    try std.testing.expect(res3 == .failure);

    var res4 = try modulo(&num, &null_opt, allocator);
    defer operations.delete.deleteResult(&res4, allocator);
    try std.testing.expect(res4 == .failure);
}

test "modulo Integer combinations, signs and zero division" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 17 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Integer % Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 2), res.success.value.Integer);
    }

    // 2. Integer % UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 4 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 1), res.success.value.Integer);
    }

    // 3. Integer % Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 4.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 3.5), res.success.value.Float);
    }

    // 4. Integer % Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0), res.success.value.Integer);
    }

    // 5. Integer % Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 10 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 7), res.success.value.Integer);
    }

    // 6. Negative left integer keeps negative sign (@rem rule)
    {
        var left_neg = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = -17 } };
        defer operations.delete.deleteElement(&left_neg, allocator);
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 5 } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try modulo(&left_neg, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, -2), res.success.value.Integer);
    }

    // 7. Modulo by zero fails
    {
        var zero = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0 } };
        defer operations.delete.deleteElement(&zero, allocator);
        var res = try modulo(&left, &zero, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "modulo UnsignedInteger combinations and zero division" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .UnsignedInteger = 23 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // UnsignedInteger % UnsignedInteger -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 3), res.success.value.UnsignedInteger);
    }

    // UnsignedInteger % Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 7 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 2), res.success.value.Integer);
    }

    // UnsignedInteger % Boolean(false) -> Zero division failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "modulo Float combinations and zero division" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Float = 7.5 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // Float % Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 2.0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 1.5), res.success.value.Float);
    }

    // Float % Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 2 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 1.5), res.success.value.Float);
    }

    // Float % 0.0 -> Zero division failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "modulo Boolean and Character" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // Boolean % Integer
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } }; // 1
        defer operations.delete.deleteElement(&left, allocator);
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 2 } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 1), res.success.value.Integer);
    }

    // Character % Character
    {
        var left = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 65 } };
        defer operations.delete.deleteElement(&left, allocator);
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 10 } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try modulo(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 5), res.success.value.Character);
    }
}

test "modulo unsupported operand fails" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var str = results.Element{
        .modifier = .{},
        .value = values.Value{ .String = try allocator.dupe(u8, "abc") },
    };
    defer operations.delete.deleteElement(&str, allocator);

    var num = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 3 },
    };
    defer operations.delete.deleteElement(&num, allocator);

    var res = try modulo(&str, &num, allocator);
    defer operations.delete.deleteResult(&res, allocator);
    try std.testing.expect(res == .failure);
}
