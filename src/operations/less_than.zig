const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");

const OPERATOR_NAME: []const u8 = "<";

pub fn lessThan(left: *const results.Element, right: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (left.value.isNull() or right.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.nullOperationError(OPERATOR_NAME, allocator) };
    }

    const result = switch (left.value) {
        .Integer => |value| lessThanInteger(value.?, &right.value),
        .UnsignedInteger => |value| lessThanUnsignedInteger(value.?, &right.value),
        .Float => |value| lessThanFloat(value.?, &right.value),
        .Boolean => |value| lessThanBoolean(value.?, &right.value),
        .Character => |value| lessThanCharacter(value.?, &right.value),

        else => null,
    };

    if (result) |element| {
        return results.OperationResult{ .success = element };
    } else {
        return results.OperationResult{ .failure = try results.Signal.binaryOperationError(OPERATOR_NAME, left, right, allocator) };
    }
}

fn lessThanInteger(left: i64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Boolean = left < value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = left < value.? }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = @as(f64, @floatFromInt(left)) < value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = left < @as(i64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = left < value.? }),

        else => null,
    };
}

fn lessThanUnsignedInteger(left: u64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Boolean = left < value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = left < value.? }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = @as(f64, @floatFromInt(left)) < value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = left < @as(u64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = left < value.? }),

        else => null,
    };
}

fn lessThanFloat(left: f64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Boolean = left < @as(f64, @floatFromInt(value.?)) }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = left < @as(f64, @floatFromInt(value.?)) }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = left < value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = left < @as(f64, @floatFromInt(@intFromBool(value.?))) }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = left < @as(f64, @floatFromInt(value.?)) }),

        else => null,
    };
}

fn lessThanBoolean(left: bool, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Boolean = @as(i64, @intFromBool(left)) < value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = @as(u64, @intFromBool(left)) < value.? }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = @as(f64, @floatFromInt(@intFromBool(left))) < value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = @as(i64, @intFromBool(left)) < @as(i64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = @as(u32, @intFromBool(left)) < value.? }),

        else => null,
    };
}

fn lessThanCharacter(left: u32, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Boolean = left < value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = left < value.? }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = @as(f64, @floatFromInt(left)) < value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = left < @as(u32, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = left < value.? }),

        else => null,
    };
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "lessThan null operand checks" {
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
    var res1 = try lessThan(&null_literal, &valid, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);

    // Right operand is null literal
    var res2 = try lessThan(&valid, &null_literal, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2 == .failure);

    // Left operand is null optional
    var res3 = try lessThan(&null_optional, &valid, allocator);
    defer operations.delete.deleteResult(&res3, allocator);
    try std.testing.expect(res3 == .failure);

    // Right operand is null optional
    var res4 = try lessThan(&valid, &null_optional, allocator);
    defer operations.delete.deleteResult(&res4, allocator);
    try std.testing.expect(res4 == .failure);
}

test "lessThan unsupported left operand type fails" {
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

    var res = try lessThan(&left, &right, allocator);
    defer operations.delete.deleteResult(&res, allocator);
    try std.testing.expect(res == .failure);
}

test "lessThanInteger all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 10 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Integer < Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 10 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 2. Integer < UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 15 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 3. Integer < Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 9.9 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 4. Integer < Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 5. Integer < Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 65 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "lessThanUnsignedInteger all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .UnsignedInteger = 20 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. UnsignedInteger < Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 25 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. UnsignedInteger < UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 20 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 3. UnsignedInteger < Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 20.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 4. UnsignedInteger < Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 5. UnsignedInteger < Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 30 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "lessThanFloat all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Float = 15.5 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Float < Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 16 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. Float < UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 15 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 3. Float < Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 15.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 4. Float < Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 5. Float < Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 65 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "lessThanBoolean all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Boolean = false }, // 0
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Boolean < Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. Boolean < UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 3. Boolean < Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 0.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 4. Boolean < Boolean
    {
        // false < true -> true
        var right_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right_true, allocator);
        var res_ft = try lessThan(&left, &right_true, allocator);
        defer operations.delete.deleteResult(&res_ft, allocator);
        try std.testing.expectEqual(@as(?bool, true), res_ft.success.value.Boolean);

        // true < false -> false
        var left_true = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&left_true, allocator);
        var right_false = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&right_false, allocator);
        var res_tf = try lessThan(&left_true, &right_false, allocator);
        defer operations.delete.deleteResult(&res_tf, allocator);
        try std.testing.expectEqual(@as(?bool, false), res_tf.success.value.Boolean);
    }

    // 5. Boolean < Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "lessThanCharacter all combinations and unsupported right operand" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Character = 65 }, // 'A'
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Character < Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 66 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 2. Character < UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 65 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 3. Character < Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 65.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 4. Character < Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } }; // 1
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, false), res.success.value.Boolean);
    }

    // 5. Character < Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 66 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?bool, true), res.success.value.Boolean);
    }

    // 6. Incompatible right operand (String) -> failure
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "abc") } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try lessThan(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}
