const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");
const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

const OPERATOR_NAME: []const u8 = "/";

pub fn divide(left: *const results.Element, right: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (left.value.isNull() or right.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.nullOperationError(OPERATOR_NAME, allocator) };
    }

    const result = switch (left.value) {
        .Integer => |value| divideInteger(value.?, &right.value),
        .UnsignedInteger => |value| divideUnsignedInteger(value.?, &right.value),
        .Float => |value| divideFloat(value.?, &right.value),
        .Boolean => |value| divideBoolean(value.?, &right.value),
        .Character => |value| divideCharacter(value.?, &right.value),

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

fn divideInteger(left: i64, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @divTrunc(left, value.?) }),
        .UnsignedInteger => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @divTrunc(left, @as(i64, @intCast(value.?))) }),
        .Float => |value| if (value.? == 0.0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) / value.? }),
        .Boolean => |value| if (!value.?) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = left }),
        .Character => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @divTrunc(left, @as(i64, @intCast(value.?))) }),

        else => InternalError.UndefinedOperation,
    };
}

fn divideUnsignedInteger(left: u64, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @divTrunc(@as(i64, @intCast(left)), value.?) }),
        .UnsignedInteger => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = left / value.? }),
        .Float => |value| if (value.? == 0.0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) / value.? }),
        .Boolean => |value| if (!value.?) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = left }),
        .Character => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = left / @as(u64, @intCast(value.?)) }),

        else => InternalError.UndefinedOperation,
    };
}

fn divideFloat(left: f64, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = left / @as(f64, @floatFromInt(value.?)) }),
        .UnsignedInteger => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = left / @as(f64, @floatFromInt(value.?)) }),
        .Float => |value| if (value.? == 0.0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = left / value.? }),
        .Boolean => |value| if (!value.?) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = left }),
        .Character => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = left / @as(f64, @floatFromInt(value.?)) }),

        else => InternalError.UndefinedOperation,
    };
}

fn divideBoolean(left: bool, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @divTrunc(@as(i64, @intFromBool(left)), value.?) }),
        .UnsignedInteger => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intFromBool(left)) / value.? }),
        .Float => |value| if (value.? == 0.0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(@intFromBool(left))) / value.? }),
        .Boolean => |value| if (!value.?) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intFromBool(left)) }),
        .Character => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Character = @as(u32, @intFromBool(left)) / value.? }),

        else => InternalError.UndefinedOperation,
    };
}

fn divideCharacter(left: u32, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Integer = @divTrunc(@as(i64, @intCast(left)), value.?) }),
        .UnsignedInteger => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intCast(left)) / value.? }),
        .Float => |value| if (value.? == 0.0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) / value.? }),
        .Boolean => |value| if (!value.?) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Character = left }),
        .Character => |value| if (value.? == 0) InternalError.ZeroDivisionOperation else results.Element.init(values.Value{ .Character = left / value.? }),

        else => InternalError.UndefinedOperation,
    };
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "divide null operands result in failure" {
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

    var res1 = try divide(&null_lit, &num, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);

    var res2 = try divide(&num, &null_lit, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2 == .failure);

    var res3 = try divide(&null_opt, &num, allocator);
    defer operations.delete.deleteResult(&res3, allocator);
    try std.testing.expect(res3 == .failure);

    var res4 = try divide(&num, &null_opt, allocator);
    defer operations.delete.deleteResult(&res4, allocator);
    try std.testing.expect(res4 == .failure);
}

test "divide Integer all conversions and zero division" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 20 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // Integer / Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 4 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 5), res.success.value.Integer);
    }

    // Integer / UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 4), res.success.value.Integer);
    }

    // Integer / Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 2.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 8.0), res.success.value.Float);
    }

    // Integer / Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 20), res.success.value.Integer);
    }

    // Integer / Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 2 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 10), res.success.value.Integer);
    }

    // Division by zero -> failure
    {
        var zero = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0 } };
        defer operations.delete.deleteElement(&zero, allocator);
        var res = try divide(&left, &zero, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }

    // Incompatible operand (String) -> failure
    {
        var str = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&str, allocator);
        var res = try divide(&left, &str, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "divide UnsignedInteger all conversions and zero division" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .UnsignedInteger = 50 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // UnsignedInteger / Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 10), res.success.value.Integer);
    }

    // UnsignedInteger / UnsignedInteger -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 2 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 25), res.success.value.UnsignedInteger);
    }

    // UnsignedInteger / Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 4.0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 12.5), res.success.value.Float);
    }

    // UnsignedInteger / Boolean (false) -> Zero division failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "divide Float all conversions and zero division" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Float = 15.0 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // Float / Integer -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 2 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 7.5), res.success.value.Float);
    }

    // Float / Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 3.0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 5.0), res.success.value.Float);
    }

    // Float / Float 0.0 -> Zero division failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "divide Boolean combinations and zero division" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Boolean = true }, // 1
    };
    defer operations.delete.deleteElement(&left, allocator);

    // Boolean / Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 1), res.success.value.Integer);
    }

    // Boolean / Boolean (true) -> 1
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 1), res.success.value.UnsignedInteger);
    }

    // Boolean / Boolean (false) -> Zero division failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "divide Character combinations and zero division" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Character = 100 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // Character / Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 10 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 10), res.success.value.Character);
    }

    // Character / Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 2 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 50), res.success.value.Integer);
    }

    // Character / Character(0) -> Zero division failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try divide(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "divide unsupported types fails with binaryOperationError" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var str = results.Element{
        .modifier = .{},
        .value = values.Value{ .String = try allocator.dupe(u8, "hello") },
    };
    defer operations.delete.deleteElement(&str, allocator);

    var num = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 2 },
    };
    defer operations.delete.deleteElement(&num, allocator);

    // String / Integer
    var res1 = try divide(&str, &num, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);
}
