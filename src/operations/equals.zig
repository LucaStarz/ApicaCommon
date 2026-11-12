const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");

const OPERATOR_NAME: []const u8 = "==";

pub fn equals(left: *const results.Element, right: *const results.Element, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    const result = equalsValue(&left.value, &right.value);

    if (result) |element| {
        return results.OperationResult{ .success = element };
    } else {
        return results.OperationResult{ .failure = try results.Signal.binaryOperationError(OPERATOR_NAME, left, right, allocator) };
    }
}

fn equalsValue(left: *const values.Value, right: *const values.Value) ?results.Element {
    return switch (left.*) {
        .Null => results.Element.init(values.Value{ .Boolean = right.isNull() }),
        .Integer => |value| equalsInteger(value, right),
        .UnsignedInteger => |value| equalsUnsignedInteger(value, right),
        .Float => |value| equalsFloat(value, right),
        .Boolean => |value| equalsBoolean(value, right),
        .Character => |value| equalsCharacter(value, right),
        .String => |value| equalsString(value, right),
        .Error => |value| equalsError(value, right),
        .Type => |value| equalsType(value, right),
        .Reference => |value| equalsReference(value, right),
        .List => |value| equalsList(value, right),
    };
}

fn equalsInteger(left: ?i64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Null => results.Element.init(values.Value{ .Boolean = left == null }),
        .Integer => |value| results.Element.init(values.Value{ .Boolean = left == value }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and lval == @as(i64, @intCast(value.?)) else value == null }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and value.? == @as(f64, @floatFromInt(lval)) else value == null }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and lval == @as(i64, @intFromBool(value.?)) else value == null }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and lval == @as(i64, @intCast(value.?)) else value == null }),

        else => null,
    };
}

fn equalsUnsignedInteger(left: ?u64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Null => results.Element.init(values.Value{ .Boolean = left == null }),
        .Integer => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and lval == @as(u64, @intCast(value.?)) else value == null }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = left == value }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and value.? == @as(f64, @floatFromInt(lval)) else value == null }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and lval == @as(u64, @intFromBool(value.?)) else value == null }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and lval == @as(u64, @intCast(value.?)) else value == null }),

        else => null,
    };
}

fn equalsFloat(left: ?f64, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Null => results.Element.init(values.Value{ .Boolean = left == null }),
        .Integer => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and lval == @as(f64, @floatFromInt(value.?)) else value == null }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and lval == @as(f64, @floatFromInt(value.?)) else value == null }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = left == value }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and lval == @as(f64, @floatFromInt(@intFromBool(value.?))) else value == null }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and lval == @as(f64, @floatFromInt(value.?)) else value == null }),

        else => null,
    };
}

fn equalsBoolean(left: ?bool, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Null => results.Element.init(values.Value{ .Boolean = left == null }),
        .Integer => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and @as(i64, @intFromBool(lval)) == value.? else value == null }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and @as(u64, @intFromBool(lval)) == value.? else value == null }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and @as(f64, @floatFromInt(@intFromBool(lval))) == value.? else value == null }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = left == value }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and @as(u32, @intFromBool(lval)) == value.? else value == null }),

        else => null,
    };
}

fn equalsCharacter(left: ?u32, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Null => results.Element.init(values.Value{ .Boolean = left == null }),
        .Integer => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and value.? == @as(i64, @intCast(lval)) else value == null }),
        .UnsignedInteger => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and value.? == @as(u64, @intCast(lval)) else value == null }),
        .Float => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and value.? == @as(f64, @floatFromInt(lval)) else value == null }),
        .Boolean => |value| results.Element.init(values.Value{ .Boolean = if (left) |lval| value != null and lval == @as(u32, @intFromBool(value.?)) else value == null }),
        .Character => |value| results.Element.init(values.Value{ .Boolean = left == value }),

        else => null,
    };
}

fn equalsString(left: ?[]const u8, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Null => results.Element.init(values.Value{ .Boolean = left == null }),
        .String => |value| results.Element.init(values.Value{ .Boolean = (left == null and value == null) or (left != null and value != null and std.mem.eql(u8, left.?, value.?)) }),

        else => null,
    };
}

fn equalsError(left: *const values.ErrorValue, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Null => results.Element.init(values.Value{ .Boolean = left.name == null }),
        .Error => |value| results.Element.init(values.Value{ .Boolean = (left.name == null and value.name == null) or (left.name != null and value.name != null and std.mem.eql(u8, left.name.?, value.name.?)) }),

        else => null,
    };
}

fn equalsType(left: *const values.TypeValue, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Null => results.Element.init(values.Value{ .Boolean = false }),
        .Type => |value| results.Element.init(values.Value{ .Boolean = left.equals(value) }),

        else => null,
    };
}

fn equalsReference(left: *const values.ReferenceValue, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Null => results.Element.init(values.Value{ .Boolean = left.index == null }),
        .Reference => |value| results.Element.init(values.Value{ .Boolean = left.index == value.index }),

        else => null,
    };
}

fn equalsList(left: *const values.ListValue, right: *const values.Value) ?results.Element {
    return switch (right.*) {
        .Null => results.Element.init(values.Value{ .Boolean = left.items == null }),
        .List => |value| {
            if (!left.type.equals(&value.type)) {
                return results.Element.init(values.Value{ .Boolean = false });
            }

            if (left.items == null and value.items == null) {
                return results.Element.init(values.Value{ .Boolean = true });
            }

            if (left.items == null or value.items == null) {
                return results.Element.init(values.Value{ .Boolean = false });
            }

            const left_items = left.items.?.items;
            const right_items = value.items.?.items;
            if (left_items.len != right_items.len) {
                return results.Element.init(values.Value{ .Boolean = false });
            }

            for (0..left_items.len) |i| {
                const sub_cmp = equalsValue(&left_items[i], &right_items[i]);
                if (sub_cmp == null or !sub_cmp.?.value.Boolean.?) {
                    return results.Element.init(values.Value{ .Boolean = false });
                }
            }

            return results.Element.init(values.Value{ .Boolean = true });
        },

        else => null,
    };
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "equals Null with all primitives and null states" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var null_elem = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&null_elem, allocator);

    var int_null = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = null },
    };
    defer operations.delete.deleteElement(&int_null, allocator);

    var int_val = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 10 },
    };
    defer operations.delete.deleteElement(&int_val, allocator);

    // Null == Null
    var res1 = try equals(&null_elem, &null_elem, allocator);
    defer operations.delete.deleteResult(&res1, allocator);
    try std.testing.expectEqual(true, res1.success.value.Boolean.?);

    // Null == Integer(null)
    var res2 = try equals(&null_elem, &int_null, allocator);
    defer operations.delete.deleteResult(&res2, allocator);
    try std.testing.expectEqual(true, res2.success.value.Boolean.?);

    // Null == Integer(10)
    var res3 = try equals(&null_elem, &int_val, allocator);
    defer operations.delete.deleteResult(&res3, allocator);
    try std.testing.expectEqual(false, res3.success.value.Boolean.?);
}

test "equals Integer cross-type comparisons" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 42 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    const match_cases = [_]values.Value{
        values.Value{ .Integer = 42 },
        values.Value{ .UnsignedInteger = 42 },
        values.Value{ .Float = 42.0 },
        values.Value{ .Character = 42 },
    };

    for (match_cases) |val| {
        var right = results.Element{ .modifier = results.ElementModifier{}, .value = val };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try equals(&left, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(true, res.success.value.Boolean.?);
    }

    // Negative int compared to unsigned
    var left_neg = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = -5 },
    };
    defer operations.delete.deleteElement(&left_neg, allocator);

    var right_uint = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .UnsignedInteger = 5 },
    };
    defer operations.delete.deleteElement(&right_uint, allocator);

    var res_neg = try equals(&left_neg, &right_uint, allocator);
    defer operations.delete.deleteResult(&res_neg, allocator);
    try std.testing.expectEqual(false, res_neg.success.value.Boolean.?);

    // Incompatible: Integer == String -> Failure
    var right_str = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "42") },
    };
    defer operations.delete.deleteElement(&right_str, allocator);

    var res_fail = try equals(&left, &right_str, allocator);
    defer operations.delete.deleteResult(&res_fail, allocator);
    try std.testing.expect(res_fail == .failure);
}

test "equals Boolean cross-type conversions" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var b_true = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Boolean = true },
    };
    defer operations.delete.deleteElement(&b_true, allocator);

    const true_cases = [_]values.Value{
        values.Value{ .Integer = 1 },
        values.Value{ .UnsignedInteger = 1 },
        values.Value{ .Float = 1.0 },
        values.Value{ .Character = 1 },
    };

    for (true_cases) |val| {
        var right = results.Element{ .modifier = results.ElementModifier{}, .value = val };
        defer operations.delete.deleteElement(&right, allocator);

        var res = try equals(&b_true, &right, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(true, res.success.value.Boolean.?);
    }

    var int_two = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 2 },
    };
    defer operations.delete.deleteElement(&int_two, allocator);

    var res_false = try equals(&b_true, &int_two, allocator);
    defer operations.delete.deleteResult(&res_false, allocator);
    try std.testing.expectEqual(false, res_false.success.value.Boolean.?);
}

test "equals String matching, mismatch, null, and incompatible" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var s1 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "hello") },
    };
    defer operations.delete.deleteElement(&s1, allocator);

    var s2 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "hello") },
    };
    defer operations.delete.deleteElement(&s2, allocator);

    var s3 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "world") },
    };
    defer operations.delete.deleteElement(&s3, allocator);

    var s_null = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = null },
    };
    defer operations.delete.deleteElement(&s_null, allocator);

    // Identical
    var res_eq = try equals(&s1, &s2, allocator);
    defer operations.delete.deleteResult(&res_eq, allocator);
    try std.testing.expectEqual(true, res_eq.success.value.Boolean.?);

    // Different content
    var res_diff = try equals(&s1, &s3, allocator);
    defer operations.delete.deleteResult(&res_diff, allocator);
    try std.testing.expectEqual(false, res_diff.success.value.Boolean.?);

    // Compared to null
    var res_null = try equals(&s1, &s_null, allocator);
    defer operations.delete.deleteResult(&res_null, allocator);
    try std.testing.expectEqual(false, res_null.success.value.Boolean.?);

    // Null string == Null literal
    var lit_null = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&lit_null, allocator);

    var res_null_lit = try equals(&s_null, &lit_null, allocator);
    defer operations.delete.deleteResult(&res_null_lit, allocator);
    try std.testing.expectEqual(true, res_null_lit.success.value.Boolean.?);
}

test "equals Error matching on name" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    const err_a = try allocator.create(values.ErrorValue);
    err_a.* = values.ErrorValue{
        .name = try allocator.dupe(u8, "CustomError"),
        .details = try allocator.dupe(u8, "Details A"),
        .stack_trace = std.ArrayList([]const u8).empty,
    };
    var left = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Error = err_a },
    };
    defer operations.delete.deleteElement(&left, allocator);

    const err_b = try allocator.create(values.ErrorValue);
    err_b.* = values.ErrorValue{
        .name = try allocator.dupe(u8, "CustomError"),
        .details = try allocator.dupe(u8, "Details B (different)"),
        .stack_trace = std.ArrayList([]const u8).empty,
    };
    var right = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Error = err_b },
    };
    defer operations.delete.deleteElement(&right, allocator);

    var res = try equals(&left, &right, allocator);
    defer operations.delete.deleteResult(&res, allocator);
    try std.testing.expectEqual(true, res.success.value.Boolean.?);
}

test "equals Type structural equality" {
    const operations = @import("../operations.zig");
    const TypeBytecode = @import("../bytecodes.zig").TypeBytecode;
    const allocator = std.testing.allocator;

    const t1 = try allocator.create(values.TypeValue);
    t1.* = values.TypeValue{
        .kind = TypeBytecode.Int,
        .is_nullable = false,
        .contained = std.ArrayList(values.TypeValue).empty,
    };
    var elem1 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Type = t1 },
    };
    defer operations.delete.deleteElement(&elem1, allocator);

    const t2 = try allocator.create(values.TypeValue);
    t2.* = values.TypeValue{
        .kind = TypeBytecode.Int,
        .is_nullable = false,
        .contained = std.ArrayList(values.TypeValue).empty,
    };
    var elem2 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Type = t2 },
    };
    defer operations.delete.deleteElement(&elem2, allocator);

    const t3 = try allocator.create(values.TypeValue);
    t3.* = values.TypeValue{
        .kind = TypeBytecode.Int,
        .is_nullable = true,
        .contained = std.ArrayList(values.TypeValue).empty,
    };
    var elem3 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Type = t3 },
    };
    defer operations.delete.deleteElement(&elem3, allocator);

    var res_eq = try equals(&elem1, &elem2, allocator);
    defer operations.delete.deleteResult(&res_eq, allocator);
    try std.testing.expectEqual(true, res_eq.success.value.Boolean.?);

    var res_neq = try equals(&elem1, &elem3, allocator);
    defer operations.delete.deleteResult(&res_neq, allocator);
    try std.testing.expectEqual(false, res_neq.success.value.Boolean.?);
}

test "equals Reference equality on type and index" {
    const operations = @import("../operations.zig");
    const TypeBytecode = @import("../bytecodes.zig").TypeBytecode;
    const allocator = std.testing.allocator;

    const r1 = try allocator.create(values.ReferenceValue);
    r1.* = values.ReferenceValue{
        .index = 10,
        .type = values.TypeValue{
            .kind = TypeBytecode.Int,
            .is_nullable = false,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var elem1 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Reference = r1 },
    };
    defer operations.delete.deleteElement(&elem1, allocator);

    const r2 = try allocator.create(values.ReferenceValue);
    r2.* = values.ReferenceValue{
        .index = 10,
        .type = values.TypeValue{
            .kind = TypeBytecode.Int,
            .is_nullable = false,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var elem2 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Reference = r2 },
    };
    defer operations.delete.deleteElement(&elem2, allocator);

    const r3 = try allocator.create(values.ReferenceValue);
    r3.* = values.ReferenceValue{
        .index = 99,
        .type = values.TypeValue{
            .kind = TypeBytecode.Int,
            .is_nullable = false,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var elem3 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Reference = r3 },
    };
    defer operations.delete.deleteElement(&elem3, allocator);

    var res_eq = try equals(&elem1, &elem2, allocator);
    defer operations.delete.deleteResult(&res_eq, allocator);
    try std.testing.expectEqual(true, res_eq.success.value.Boolean.?);

    var res_neq = try equals(&elem1, &elem3, allocator);
    defer operations.delete.deleteResult(&res_neq, allocator);
    try std.testing.expectEqual(false, res_neq.success.value.Boolean.?);
}

test "equals List deep recursive equality" {
    const operations = @import("../operations.zig");
    const TypeBytecode = @import("../bytecodes.zig").TypeBytecode;
    const allocator = std.testing.allocator;

    var items1 = std.ArrayList(values.Value).empty;
    try items1.append(allocator, values.Value{ .Integer = 1 });
    try items1.append(allocator, values.Value{ .Integer = 2 });

    const l1 = try allocator.create(values.ListValue);
    l1.* = values.ListValue{
        .items = items1,
        .type = values.TypeValue{
            .kind = TypeBytecode.List,
            .is_nullable = false,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var elem1 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .List = l1 },
    };
    defer operations.delete.deleteElement(&elem1, allocator);

    var items2 = std.ArrayList(values.Value).empty;
    try items2.append(allocator, values.Value{ .Integer = 1 });
    try items2.append(allocator, values.Value{ .Integer = 2 });

    const l2 = try allocator.create(values.ListValue);
    l2.* = values.ListValue{
        .items = items2,
        .type = values.TypeValue{
            .kind = TypeBytecode.List,
            .is_nullable = false,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var elem2 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .List = l2 },
    };
    defer operations.delete.deleteElement(&elem2, allocator);

    var items3 = std.ArrayList(values.Value).empty;
    try items3.append(allocator, values.Value{ .Integer = 1 });
    try items3.append(allocator, values.Value{ .Integer = 99 });

    const l3 = try allocator.create(values.ListValue);
    l3.* = values.ListValue{
        .items = items3,
        .type = values.TypeValue{
            .kind = TypeBytecode.List,
            .is_nullable = false,
            .contained = std.ArrayList(values.TypeValue).empty,
        },
    };
    var elem3 = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .List = l3 },
    };
    defer operations.delete.deleteElement(&elem3, allocator);

    var res_eq = try equals(&elem1, &elem2, allocator);
    defer operations.delete.deleteResult(&res_eq, allocator);
    try std.testing.expectEqual(true, res_eq.success.value.Boolean.?);

    var res_diff = try equals(&elem1, &elem3, allocator);
    defer operations.delete.deleteResult(&res_diff, allocator);
    try std.testing.expectEqual(false, res_diff.success.value.Boolean.?);
}
