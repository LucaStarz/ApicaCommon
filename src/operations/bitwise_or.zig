const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");

const OPERATOR_NAME: []const u8 = "|";

pub fn bitwiseOr(left: *const results.Element, right: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (left.value.isNull() or right.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.nullOperationError(OPERATOR_NAME, allocator) };
    }

    const result = switch (left.value) {
        .Integer => |value| bitwiseOrInteger(value.?, &right.value),
        .UnsignedInteger => |value| bitwiseOrUnsignedInteger(value.?, &right.value),
        .Float => |value| bitwiseOrFloat(value.?, &right.value),
        .Boolean => |value| bitwiseOrBoolean(value.?, &right.value),
        .Character => |value| bitwiseOrCharacter(value.?, &right.value),

        else => null,
    };

    if (result) |element| {
        return results.OperationResult{ .success = element };
    } else {
        return results.OperationResult{ .failure = try results.Signal.binaryOperationError(OPERATOR_NAME, left, right, allocator) };
    }
}

fn bitwiseOrInteger(left: i64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = left | value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Integer = left | @as(i64, @intCast(value.?)) }),
        .Float => |value| results.Element.init(values.Value{ .Integer = left | @as(i64, @intFromFloat(value.?)) }),
        .Boolean => |value| results.Element.init(values.Value{ .Integer = left | @as(i64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Integer = left | @as(i64, value.?) }),

        else => null,
    };
}

fn bitwiseOrUnsignedInteger(left: u64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intCast(left)) | value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = left | value.? }),
        .Float => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intCast(left)) | @as(i64, @intFromFloat(value.?)) }),
        .Boolean => |value| results.Element.init(values.Value{ .UnsignedInteger = left | @as(u64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .UnsignedInteger = left | @as(u64, value.?) }),

        else => null,
    };
}

fn bitwiseOrFloat(left: f64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intFromFloat(left)) | value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intFromFloat(left)) | @as(i64, @intCast(value.?)) }),
        .Float => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intFromFloat(left)) | @as(i64, @intFromFloat(value.?)) }),
        .Boolean => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intFromFloat(left)) | @as(i64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intFromFloat(left)) | @as(i64, value.?) }),

        else => null,
    };
}

fn bitwiseOrBoolean(left: bool, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intFromBool(left)) | value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intFromBool(left)) | value.? }),
        .Float => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intFromBool(left)) | @as(i64, @intFromFloat(value.?)) }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = left or value.? }),
        .Character => |value| results.Element.init(values.Value{ .Character = @as(u32, @intFromBool(left)) | value.? }),

        else => null,
    };
}

fn bitwiseOrCharacter(left: u32, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, left) | value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = @as(u64, left) | value.? }),
        .Float => |value| results.Element.init(values.Value{ .Integer = @as(i64, left) | @as(i64, @intFromFloat(value.?)) }),
        .Boolean => |value| results.Element.init(values.Value{ .Character = left | @as(u32, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Character = left | value.? }),

        else => null,
    };
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "bitwiseOr null operand checks" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var valid = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 5 },
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
    var res1 = try bitwiseOr(&null_literal, &valid, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);

    // Right operand is null literal
    var res2 = try bitwiseOr(&valid, &null_literal, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2 == .failure);

    // Left operand is null optional
    var res3 = try bitwiseOr(&null_optional, &valid, allocator);
    defer operations.delete.deleteResult(&res3, allocator);
    try std.testing.expect(res3 == .failure);

    // Right operand is null optional
    var res4 = try bitwiseOr(&valid, &null_optional, allocator);
    defer operations.delete.deleteResult(&res4, allocator);
    try std.testing.expect(res4 == .failure);
}

test "bitwiseOr unsupported left operand type fails" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "text") },
    };
    defer operations.delete.deleteElement(&left, allocator);

    var right = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 5 },
    };
    defer operations.delete.deleteElement(&right, allocator);

    var res = try bitwiseOr(&left, &right, allocator);
    defer operations.delete.deleteResult(&res, allocator);
    try std.testing.expect(res == .failure);
}

test "bitwiseOrInteger all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 0b1000 }, // 8
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Integer | Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0b0011 } }; // 3
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1011), res.success.value.Integer);
    }

    // 2. Integer | UnsignedInteger -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 0b0100 } }; // 4
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1100), res.success.value.Integer);
    }

    // 3. Integer | Float -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 3.9 } }; // truncated to 3 (0b0011)
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1011), res.success.value.Integer);
    }

    // 4. Integer | Boolean -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } }; // 1
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1001), res.success.value.Integer);
    }

    // 5. Integer | Character -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0b0110 } }; // 6
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1110), res.success.value.Integer);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "bitwiseOrUnsignedInteger all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .UnsignedInteger = 0b1000 }, // 8
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. UnsignedInteger | Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0b0011 } }; // 3
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1011), res.success.value.Integer);
    }

    // 2. UnsignedInteger | UnsignedInteger -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 0b0100 } }; // 4
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 0b1100), res.success.value.UnsignedInteger);
    }

    // 3. UnsignedInteger | Float -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 3.2 } }; // truncated to 3 (0b0011)
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1011), res.success.value.Integer);
    }

    // 4. UnsignedInteger | Boolean -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } }; // 1
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 0b1001), res.success.value.UnsignedInteger);
    }

    // 5. UnsignedInteger | Character -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0b0110 } }; // 6
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 0b1110), res.success.value.UnsignedInteger);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "bitwiseOrFloat all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Float = 8.7 }, // truncated to 8 (0b1000)
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Float | Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0b0011 } }; // 3
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1011), res.success.value.Integer);
    }

    // 2. Float | UnsignedInteger -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 0b0100 } }; // 4
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1100), res.success.value.Integer);
    }

    // 3. Float | Float -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 3.1 } }; // truncated to 3 (0b0011)
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1011), res.success.value.Integer);
    }

    // 4. Float | Boolean -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } }; // 1
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1001), res.success.value.Integer);
    }

    // 5. Float | Character -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0b0110 } }; // 6
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1110), res.success.value.Integer);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "bitwiseOrBoolean all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Boolean = false }, // 0
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Boolean | Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 8 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 8), res.success.value.Integer);
    }

    // 2. Boolean | UnsignedInteger -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 6 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 6), res.success.value.UnsignedInteger);
    }

    // 3. Boolean | Float -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 4.8 } }; // truncated to 4
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 4), res.success.value.Integer);
    }

    // 4. Boolean | Boolean -> Boolean
    {
        // false or false -> false
        var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&right_false, allocator);
        var res_ff = try bitwiseOr(&left, &right_false, allocator);
        defer operations.delete.deleteResult(&res_ff, allocator);
        try std.testing.expectEqual(@as(?bool, false), res_ff.success.value.Boolean);

        // false or true -> true
        var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right_true, allocator);
        var res_ft = try bitwiseOr(&left, &right_true, allocator);
        defer operations.delete.deleteResult(&res_ft, allocator);
        try std.testing.expectEqual(@as(?bool, true), res_ft.success.value.Boolean);

        // true or false -> true
        var left_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&left_true, allocator);
        var res_tf = try bitwiseOr(&left_true, &right_false, allocator);
        defer operations.delete.deleteResult(&res_tf, allocator);
        try std.testing.expectEqual(@as(?bool, true), res_tf.success.value.Boolean);
    }

    // 5. Boolean | Character -> Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 64 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 64), res.success.value.Character);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "bitwiseOrCharacter all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Character = 0b1000 }, // 8
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Character | Integer -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0b0011 } }; // 3
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1011), res.success.value.Integer);
    }

    // 2. Character | UnsignedInteger -> UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 0b0100 } }; // 4
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u64, 0b1100), res.success.value.UnsignedInteger);
    }

    // 3. Character | Float -> Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 3.6 } }; // truncated to 3 (0b0011)
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 0b1011), res.success.value.Integer);
    }

    // 4. Character | Boolean -> Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } }; // 1
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 0b1001), res.success.value.Character);
    }

    // 5. Character | Character -> Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0b0110 } }; // 6
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 0b1110), res.success.value.Character);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try bitwiseOr(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}
