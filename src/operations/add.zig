const std = @import("std");
const repr = @import("../operations.zig").repr;
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");

const OPERATOR_NAME: []const u8 = "+";

pub fn add(left: *const results.Element, right: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (left.value.isNull() or right.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.nullOperationError(OPERATOR_NAME, allocator) };
    }

    const result = switch (left.value) {
        .Integer => |value| addInteger(value.?, &right.value),
        .UnsignedInteger => |value| addUnsignedInteger(value.?, &right.value),
        .Float => |value| addFloat(value.?, &right.value),
        .Boolean => |value| addBoolean(value.?, &right.value),
        .Character => |value| addCharacter(value.?, &right.value),
        .String => |value| try addString(value.?, right, allocator),

        else => null,
    };

    if (result) |element| {
        return results.OperationResult{ .success = element };
    } else {
        return results.OperationResult{ .failure = try results.Signal.binaryOperationError(OPERATOR_NAME, left, right, allocator) };
    }
}

fn addInteger(left: i64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = left + value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Integer = left + @as(i64, @intCast(value.?)) }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) + value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Integer = left + @as(i64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Integer = left + @as(i64, @intCast(value.?)) }),

        else => null,
    };
}

fn addUnsignedInteger(left: u64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intCast(left)) + value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = left + value.? }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) + value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .UnsignedInteger = left + @as(u64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .UnsignedInteger = left + @as(u64, @intCast(value.?)) }),

        else => null,
    };
}

fn addFloat(left: f64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Float = left + @as(f64, @floatFromInt(value.?)) }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Float = left + @as(f64, @floatFromInt(value.?)) }),
        .Float => |value| results.Element.init(values.Value{ .Float = left + value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Float = left + @as(f64, @floatFromInt(@intFromBool(value.?))) }),
        .Character => |value| results.Element.init(values.Value{ .Float = left + @as(f64, @floatFromInt(value.?)) }),

        else => null,
    };
}

fn addBoolean(left: bool, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intFromBool(left)) + value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intFromBool(left)) + value.? }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(@intFromBool(left))) + value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intFromBool(left)) + @as(u64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Character = @as(u32, @intFromBool(left)) + value.? }),

        else => null,
    };
}

fn addCharacter(left: u32, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intCast(left)) + value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intCast(left)) + value.? }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) + value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Character = left + @as(u32, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Character = left + value.? }),

        else => null,
    };
}

fn addString(left: []const u8, right: *const results.Element, allocator: std.mem.Allocator) InternalError!?results.Element {
    const text = try repr(right, allocator);
    defer allocator.free(text);

    const string = allocator.print("{s}{s}", .{ left, text }) catch return InternalError.OutOfMemory;
    return results.Element.init(values.Value{ .String = string });
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "add null checks" {
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
    var res1 = try add(&null_literal, &valid, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);

    // Right operand is null literal
    var res2 = try add(&valid, &null_literal, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2 == .failure);

    // Left operand is null optional
    var res3 = try add(&null_optional, &valid, allocator);
    defer operations.delete.deleteResult(&res3, allocator);
    try std.testing.expect(res3 == .failure);

    // Right operand is null optional
    var res4 = try add(&valid, &null_optional, allocator);
    defer operations.delete.deleteResult(&res4, allocator);
    try std.testing.expect(res4 == .failure);
}

test "add unsupported left operand type fails" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

    const left_type = try allocator.create(values.TypeValue);
    left_type.* = values.TypeValue{
        .kind = TypeBytecode.Int,
        .is_nullable = false,
        .contained = std.ArrayList(values.TypeValue).empty,
    };
    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Type = left_type },
    };
    defer operations.delete.deleteElement(&left, allocator);

    var right = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 5 },
    };
    defer operations.delete.deleteElement(&right, allocator);

    var res = try add(&left, &right, allocator);
    defer operations.delete.deleteResult(&res, allocator);
    try std.testing.expect(res == .failure);
}

test "addInteger all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 10 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Integer + Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 15), res.success.value.Integer);
    }

    // 2. Integer + UnsignedInteger -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 15), res.success.value.Integer);
    }

    // 3. Integer + Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 2.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 12.5), res.success.value.Float);
    }

    // 4. Integer + Boolean -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 11), res.success.value.Integer);
    }

    // 5. Integer + Character -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 15), res.success.value.Integer);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "addUnsignedInteger all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .UnsignedInteger = 20 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. UnsignedInteger + Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = -5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 15), res.success.value.Integer);
    }

    // 2. UnsignedInteger + UnsignedInteger -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 10 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 30), res.success.value.UnsignedInteger);
    }

    // 3. UnsignedInteger + Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 1.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 21.5), res.success.value.Float);
    }

    // 4. UnsignedInteger + Boolean -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 21), res.success.value.UnsignedInteger);
    }

    // 5. UnsignedInteger + Character -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 4 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 24), res.success.value.UnsignedInteger);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "addFloat all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Float = 10.5 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Float + Integer -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 2 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 12.5), res.success.value.Float);
    }

    // 2. Float + UnsignedInteger -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 3 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 13.5), res.success.value.Float);
    }

    // 3. Float + Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 11.0), res.success.value.Float);
    }

    // 4. Float + Boolean -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 11.5), res.success.value.Float);
    }

    // 5. Float + Character -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 11.5), res.success.value.Float);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "addBoolean all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Boolean = true },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Boolean + Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 10 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 11), res.success.value.Integer);
    }

    // 2. Boolean + UnsignedInteger -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 6), res.success.value.UnsignedInteger);
    }

    // 3. Boolean + Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 2.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 3.5), res.success.value.Float);
    }

    // 4. Boolean + Boolean -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 2), res.success.value.UnsignedInteger);
    }

    // 5. Boolean + Character -> Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 65 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 66), res.success.value.Character);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "addCharacter all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Character = 65 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Character + Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 2 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 67), res.success.value.Integer);
    }

    // 2. Character + UnsignedInteger -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 3 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 68), res.success.value.UnsignedInteger);
    }

    // 3. Character + Float -> Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 65.5), res.success.value.Float);
    }

    // 4. Character + Boolean -> Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 66), res.success.value.Character);
    }

    // 5. Character + Character -> Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 66), res.success.value.Character);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "addString concatenation with various types" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "Hello, ") },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // String + String
    {
        var right = results.Element{
            .modifier = results.ElementModifier{},
            .value = values.Value{ .String = try allocator.dupe(u8, "world!") },
        };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .success);
        try std.testing.expectEqualStrings("Hello, world!", res.success.value.String.?);
    }

    // String + Integer
    {
        var right = results.Element{
            .modifier = results.ElementModifier{},
            .value = values.Value{ .Integer = 42 },
        };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try add(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .success);
        try std.testing.expectEqualStrings("Hello, 42", res.success.value.String.?);
    }
}
