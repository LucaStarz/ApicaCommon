const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");

const OPERATOR_NAME: []const u8 = "-";

pub fn subtract(left: *const results.Element, right: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (left.value.isNull() or right.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.nullOperationError(OPERATOR_NAME, allocator) };
    }

    const result = switch (left.value) {
        .Integer => |value| subtractInteger(value.?, &right.value),
        .UnsignedInteger => |value| subtractUnsignedInteger(value.?, &right.value),
        .Float => |value| subtractFloat(value.?, &right.value),
        .Boolean => |value| subtractBoolean(value.?, &right.value),
        .Character => |value| subtractCharacter(value.?, &right.value),

        else => null,
    };

    if (result) |element| {
        return results.OperationResult{ .success = element };
    } else {
        return results.OperationResult{ .failure = try results.Signal.binaryOperationError(OPERATOR_NAME, left, right, allocator) };
    }
}

fn subtractInteger(left: i64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = left - value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Integer = left - @as(i64, @intCast(value.?)) }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) - value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Integer = left - @as(i64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Integer = left - @as(i64, @intCast(value.?)) }),

        else => null,
    };
}

fn subtractUnsignedInteger(left: u64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intCast(left)) - value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = left - value.? }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) - value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .UnsignedInteger = left - @as(u64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .UnsignedInteger = left - @as(u64, @intCast(value.?)) }),

        else => null,
    };
}

fn subtractFloat(left: f64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Float = left - @as(f64, @floatFromInt(value.?)) }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Float = left - @as(f64, @floatFromInt(value.?)) }),
        .Float => |value| results.Element.init(values.Value{ .Float = left - value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Float = left - @as(f64, @floatFromInt(@intFromBool(value.?))) }),
        .Character => |value| results.Element.init(values.Value{ .Float = left - @as(f64, @floatFromInt(value.?)) }),

        else => null,
    };
}

fn subtractBoolean(left: bool, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intFromBool(left)) - value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intFromBool(left)) - value.? }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(@intFromBool(left))) - value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intFromBool(left)) - @as(u64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Character = @as(u32, @intFromBool(left)) - value.? }),

        else => null,
    };
}

fn subtractCharacter(left: u32, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intCast(left)) - value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intCast(left)) - value.? }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) - value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Character = left - @as(u32, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Character = left - value.? }),

        else => null,
    };
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "subtract null operand checks" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var valid = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 10 },
    };
    defer operations.delete.deleteElement(&valid, allocator);

    var null_literal = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&null_literal, allocator);

    var null_optional = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = null },
    };
    defer operations.delete.deleteElement(&null_optional, allocator);

    // Left operand is null literal
    var res1 = try subtract(&null_literal, &valid, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);

    // Right operand is null literal
    var res2 = try subtract(&valid, &null_literal, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2 == .failure);

    // Left operand is null optional
    var res3 = try subtract(&null_optional, &valid, allocator);
    defer operations.delete.deleteResult(&res3, allocator);
    try std.testing.expect(res3 == .failure);

    // Right operand is null optional
    var res4 = try subtract(&valid, &null_optional, allocator);
    defer operations.delete.deleteResult(&res4, allocator);
    try std.testing.expect(res4 == .failure);
}

test "subtract unsupported left operand type fails" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "abc") },
    };
    defer operations.delete.deleteElement(&left, allocator);

    var right = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 5 },
    };
    defer operations.delete.deleteElement(&right, allocator);

    var res = try subtract(&left, &right, allocator);
    defer operations.delete.deleteResult(&res, allocator);
    try std.testing.expect(res == .failure);
}

test "subtractInteger all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 20 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Integer - Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 15), res.success.value.Integer);
    }

    // 2. Integer - UnsignedInteger -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 15), res.success.value.Integer);
    }

    // 3. Integer - Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 2.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 17.5), res.success.value.Float);
    }

    // 4. Integer - Boolean -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 19), res.success.value.Integer);
    }

    // 5. Integer - Character -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 15), res.success.value.Integer);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "subtractUnsignedInteger all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .UnsignedInteger = 30 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. UnsignedInteger - Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 10 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 20), res.success.value.Integer);
    }

    // 2. UnsignedInteger - UnsignedInteger -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 10 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 20), res.success.value.UnsignedInteger);
    }

    // 3. UnsignedInteger - Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 1.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 28.5), res.success.value.Float);
    }

    // 4. UnsignedInteger - Boolean -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 29), res.success.value.UnsignedInteger);
    }

    // 5. UnsignedInteger - Character -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 25), res.success.value.UnsignedInteger);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "subtractFloat all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Float = 15.5 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Float - Integer -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 10.5), res.success.value.Float);
    }

    // 2. Float - UnsignedInteger -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 10.5), res.success.value.Float);
    }

    // 3. Float - Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 15.0), res.success.value.Float);
    }

    // 4. Float - Boolean -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 14.5), res.success.value.Float);
    }

    // 5. Float - Character -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 10.5), res.success.value.Float);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "subtractBoolean all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Boolean = true }, // 1
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Boolean - Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, -4), res.success.value.Integer);
    }

    // 2. Boolean - UnsignedInteger -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 0), res.success.value.UnsignedInteger);
    }

    // 3. Boolean - Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 0.5), res.success.value.Float);
    }

    // 4. Boolean - Boolean -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 0), res.success.value.UnsignedInteger);
    }

    // 5. Boolean - Character -> Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 0), res.success.value.Character);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "subtractCharacter all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Character = 65 }, // 'A'
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Character - Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 60), res.success.value.Integer);
    }

    // 2. Character - UnsignedInteger -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 60), res.success.value.UnsignedInteger);
    }

    // 3. Character - Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 64.5), res.success.value.Float);
    }

    // 4. Character - Boolean -> Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } }; // 1
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 64), res.success.value.Character); // '@'
    }

    // 5. Character - Character -> Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 60), res.success.value.Character);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try subtract(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}
