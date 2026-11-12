const std = @import("std");
const utils = @import("../utils.zig");
const Element = @import("../results.zig").Element;
const TypeValue = @import("../values.zig").TypeValue;

pub fn typeRepr(operand: *const Element, allocator: std.mem.Allocator) utils.InternalError![]const u8 {
    return switch (operand.value) {
        .Null => allocator.print("null", .{}) catch return utils.InternalError.OutOfMemory,
        .Integer => allocator.print("int", .{}) catch return utils.InternalError.OutOfMemory,
        .UnsignedInteger => allocator.print("uint", .{}) catch return utils.InternalError.OutOfMemory,
        .Float => allocator.print("float", .{}) catch return utils.InternalError.OutOfMemory,
        .Boolean => allocator.print("bool", .{}) catch return utils.InternalError.OutOfMemory,
        .Character => allocator.print("char", .{}) catch return utils.InternalError.OutOfMemory,
        .String => allocator.print("string", .{}) catch return utils.InternalError.OutOfMemory,
        .Error => allocator.print("error", .{}) catch return utils.InternalError.OutOfMemory,
        .Type => allocator.print("type", .{}) catch return utils.InternalError.OutOfMemory,

        .Reference => |ref| blk: {
            const inner = try typeReprType(&ref.type, allocator);
            defer allocator.free(inner);
            const result = allocator.print("reference<{s}>", .{inner}) catch return utils.InternalError.OutOfMemory;

            break :blk result;
        },

        .List => |list| blk: {
            const inner = try typeReprType(&list.type, allocator);
            defer allocator.free(inner);
            const result = allocator.print("list<{s}>", .{inner}) catch return utils.InternalError.OutOfMemory;
            break :blk result;
        },
    };
}

pub fn typeReprType(t: *const TypeValue, allocator: std.mem.Allocator) utils.InternalError![]const u8 {
    if (t.contained.items.len > 0) {
        var buffer: std.ArrayList(u8) = .empty;
        buffer.print(allocator, "{s}<", .{t.kind.repr()}) catch return utils.InternalError.OutOfMemory;

        var empty = true;
        for (t.contained.items) |contained| {
            if (!empty) {
                buffer.appendSlice(allocator, ", ") catch return utils.InternalError.OutOfMemory;
            }

            const repr = try typeReprType(&contained, allocator);
            defer allocator.free(repr);

            buffer.appendSlice(allocator, repr) catch return utils.InternalError.OutOfMemory;
            empty = false;
        }

        buffer.append(allocator, '>') catch return utils.InternalError.OutOfMemory;
        if (!t.is_nullable) buffer.append(allocator, '!') catch return utils.InternalError.OutOfMemory;
        return buffer.toOwnedSlice(allocator) catch return utils.InternalError.OutOfMemory;
    } else {
        return allocator.print("{s}{s}", .{
            t.kind.repr(),
            if (t.is_nullable) "" else "!",
        }) catch return utils.InternalError.OutOfMemory;
    }
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "typeRepr scalar and primitive variants" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const allocator = std.testing.allocator;

    const test_cases = [_]struct { val: values.Value, expected: []const u8 }{
        .{ .val = values.Value{ .Null = {} }, .expected = "null" },
        .{ .val = values.Value{ .Integer = 42 }, .expected = "int" },
        .{ .val = values.Value{ .UnsignedInteger = 10 }, .expected = "uint" },
        .{ .val = values.Value{ .Float = 3.14 }, .expected = "float" },
        .{ .val = values.Value{ .Boolean = true }, .expected = "bool" },
        .{ .val = values.Value{ .Character = 'A' }, .expected = "char" },
    };

    for (test_cases) |tc| {
        var elem = Element{
            .modifier = .{},
            .value = tc.val,
        };
        defer operations.delete.deleteElement(&elem, allocator);

        const text = try typeRepr(&elem, allocator);
        defer allocator.free(text);
        try std.testing.expectEqualStrings(tc.expected, text);
    }
}

test "typeRepr String" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const allocator = std.testing.allocator;

    var elem = Element{
        .modifier = .{},
        .value = values.Value{ .String = try allocator.dupe(u8, "hello") },
    };
    defer operations.delete.deleteElement(&elem, allocator);

    const text = try typeRepr(&elem, allocator);
    defer allocator.free(text);
    try std.testing.expectEqualStrings("string", text);
}

test "typeRepr Error" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const allocator = std.testing.allocator;

    const err_ptr = try allocator.create(values.ErrorValue);
    err_ptr.* = values.ErrorValue{
        .name = try allocator.dupe(u8, "CustomError"),
        .details = null,
        .stack_trace = std.ArrayList([]const u8).empty,
    };

    var elem = Element{
        .modifier = .{},
        .value = values.Value{ .Error = err_ptr },
    };
    defer operations.delete.deleteElement(&elem, allocator);

    const text = try typeRepr(&elem, allocator);
    defer allocator.free(text);
    try std.testing.expectEqualStrings("error", text);
}

test "typeRepr Type" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const bytecodes = @import("../bytecodes/type.zig");
    const allocator = std.testing.allocator;

    const type_ptr = try allocator.create(values.TypeValue);
    type_ptr.* = values.TypeValue{
        .kind = bytecodes.TypeBytecode.Int,
        .is_nullable = false,
        .contained = std.ArrayList(values.TypeValue).empty,
    };

    var elem = Element{
        .modifier = .{},
        .value = values.Value{ .Type = type_ptr },
    };
    defer operations.delete.deleteElement(&elem, allocator);

    const text = try typeRepr(&elem, allocator);
    defer allocator.free(text);
    try std.testing.expectEqualStrings("type", text);
}

test "typeRepr Reference with nested and multi-parameter types" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const bytecodes = @import("../bytecodes/type.zig");
    const allocator = std.testing.allocator;

    // Build reference type with multiple contained items to test the comma separation:
    // reference<type<int, string!>!>
    var nested_contained: std.ArrayList(values.TypeValue) = .empty;
    try nested_contained.append(allocator, values.TypeValue{
        .kind = bytecodes.TypeBytecode.Int,
        .is_nullable = true,
        .contained = .empty,
    });
    try nested_contained.append(allocator, values.TypeValue{
        .kind = bytecodes.TypeBytecode.String,
        .is_nullable = false,
        .contained = .empty,
    });

    const ref_ptr = try allocator.create(values.ReferenceValue);
    ref_ptr.index = 10;
    ref_ptr.type = values.TypeValue{
        .kind = bytecodes.TypeBytecode.Type,
        .is_nullable = false,
        .contained = nested_contained,
    };

    var elem = Element{
        .modifier = .{},
        .value = values.Value{ .Reference = ref_ptr },
    };
    defer operations.delete.deleteElement(&elem, allocator);

    const text = try typeRepr(&elem, allocator);
    defer allocator.free(text);
    try std.testing.expectEqualStrings("reference<type<int, string!>!>", text);
}

test "typeRepr List with simple and nullable element type" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const bytecodes = @import("../bytecodes/type.zig");
    const allocator = std.testing.allocator;

    const list_ptr = try allocator.create(values.ListValue);
    list_ptr.items = null;
    list_ptr.type = values.TypeValue{
        .kind = bytecodes.TypeBytecode.Float,
        .is_nullable = true,
        .contained = .empty,
    };

    var elem = Element{
        .modifier = .{},
        .value = values.Value{ .List = list_ptr },
    };
    defer operations.delete.deleteElement(&elem, allocator);

    const text = try typeRepr(&elem, allocator);
    defer allocator.free(text);
    try std.testing.expectEqualStrings("list<float>", text);
}

test "typeReprType standalone (leaf nullable vs non-nullable)" {
    const values = @import("../values.zig");
    const bytecodes = @import("../bytecodes/type.zig");
    const allocator = std.testing.allocator;

    // 1. Leaf nullable: "char"
    {
        const t = values.TypeValue{
            .kind = bytecodes.TypeBytecode.Char,
            .is_nullable = true,
            .contained = .empty,
        };
        const text = try typeReprType(&t, allocator);
        defer allocator.free(text);
        try std.testing.expectEqualStrings("char", text);
    }

    // 2. Leaf non-nullable: "char!"
    {
        const t = values.TypeValue{
            .kind = bytecodes.TypeBytecode.Char,
            .is_nullable = false,
            .contained = .empty,
        };
        const text = try typeReprType(&t, allocator);
        defer allocator.free(text);
        try std.testing.expectEqualStrings("char!", text);
    }
}
