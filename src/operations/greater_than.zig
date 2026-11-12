const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");

const OPERATOR_NAME: []const u8 = ">";

pub fn greaterThan(left: *const results.Element, right: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (left.value.isNull() or right.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.nullOperationError(OPERATOR_NAME, allocator) };
    }

    const result = switch (left.value) {
        .Integer => |value| greaterThanInteger(value.?, &right.value),
        .UnsignedInteger => |value| greaterThanUnsignedInteger(value.?, &right.value),
        .Float => |value| greaterThanFloat(value.?, &right.value),
        .Boolean => |value| greaterThanBoolean(value.?, &right.value),
        .Character => |value| greaterThanCharacter(value.?, &right.value),

        else => null,
    };

    if (result) |element| {
        return results.OperationResult{ .success = element };
    } else {
        return results.OperationResult{ .failure = try results.Signal.binaryOperationError(OPERATOR_NAME, left, right, allocator) };
    }
}

fn greaterThanInteger(left: i64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Boolean = left > value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = left > value.? }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = @as(f64, @floatFromInt(left)) > value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = left > @as(i64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = left > value.? }),

        else => null,
    };
}

fn greaterThanUnsignedInteger(left: u64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Boolean = left > value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = left > value.? }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = @as(f64, @floatFromInt(left)) > value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = left > @as(u64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = left > value.? }),

        else => null,
    };
}

fn greaterThanFloat(left: f64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Boolean = left > @as(f64, @floatFromInt(value.?)) }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = left > @as(f64, @floatFromInt(value.?)) }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = left > value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = left > @as(f64, @floatFromInt(@intFromBool(value.?))) }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = left > @as(f64, @floatFromInt(value.?)) }),

        else => null,
    };
}

fn greaterThanBoolean(left: bool, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Boolean = @as(i64, @intFromBool(left)) > value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = @as(u64, @intFromBool(left)) > value.? }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = @as(f64, @floatFromInt(@intFromBool(left))) > value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = @as(i64, @intFromBool(left)) > @as(i64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = @as(u32, @intFromBool(left)) > value.? }),

        else => null,
    };
}

fn greaterThanCharacter(left: u32, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Boolean = left > value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = left > value.? }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = @as(f64, @floatFromInt(left)) > value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = left > @as(u32, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = left > value.? }),

        else => null,
    };
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "greaterThan null operand checks" {
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
    var res1 = try greaterThan(&null_literal, &valid, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);

    // Right operand is null literal
    var res2 = try greaterThan(&valid, &null_literal, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2 == .failure);

    // Left operand is null optional
    var res3 = try greaterThan(&null_optional, &valid, allocator);
    defer operations.delete.deleteResult(&res3, allocator);
    try std.testing.expect(res3 == .failure);

    // Right operand is null optional
    var res4 = try greaterThan(&valid, &null_optional, allocator);
    defer operations.delete.deleteResult(&res4, allocator);
    try std.testing.expect(res4 == .failure);
}

test "greaterThan unsupported left operand type fails" {
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

    var res = try greaterThan(&left, &right, allocator);
    defer operations.delete.deleteResult(&res, allocator);
    try std.testing.expect(res == .failure);
}

test "greaterThanInteger all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 10 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Integer > Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 10 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 2. Integer > UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 3. Integer > Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 10.1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 4. Integer > Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 5. Integer > Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 65 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "greaterThanUnsignedInteger all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .UnsignedInteger = 20 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. UnsignedInteger > Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 20 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 2. UnsignedInteger > UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 15 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 3. UnsignedInteger > Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 20.0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 4. UnsignedInteger > Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 5. UnsignedInteger > Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 30 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "greaterThanFloat all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Float = 15.5 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Float > Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 15 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. Float > UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 16 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 3. Float > Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 15.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 4. Float > Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 5. Float > Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 65 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "greaterThanBoolean all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Boolean = true }, // 1
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Boolean > Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. Boolean > UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 3. Boolean > Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 4. Boolean > Boolean
    {
        // true > false -> true
        var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&right_false, allocator);
        var res_tf = try greaterThan(&left, &right_false, allocator);
        defer operations.delete.deleteResult(&res_tf, allocator);
        try std.testing.expectEqual(@as(?bool, true), res_tf.success.value.Boolean);

        // false > true -> false
        var left_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&left_false, allocator);
        var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right_true, allocator);
        var res_ft = try greaterThan(&left_false, &right_true, allocator);
        defer operations.delete.deleteResult(&res_ft, allocator);
        try std.testing.expectEqual(@as(?bool, false), res_ft.success.value.Boolean);
    }

    // 5. Boolean > Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "greaterThanCharacter all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Character = 65 }, // 'A'
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Character > Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 64 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. Character > UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 65 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 3. Character > Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 64.9 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 4. Character > Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } }; // 1
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 5. Character > Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 65 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try greaterThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}
