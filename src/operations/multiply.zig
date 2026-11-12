const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");
const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;

const OPERATOR_NAME: []const u8 = "*";

pub fn multiply(left: *const results.Element, right: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    if (left.value.isNull() or right.value.isNull()) {
        return results.OperationResult{ .failure = try results.Signal.nullOperationError(OPERATOR_NAME, allocator) };
    }

    const result = switch (left.value) {
        .Integer => |value| multiplyInteger(value.?, &right.value),
        .UnsignedInteger => |value| multiplyUnsignedInteger(value.?, &right.value),
        .Float => |value| multiplyFloat(value.?, &right.value),
        .Boolean => |value| multiplyBoolean(value.?, &right.value),
        .Character => |value| multiplyCharacter(value.?, &right.value),
        .String => |value| multiplyString(value.?, &right.value, allocator),
        .List => |value| multiplyList(value, &right.value, allocator),

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

fn multiplyInteger(left: i64, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = left * value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Integer = left * @as(i64, @intCast(value.?)) }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) * value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Integer = left * @as(i64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Integer = left * @as(i64, @intCast(value.?)) }),

        else => InternalError.UndefinedOperation,
    };
}

fn multiplyUnsignedInteger(left: u64, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intCast(left)) * value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = left * value.? }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) * value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .UnsignedInteger = left * @as(u64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .UnsignedInteger = left * @as(u64, @intCast(value.?)) }),

        else => InternalError.UndefinedOperation,
    };
}

fn multiplyFloat(left: f64, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Float = left * @as(f64, @floatFromInt(value.?)) }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Float = left * @as(f64, @floatFromInt(value.?)) }),
        .Float => |value| results.Element.init(values.Value{ .Float = left * value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Float = left * @as(f64, @floatFromInt(@intFromBool(value.?))) }),
        .Character => |value| results.Element.init(values.Value{ .Float = left * @as(f64, @floatFromInt(value.?)) }),

        else => InternalError.UndefinedOperation,
    };
}

fn multiplyBoolean(left: bool, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intFromBool(left)) * value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intFromBool(left)) * value.? }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(@intFromBool(left))) * value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intFromBool(left)) * @as(u64, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Character = @as(u32, @intFromBool(left)) * value.? }),

        else => InternalError.UndefinedOperation,
    };
}

fn multiplyCharacter(left: u32, right: *const values.Value) InternalError!results.Element {
    return switch (right.*) {
        .Integer => |value| results.Element.init(values.Value{ .Integer = @as(i64, @intCast(left)) * value.? }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .UnsignedInteger = @as(u64, @intCast(left)) * value.? }),
        .Float => |value| results.Element.init(values.Value{ .Float = @as(f64, @floatFromInt(left)) * value.? }),
        .Boolean => |value| results.Element.init(values.Value{ .Character = left * @as(u32, @intFromBool(value.?)) }),
        .Character => |value| results.Element.init(values.Value{ .Character = left * value.? }),

        else => InternalError.UndefinedOperation,
    };
}

fn multiplyString(left: []const u8, right: *const values.Value, allocator: std.mem.Allocator) InternalError!results.Element {
    const count: usize = switch (right.*) {
        .Integer => |value| if (value.? < 0) {
            return InternalError.UndefinedNegativeOperation;
        } else @as(usize, @intCast(value.?)),
        .UnsignedInteger => |value| @as(usize, @intCast(value.?)),
        .Character => |value| @as(usize, @intCast(value.?)),
        else => return InternalError.UndefinedOperation,
    };

    const total_len = std.math.mul(usize, left.len, count) catch return InternalError.OutOfMemory;
    const result = allocator.alloc(u8, total_len) catch return InternalError.OutOfMemory;
    for (0..count) |i| {
        const dest = result[i * left.len .. (i + 1) * left.len];
        @memcpy(dest, left);
    }

    return results.Element.init(values.Value{ .String = result });
}

fn multiplyList(left: *const values.ListValue, right: *const values.Value, allocator: std.mem.Allocator) InternalError!results.Element {
    const count: usize = switch (right.*) {
        .Integer => |value| if (value.? < 0) {
            return InternalError.UndefinedNegativeOperation;
        } else @as(usize, @intCast(value.?)),
        .UnsignedInteger => |value| @as(usize, @intCast(value.?)),
        .Character => |value| @as(usize, @intCast(value.?)),
        else => return InternalError.UndefinedOperation,
    };

    var new_type = try left.type.clone(allocator);
    errdefer new_type.deinit(allocator);

    var new_items: ?std.ArrayList(values.Value) = null;
    if (left.items) |items| {
        const total_len = std.math.mul(usize, items.items.len, count) catch return InternalError.OutOfMemory;
        var list_builder = std.ArrayList(values.Value).initCapacity(allocator, total_len) catch return InternalError.OutOfMemory;
        errdefer {
            for (list_builder.items) |*item| {
                item.deinit(allocator);
            }
            list_builder.deinit(allocator);
        }

        for (0..count) |_| {
            for (items.items) |*item| {
                const cloned_item = try item.clone(allocator);
                list_builder.appendAssumeCapacity(cloned_item);
            }
        }
        new_items = list_builder;
    }

    const copy = allocator.create(values.ListValue) catch return InternalError.OutOfMemory;
    copy.* = values.ListValue{
        .items = new_items,
        .type = new_type,
    };

    return results.Element.init(values.Value{ .List = copy });
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "multiply null operands result in failure" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var num = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 5 },
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

    var res1 = try multiply(&null_lit, &num, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expect(res1 == .failure);

    var res2 = try multiply(&num, &null_lit, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expect(res2 == .failure);

    var res3 = try multiply(&null_opt, &num, allocator);
    defer operations.delete.deleteResult(&res3, allocator);
    try std.testing.expect(res3 == .failure);

    var res4 = try multiply(&num, &null_opt, allocator);
    defer operations.delete.deleteResult(&res4, allocator);
    try std.testing.expect(res4 == .failure);
}

test "multiply Integer all conversions" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 4 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // Integer * Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 3 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 12), res.success.value.Integer);
    }

    // Integer * UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 20), res.success.value.Integer);
    }

    // Integer * Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 2.5 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 10.0), res.success.value.Float);
    }

    // Integer * Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 4), res.success.value.Integer);
    }

    // Integer * Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 2 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?i64, 8), res.success.value.Integer);
    }
}

test "multiply Float all conversions" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Float = 2.5 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // Float * Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 2 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 5.0), res.success.value.Float);
    }

    // Float * Float
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 4.0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 10.0), res.success.value.Float);
    }

    // Float * Boolean
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 2.5), res.success.value.Float);
    }
}

test "multiply String by Integer, UnsignedInteger, Character and negative error" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .String = try allocator.dupe(u8, "ab") },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // String * Integer (valid)
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 3 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqualStrings("ababab", res.success.value.String.?);
    }

    // String * UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 2 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqualStrings("abab", res.success.value.String.?);
    }

    // String * Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqualStrings("ab", res.success.value.String.?);
    }

    // String * 0 count
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqualStrings("", res.success.value.String.?);
    }

    // String * Negative Integer -> negativeRightOperandError
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = -1 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }

    // String * Incompatible (Float) -> binaryOperationError
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 2.0 } };
        defer operations.delete.deleteElement(&right, allocator);
        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }
}

test "multiply List repetitions, null items, negative count, and incompatible" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var initial_items = std.ArrayList(values.Value).empty;
    try initial_items.append(allocator, values.Value{ .Integer = 10 });
    try initial_items.append(allocator, values.Value{ .Integer = 20 });

    const list_val = try allocator.create(values.ListValue);
    list_val.* = values.ListValue{
        .items = initial_items,
        .type = values.TypeValue{
            .kind = TypeBytecode.List,
            .is_nullable = false,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .List = list_val },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // List * 2
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = 2 } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .success);
        const res_list = res.success.value.List;
        try std.testing.expectEqual(@as(usize, 4), res_list.items.?.items.len);
        try std.testing.expectEqual(@as(?i64, 10), res_list.items.?.items[0].Integer);
        try std.testing.expectEqual(@as(?i64, 20), res_list.items.?.items[1].Integer);
        try std.testing.expectEqual(@as(?i64, 10), res_list.items.?.items[2].Integer);
        try std.testing.expectEqual(@as(?i64, 20), res_list.items.?.items[3].Integer);
    }

    // List * UnsignedInteger
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 1 } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .success);
        try std.testing.expectEqual(@as(usize, 2), res.success.value.List.items.?.items.len);
    }

    // List * Character
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0 } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .success);
        try std.testing.expectEqual(@as(usize, 0), res.success.value.List.items.?.items.len);
    }

    // List * Negative Integer
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Integer = -3 } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .failure);
    }

    // List * Incompatible (Boolean)
    {
        var right = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try multiply(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);

        try std.testing.expect(res == .failure);
    }
}
