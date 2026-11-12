const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");
const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

const OPERATOR_NAME: []const u8 = "=";

pub fn assign(left: *results.Element, right: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (left.modifier.NOT_NULLABLE and right.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.notNullableOperationError(allocator) };
    }

    const result = switch (left.value) {
        .Null => null,
        .Integer => |*value| assignInteger(value, &right.value),
        .UnsignedInteger => |*value| assignUnsignedInteger(value, &right.value),
        .Float => |*value| assignFloat(value, &right.value),
        .Boolean => |*value| assignBoolean(value, &right.value),
        .Character => |*value| assignCharacter(value, &right.value),
        .String => |*value| try assignString(value, &right.value, allocator),
        .Error => |value| try assignError(value, &right.value, allocator),
        .Type => |value| try assignType(value, &right.value, allocator),
        .Reference => |value| try assignReference(value, &right.value, allocator),
        .List => |value| try assignList(value, &right.value, allocator),
    };

    if (result) |element| {
        return results.OperationResult{ .success = element };
    } else {
        return results.OperationResult{ .failure = try results.Signal.binaryOperationError(OPERATOR_NAME, left, right, allocator) };
    }
}

fn assignInteger(left: *?i64, right: *const values.Value) ?results.Element {
    switch (right.*) {
        .Null => left.* = null,
        .Integer => |value| left.* = value,
        .UnsignedInteger => |value| left.* = if (value) |v| @intCast(v) else null,
        .Float => |value| left.* = if (value) |v| @intFromFloat(v) else null,
        .Boolean => |value| left.* = if (value) |v| @intFromBool(v) else null,
        .Character => |value| left.* = if (value) |v| @intCast(v) else null,
        else => return null,
    }

    return results.Element.init(values.Value{ .Integer = left.* });
}

fn assignUnsignedInteger(left: *?u64, right: *const values.Value) ?results.Element {
    switch (right.*) {
        .Null => left.* = null,
        .Integer => |value| left.* = if (value) |v| @intCast(v) else null,
        .UnsignedInteger => |value| left.* = value,
        .Float => |value| left.* = if (value) |v| @intFromFloat(v) else null,
        .Boolean => |value| left.* = if (value) |v| @intFromBool(v) else null,
        .Character => |value| left.* = if (value) |v| @intCast(v) else null,
        else => return null,
    }

    return results.Element.init(values.Value{ .UnsignedInteger = left.* });
}

fn assignFloat(left: *?f64, right: *const values.Value) ?results.Element {
    switch (right.*) {
        .Null => left.* = null,
        .Integer => |value| left.* = if (value) |v| @floatFromInt(v) else null,
        .UnsignedInteger => |value| left.* = if (value) |v| @floatFromInt(v) else null,
        .Float => |value| left.* = value,
        .Boolean => |value| left.* = if (value) |v| @floatFromInt(@intFromBool(v)) else null,
        .Character => |value| left.* = if (value) |v| @floatFromInt(v) else null,
        else => return null,
    }

    return results.Element.init(values.Value{ .Float = left.* });
}

fn assignBoolean(left: *?bool, right: *const values.Value) ?results.Element {
    switch (right.*) {
        .Null => left.* = null,
        .Integer => |value| left.* = if (value) |v| v != 0 else null,
        .UnsignedInteger => |value| left.* = if (value) |v| v != 0 else null,
        .Float => |value| left.* = if (value) |v| v != 0.0 else null,
        .Boolean => |value| left.* = value,
        .Character => |value| left.* = if (value) |v| v != 0 else null,
        else => return null,
    }

    return results.Element.init(values.Value{ .Boolean = left.* });
}

fn assignCharacter(left: *?u32, right: *const values.Value) ?results.Element {
    switch (right.*) {
        .Null => left.* = null,
        .Integer => |value| left.* = if (value) |v| @intCast(v) else null,
        .UnsignedInteger => |value| left.* = if (value) |v| @intCast(v) else null,
        .Float => |value| left.* = if (value) |v| @intFromFloat(v) else null,
        .Boolean => |value| left.* = if (value) |v| @intFromBool(v) else null,
        .Character => |value| left.* = value,
        else => return null,
    }

    return results.Element.init(values.Value{ .Character = left.* });
}

fn assignString(left: *?[]const u8, right: *const values.Value, allocator: std.mem.Allocator) InternalError!?results.Element {
    switch (right.*) {
        .Null => {
            if (left.*) |data| allocator.free(data);
            left.* = null;
        },
        .String => |value| {
            if (left.*) |data| allocator.free(data);
            if (value) |v| {
                left.* = allocator.dupe(u8, v) catch return InternalError.OutOfMemory;
            } else {
                left.* = null;
            }
        },
        else => return null,
    }

    return results.Element.init(values.Value{ .String = if (left.*) |string| allocator.dupe(u8, string) catch return InternalError.OutOfMemory else null });
}

fn assignError(left: *values.ErrorValue, right: *const values.Value, allocator: std.mem.Allocator) InternalError!?results.Element {
    switch (right.*) {
        .Null => {
            left.deinit(allocator);
            left.* = values.ErrorValue{
                .name = null,
                .details = null,
                .stack_trace = .empty,
            };
        },
        .Error => |value| {
            const cloned = try value.clone(allocator);
            left.deinit(allocator);
            left.* = cloned;
        },
        else => return null,
    }

    const copy = allocator.create(values.ErrorValue) catch return InternalError.OutOfMemory;
    errdefer allocator.destroy(copy);

    copy.* = try left.clone(allocator);
    return results.Element.init(values.Value{ .Error = copy });
}

fn assignType(left: *values.TypeValue, right: *const values.Value, allocator: std.mem.Allocator) InternalError!?results.Element {
    switch (right.*) {
        .Type => |value| {
            const cloned = try value.clone(allocator);
            left.deinit(allocator);
            left.* = cloned;
        },
        else => return null,
    }

    const copy = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
    errdefer allocator.destroy(copy);

    copy.* = try left.clone(allocator);
    return results.Element.init(values.Value{ .Type = copy });
}

fn assignReference(left: *values.ReferenceValue, right: *const values.Value, allocator: std.mem.Allocator) InternalError!?results.Element {
    switch (right.*) {
        .Null => {
            left.index = null;
        },
        .Reference => |value| {
            if (!left.type.canCollect(&value.type)) {
                return null;
            }
            left.index = value.index;
        },
        else => return null,
    }

    const copy = allocator.create(values.ReferenceValue) catch return InternalError.OutOfMemory;
    errdefer allocator.destroy(copy);

    copy.* = try left.clone(allocator);
    return results.Element.init(values.Value{ .Reference = copy });
}

fn assignList(left: *values.ListValue, right: *const values.Value, allocator: std.mem.Allocator) InternalError!?results.Element {
    switch (right.*) {
        .Null => {
            if (left.items) |*items| {
                for (items.items) |*item| {
                    item.deinit(allocator);
                }
                items.deinit(allocator);
                left.items = null;
            }
        },
        .List => |value| {
            if (!left.type.canCollect(&value.type)) {
                return null;
            }

            const cloned = try value.clone(allocator);
            left.deinit(allocator);
            left.* = cloned;
        },
        else => return null,
    }

    const copy = allocator.create(values.ListValue) catch return InternalError.OutOfMemory;
    errdefer allocator.destroy(copy);

    copy.* = try left.clone(allocator);
    return results.Element.init(values.Value{ .List = copy });
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "assign modifier NOT_NULLABLE rejects null right value" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{ .NOT_NULLABLE = true },
        .value = values.Value{ .Integer = 10 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    var right = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&right, allocator);

    var res = try assign(&left, &right, allocator);
    defer operations.delete.deleteResult(&res, allocator);

    try std.testing.expect(res == .failure);
}

test "assign with left value Null fails" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&left, allocator);

    var right = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 42 },
    };
    defer operations.delete.deleteElement(&right, allocator);

    var res = try assign(&left, &right, allocator);
    defer operations.delete.deleteResult(&res, allocator);

    try std.testing.expect(res == .failure);
}

test "assign Integer all conversions, null, and incompatible" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 0 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    const test_cases = [_]struct { val: values.Value, expected: ?i64 }{
        .{ .val = values.Value{ .Integer = 42 }, .expected = 42 },
        .{ .val = values.Value{ .UnsignedInteger = 100 }, .expected = 100 },
        .{ .val = values.Value{ .Float = 3.9 }, .expected = 3 },
        .{ .val = values.Value{ .Boolean = true }, .expected = 1 },
        .{ .val = values.Value{ .Character = 65 }, .expected = 65 },
        .{ .val = values.Value{ .Null = {} }, .expected = null },
        .{ .val = values.Value{ .Integer = null }, .expected = null },
        .{ .val = values.Value{ .UnsignedInteger = null }, .expected = null },
        .{ .val = values.Value{ .Float = null }, .expected = null },
        .{ .val = values.Value{ .Boolean = null }, .expected = null },
        .{ .val = values.Value{ .Character = null }, .expected = null },
    };

    for (test_cases) |tc| {
        var right = results.Element{ .modifier = results.ElementModifier{}, .value = tc.val };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try assign(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .success);
        try std.testing.expectEqual(tc.expected, res.success.value.Integer);
        try std.testing.expectEqual(tc.expected, left.value.Integer);
    }

    // Incompatible: String -> Integer
    var right_incompatible = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "abc") },
    };
    defer operations.delete.deleteElement(&right_incompatible, allocator);

    var res_fail = try assign(&left, &right_incompatible, allocator);
    defer operations.delete.deleteResult(&res_fail, allocator);
    try std.testing.expect(res_fail == .failure);
}

test "assign UnsignedInteger all conversions, null, and incompatible" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .UnsignedInteger = 0 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    const test_cases = [_]struct { val: values.Value, expected: ?u64 }{
        .{ .val = values.Value{ .UnsignedInteger = 42 }, .expected = 42 },
        .{ .val = values.Value{ .Integer = 100 }, .expected = 100 },
        .{ .val = values.Value{ .Float = 4.2 }, .expected = 4 },
        .{ .val = values.Value{ .Boolean = true }, .expected = 1 },
        .{ .val = values.Value{ .Character = 66 }, .expected = 66 },
        .{ .val = values.Value{ .Null = {} }, .expected = null },
        .{ .val = values.Value{ .Integer = null }, .expected = null },
        .{ .val = values.Value{ .UnsignedInteger = null }, .expected = null },
        .{ .val = values.Value{ .Float = null }, .expected = null },
        .{ .val = values.Value{ .Boolean = null }, .expected = null },
        .{ .val = values.Value{ .Character = null }, .expected = null },
    };

    for (test_cases) |tc| {
        var right = results.Element{ .modifier = results.ElementModifier{}, .value = tc.val };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try assign(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .success);
        try std.testing.expectEqual(tc.expected, res.success.value.UnsignedInteger);
    }

    // Incompatible: String -> UnsignedInteger
    var right_incompatible = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "abc") },
    };
    defer operations.delete.deleteElement(&right_incompatible, allocator);

    var res_fail = try assign(&left, &right_incompatible, allocator);
    defer operations.delete.deleteResult(&res_fail, allocator);
    try std.testing.expect(res_fail == .failure);
}

test "assign Float all conversions, null, and incompatible" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Float = 0.0 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    const test_cases = [_]struct { val: values.Value, expected: ?f64 }{
        .{ .val = values.Value{ .Float = 12.5 }, .expected = 12.5 },
        .{ .val = values.Value{ .Integer = -10 }, .expected = -10.0 },
        .{ .val = values.Value{ .UnsignedInteger = 50 }, .expected = 50.0 },
        .{ .val = values.Value{ .Boolean = true }, .expected = 1.0 },
        .{ .val = values.Value{ .Character = 65 }, .expected = 65.0 },
        .{ .val = values.Value{ .Null = {} }, .expected = null },
        .{ .val = values.Value{ .Integer = null }, .expected = null },
        .{ .val = values.Value{ .UnsignedInteger = null }, .expected = null },
        .{ .val = values.Value{ .Float = null }, .expected = null },
        .{ .val = values.Value{ .Boolean = null }, .expected = null },
        .{ .val = values.Value{ .Character = null }, .expected = null },
    };

    for (test_cases) |tc| {
        var right = results.Element{ .modifier = results.ElementModifier{}, .value = tc.val };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try assign(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .success);
        try std.testing.expectEqual(tc.expected, res.success.value.Float);
    }

    // Incompatible: String -> Float
    var right_incompatible = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "abc") },
    };
    defer operations.delete.deleteElement(&right_incompatible, allocator);

    var res_fail = try assign(&left, &right_incompatible, allocator);
    defer operations.delete.deleteResult(&res_fail, allocator);
    try std.testing.expect(res_fail == .failure);
}

test "assign Boolean all conversions, null, and incompatible" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Boolean = false },
    };
    defer operations.delete.deleteElement(&left, allocator);

    const test_cases = [_]struct { val: values.Value, expected: ?bool }{
        .{ .val = values.Value{ .Boolean = true }, .expected = true },
        .{ .val = values.Value{ .Integer = 5 }, .expected = true },
        .{ .val = values.Value{ .Integer = 0 }, .expected = false },
        .{ .val = values.Value{ .UnsignedInteger = 10 }, .expected = true },
        .{ .val = values.Value{ .UnsignedInteger = 0 }, .expected = false },
        .{ .val = values.Value{ .Float = 0.5 }, .expected = true },
        .{ .val = values.Value{ .Float = 0.0 }, .expected = false },
        .{ .val = values.Value{ .Character = 'A' }, .expected = true },
        .{ .val = values.Value{ .Character = 0 }, .expected = false },
        .{ .val = values.Value{ .Null = {} }, .expected = null },
        .{ .val = values.Value{ .Integer = null }, .expected = null },
        .{ .val = values.Value{ .UnsignedInteger = null }, .expected = null },
        .{ .val = values.Value{ .Float = null }, .expected = null },
        .{ .val = values.Value{ .Boolean = null }, .expected = null },
        .{ .val = values.Value{ .Character = null }, .expected = null },
    };

    for (test_cases) |tc| {
        var right = results.Element{ .modifier = results.ElementModifier{}, .value = tc.val };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try assign(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .success);
        try std.testing.expectEqual(tc.expected, res.success.value.Boolean);
    }

    // Incompatible: String -> Boolean
    var right_incompatible = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "abc") },
    };
    defer operations.delete.deleteElement(&right_incompatible, allocator);

    var res_fail = try assign(&left, &right_incompatible, allocator);
    defer operations.delete.deleteResult(&res_fail, allocator);
    try std.testing.expect(res_fail == .failure);
}

test "assign Character all conversions, null, and incompatible" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Character = 0 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    const test_cases = [_]struct { val: values.Value, expected: ?u32 }{
        .{ .val = values.Value{ .Character = 'X' }, .expected = 'X' },
        .{ .val = values.Value{ .Integer = 65 }, .expected = 65 },
        .{ .val = values.Value{ .UnsignedInteger = 66 }, .expected = 66 },
        .{ .val = values.Value{ .Float = 67.8 }, .expected = 67 },
        .{ .val = values.Value{ .Boolean = true }, .expected = 1 },
        .{ .val = values.Value{ .Null = {} }, .expected = null },
        .{ .val = values.Value{ .Integer = null }, .expected = null },
        .{ .val = values.Value{ .UnsignedInteger = null }, .expected = null },
        .{ .val = values.Value{ .Float = null }, .expected = null },
        .{ .val = values.Value{ .Boolean = null }, .expected = null },
        .{ .val = values.Value{ .Character = null }, .expected = null },
    };

    for (test_cases) |tc| {
        var right = results.Element{ .modifier = results.ElementModifier{}, .value = tc.val };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try assign(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .success);
        try std.testing.expectEqual(tc.expected, res.success.value.Character);
    }

    // Incompatible: String -> Character
    var right_incompatible = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "abc") },
    };
    defer operations.delete.deleteElement(&right_incompatible, allocator);

    var res_fail = try assign(&left, &right_incompatible, allocator);
    defer operations.delete.deleteResult(&res_fail, allocator);
    try std.testing.expect(res_fail == .failure);
}

test "assign String value, null string, Null literal, and incompatible" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "initial") },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Assign another valid string
    var right1 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "updated") },
    };
    defer operations.delete.deleteElement(&right1, allocator);

    var res1 = try assign(&left, &right1, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expectEqualStrings("updated", res1.success.value.String.?);
    try std.testing.expectEqualStrings("updated", left.value.String.?);

    // 2. Assign String null
    var right2 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = null },
    };
    defer operations.delete.deleteElement(&right2, allocator);

    var res2 = try assign(&left, &right2, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2.success.value.String == null);
    try std.testing.expect(left.value.String == null);

    // 3. Assign from Null literal
    left.value.String = try allocator.dupe(u8, "temp");
    var right3 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&right3, allocator);

    var res3 = try assign(&left, &right3, allocator);
    defer operations.delete.deleteResult(&res3, allocator);
    try std.testing.expect(res3.success.value.String == null);
    try std.testing.expect(left.value.String == null);

    // 4. Incompatible: Integer -> String
    var right_incompatible = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 123 },
    };
    defer operations.delete.deleteElement(&right_incompatible, allocator);

    var res_fail = try assign(&left, &right_incompatible, allocator);
    defer operations.delete.deleteResult(&res_fail, allocator);
    try std.testing.expect(res_fail == .failure);
}

test "assign Error value, Null literal, and incompatible" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    const left_err = try allocator.create(values.ErrorValue);
    left_err.* = values.ErrorValue{
        .name = try allocator.dupe(u8, "ErrA"),
        .details = try allocator.dupe(u8, "DetailA"),
        .stack_trace = std.ArrayList([]const u8).empty,
    };
    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Error = left_err },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Assign another Error
    const right_err = try allocator.create(values.ErrorValue);
    right_err.* = values.ErrorValue{
        .name = try allocator.dupe(u8, "ErrB"),
        .details = try allocator.dupe(u8, "DetailB"),
        .stack_trace = std.ArrayList([]const u8).empty,
    };
    var right = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Error = right_err },
    };
    defer operations.delete.deleteElement(&right, allocator);

    var res1 = try assign(&left, &right, allocator);
    defer operations.delete.deleteResult(&res1, allocator);

    try std.testing.expect(res1 == .success);
    try std.testing.expectEqualStrings("ErrB", left.value.Error.name.?);
    try std.testing.expectEqualStrings("DetailB", left.value.Error.details.?);

    // 2. Assign Null literal
    var right_null = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&right_null, allocator);

    var res2 = try assign(&left, &right_null, allocator);
    defer operations.delete.deleteResult(&res2, allocator);

    try std.testing.expect(res2 == .success);
    try std.testing.expect(left.value.Error.name == null);
    try std.testing.expect(left.value.Error.details == null);

    // 3. Incompatible: Integer -> Error
    var right_incompatible = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 5 },
    };
    defer operations.delete.deleteElement(&right_incompatible, allocator);

    var res_fail = try assign(&left, &right_incompatible, allocator);
    defer operations.delete.deleteResult(&res_fail, allocator);
    try std.testing.expect(res_fail == .failure);
}

test "assign Type value and incompatible" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

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

    // 1. Assign another Type
    const right_type = try allocator.create(values.TypeValue);
    right_type.* = values.TypeValue{
        .kind = TypeBytecode.String,
        .is_nullable = true,
        .contained = std.ArrayList(values.TypeValue).empty,
    };
    var right = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Type = right_type },
    };
    defer operations.delete.deleteElement(&right, allocator);

    var res = try assign(&left, &right, allocator);
    defer operations.delete.deleteResult(&res, allocator);

    try std.testing.expect(res == .success);
    try std.testing.expectEqual(TypeBytecode.String, left.value.Type.kind);
    try std.testing.expectEqual(true, left.value.Type.is_nullable);

    // 2. Incompatible: Integer -> Type
    var right_incompatible = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 42 },
    };
    defer operations.delete.deleteElement(&right_incompatible, allocator);

    var res_fail = try assign(&left, &right_incompatible, allocator);
    defer operations.delete.deleteResult(&res_fail, allocator);
    try std.testing.expect(res_fail == .failure);
}

test "assign Reference compatible, incompatible types, null, and other values" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    const left_ref = try allocator.create(values.ReferenceValue);
    left_ref.* = values.ReferenceValue{
        .index = 10,
        .type = values.TypeValue{
            .kind = TypeBytecode.Int,
            .is_nullable = true,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Reference = left_ref },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Compatible Reference
    const right_ref = try allocator.create(values.ReferenceValue);
    right_ref.* = values.ReferenceValue{
        .index = 25,
        .type = values.TypeValue{
            .kind = TypeBytecode.Int,
            .is_nullable = false,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var right = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Reference = right_ref },
    };
    defer operations.delete.deleteElement(&right, allocator);

    var res1 = try assign(&left, &right, allocator);
    defer operations.delete.deleteResult(&res1, allocator);

    try std.testing.expect(res1 == .success);
    try std.testing.expectEqual(@as(?u32, 25), left.value.Reference.index);

    // 2. Assign Null literal
    var right_null = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&right_null, allocator);

    var res2 = try assign(&left, &right_null, allocator);
    defer operations.delete.deleteResult(&res2, allocator);

    try std.testing.expect(res2 == .success);
    try std.testing.expect(left.value.Reference.index == null);

    // 3. Incompatible Reference Type (cannot collect Float into Int)
    const bad_ref = try allocator.create(values.ReferenceValue);
    bad_ref.* = values.ReferenceValue{
        .index = 99,
        .type = values.TypeValue{
            .kind = TypeBytecode.Float,
            .is_nullable = false,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var right_bad = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Reference = bad_ref },
    };
    defer operations.delete.deleteElement(&right_bad, allocator);

    var res_bad = try assign(&left, &right_bad, allocator);
    defer operations.delete.deleteResult(&res_bad, allocator);
    try std.testing.expect(res_bad == .failure);

    // 4. Incompatible value type (Integer -> Reference)
    var right_int = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 1 },
    };
    defer operations.delete.deleteElement(&right_int, allocator);

    var res_int = try assign(&left, &right_int, allocator);
    defer operations.delete.deleteResult(&res_int, allocator);
    try std.testing.expect(res_int == .failure);
}

test "assign List compatible, incompatible types, null, and other values" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var initial_items = std.ArrayList(values.Value).empty;
    try initial_items.append(allocator, values.Value{ .Integer = 1 });

    const left_list = try allocator.create(values.ListValue);
    left_list.* = values.ListValue{
        .items = initial_items,
        .type = values.TypeValue{
            .kind = TypeBytecode.List,
            .is_nullable = true,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .List = left_list },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Compatible List
    var right_items = std.ArrayList(values.Value).empty;
    try right_items.append(allocator, values.Value{ .Integer = 42 });

    const right_list = try allocator.create(values.ListValue);
    right_list.* = values.ListValue{
        .items = right_items,
        .type = values.TypeValue{
            .kind = TypeBytecode.List,
            .is_nullable = false,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var right = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .List = right_list },
    };
    defer operations.delete.deleteElement(&right, allocator);

    var res1 = try assign(&left, &right, allocator);
    defer operations.delete.deleteResult(&res1, allocator);

    try std.testing.expect(res1 == .success);
    try std.testing.expectEqual(@as(usize, 1), left.value.List.items.?.items.len);
    try std.testing.expectEqual(@as(?i64, 42), left.value.List.items.?.items[0].Integer);

    // 2. Assign Null literal
    var right_null = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&right_null, allocator);

    var res2 = try assign(&left, &right_null, allocator);
    defer operations.delete.deleteResult(&res2, allocator);

    try std.testing.expect(res2 == .success);
    try std.testing.expect(left.value.List.items == null);

    // 3. Incompatible List (canCollect fails because kind is Bool instead of List)
    const bad_list = try allocator.create(values.ListValue);
    bad_list.* = values.ListValue{
        .items = null,
        .type = values.TypeValue{
            .kind = TypeBytecode.Bool,
            .is_nullable = false,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var right_bad = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .List = bad_list },
    };
    defer operations.delete.deleteElement(&right_bad, allocator);

    var res_bad = try assign(&left, &right_bad, allocator);
    defer operations.delete.deleteResult(&res_bad, allocator);
    try std.testing.expect(res_bad == .failure);

    // 4. Incompatible value type (Integer -> List)
    var right_int = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 10 },
    };
    defer operations.delete.deleteElement(&right_int, allocator);

    var res_int = try assign(&left, &right_int, allocator);
    defer operations.delete.deleteResult(&res_int, allocator);
    try std.testing.expect(res_int == .failure);
}
