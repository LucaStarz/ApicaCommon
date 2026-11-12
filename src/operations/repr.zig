const std = @import("std");
const utils = @import("../utils.zig");
const Element = @import("../results.zig").Element;
const TypeValue = @import("../values.zig").TypeValue;
const ListValue = @import("../values.zig").ListValue;
const ErrorValue = @import("../values.zig").ErrorValue;
const Value = @import("../values.zig").Value;

pub fn repr(operand: *const Element, allocator: std.mem.Allocator) utils.InternalError![]const u8 {
    return reprValue(&operand.value, allocator);
}

pub fn reprValue(val: *const Value, allocator: std.mem.Allocator) utils.InternalError![]const u8 {
    return switch (val.*) {
        .Null => allocator.print("null", .{}) catch return utils.InternalError.OutOfMemory,
        .Integer => |value| allocator.print("{?}", .{value}) catch return utils.InternalError.OutOfMemory,
        .UnsignedInteger => |value| allocator.print("{?}", .{value}) catch return utils.InternalError.OutOfMemory,
        .Float => |value| allocator.print("{?}", .{value}) catch return utils.InternalError.OutOfMemory,
        .Boolean => |value| allocator.print("{?}", .{value}) catch return utils.InternalError.OutOfMemory,

        .Character => |value| if (value) |codepoint| {
            var buffer: [4]u8 = undefined;
            return allocator.print("{s}", .{utils.chars.characterToUTF8(codepoint, &buffer)}) catch return utils.InternalError.OutOfMemory;
        } else {
            return allocator.print("null", .{}) catch return utils.InternalError.OutOfMemory;
        },

        .String => |value| allocator.print("{?s}", .{value}) catch return utils.InternalError.OutOfMemory,

        .Error => |value| reprError(value, allocator),

        .Type => |value| reprType(value, allocator),

        .Reference => |value| if (value.index) |index|
            allocator.print("@{}", .{index}) catch return utils.InternalError.OutOfMemory
        else
            allocator.print("null", .{}) catch return utils.InternalError.OutOfMemory,

        .List => |value| reprList(value, allocator),
    };
}

pub fn reprType(t: *const TypeValue, allocator: std.mem.Allocator) utils.InternalError![]const u8 {
    if (t.contained.items.len > 0) {
        var buffer: std.ArrayList(u8) = .empty;
        buffer.print(allocator, "{s}<", .{t.kind.repr()}) catch return utils.InternalError.OutOfMemory;

        var empty = true;
        for (t.contained.items) |contained| {
            if (!empty) {
                buffer.appendSlice(allocator, ", ") catch return utils.InternalError.OutOfMemory;
            }

            const inner = try reprType(&contained, allocator);
            defer allocator.free(inner);

            buffer.appendSlice(allocator, inner) catch return utils.InternalError.OutOfMemory;
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

pub fn reprError(err: *const ErrorValue, allocator: std.mem.Allocator) utils.InternalError![]const u8 {
    if (err.name) |name| {
        if (err.details) |details| {
            return allocator.print("{s}: {s}", .{ name, details }) catch return utils.InternalError.OutOfMemory;
        } else {
            return allocator.print("{s}", .{name}) catch return utils.InternalError.OutOfMemory;
        }
    } else {
        return allocator.print("null", .{}) catch return utils.InternalError.OutOfMemory;
    }
}

pub fn reprList(list: *const ListValue, allocator: std.mem.Allocator) utils.InternalError![]const u8 {
    if (list.items) |items| {
        var buffer: std.ArrayList(u8) = .empty;
        buffer.append(allocator, '[') catch return utils.InternalError.OutOfMemory;

        var empty = true;
        for (items.items) |item| {
            if (!empty) {
                buffer.appendSlice(allocator, ", ") catch return utils.InternalError.OutOfMemory;
            }

            const item_str = try reprValue(&item, allocator);
            defer allocator.free(item_str);

            buffer.appendSlice(allocator, item_str) catch return utils.InternalError.OutOfMemory;
            empty = false;
        }

        buffer.append(allocator, ']') catch return utils.InternalError.OutOfMemory;
        return buffer.toOwnedSlice(allocator) catch return utils.InternalError.OutOfMemory;
    } else {
        return allocator.print("null", .{}) catch return utils.InternalError.OutOfMemory;
    }
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "repr Null" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const allocator = std.testing.allocator;

    var elem = Element{
        .modifier = .{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&elem, allocator);

    const s = try repr(&elem, allocator);
    defer allocator.free(s);

    try std.testing.expectEqualStrings("null", s);
}

test "repr Integer (value and null)" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const allocator = std.testing.allocator;

    // 1. With value
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Integer = -42 } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("-42", s);
    }

    // 2. Null
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Integer = null } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("null", s);
    }
}

test "repr UnsignedInteger (value and null)" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const allocator = std.testing.allocator;

    // 1. With value
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = 100 } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("100", s);
    }

    // 2. Null
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .UnsignedInteger = null } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("null", s);
    }
}

test "repr Float (value and null)" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const allocator = std.testing.allocator;

    // 1. With value
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Float = 3.5 } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("3.5", s);
    }

    // 2. Null
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Float = null } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("null", s);
    }
}

test "repr Boolean (value and null)" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const allocator = std.testing.allocator;

    // 1. true
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("true", s);
    }

    // 2. false
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Boolean = false } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("false", s);
    }

    // 3. Null
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Boolean = null } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("null", s);
    }
}

test "repr Character (value and null)" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const allocator = std.testing.allocator;

    // 1. ASCII character 'A'
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Character = 'A' } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("A", s);
    }

    // 2. Multi-byte UTF-8 character (e.g. '€' = 0x20AC)
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Character = 0x20AC } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("€", s);
    }

    // 3. Null
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Character = null } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("null", s);
    }
}

test "repr String (value and null)" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const allocator = std.testing.allocator;

    // 1. With string
    {
        var elem = Element{
            .modifier = .{},
            .value = values.Value{ .String = try allocator.dupe(u8, "hello world") },
        };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("hello world", s);
    }

    // 2. Null
    {
        var elem = Element{ .modifier = .{}, .value = values.Value{ .String = null } };
        defer operations.delete.deleteElement(&elem, allocator);
        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("null", s);
    }
}

test "repr Error (name + details, name only, null)" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const allocator = std.testing.allocator;

    // 1. Name and details
    {
        const err_ptr = try allocator.create(values.ErrorValue);
        err_ptr.* = values.ErrorValue{
            .name = try allocator.dupe(u8, "TypeError"),
            .details = try allocator.dupe(u8, "invalid type conversion"),
            .stack_trace = std.ArrayList([]const u8).empty,
        };
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Error = err_ptr } };
        defer operations.delete.deleteElement(&elem, allocator);

        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("TypeError: invalid type conversion", s);
    }

    // 2. Name only
    {
        const err_ptr = try allocator.create(values.ErrorValue);
        err_ptr.* = values.ErrorValue{
            .name = try allocator.dupe(u8, "NotFoundError"),
            .details = null,
            .stack_trace = std.ArrayList([]const u8).empty,
        };
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Error = err_ptr } };
        defer operations.delete.deleteElement(&elem, allocator);

        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("NotFoundError", s);
    }

    // 3. Name is null
    {
        const err_ptr = try allocator.create(values.ErrorValue);
        err_ptr.* = values.ErrorValue{
            .name = null,
            .details = null,
            .stack_trace = std.ArrayList([]const u8).empty,
        };
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Error = err_ptr } };
        defer operations.delete.deleteElement(&elem, allocator);

        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("null", s);
    }
}

test "repr Type nested representation" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;
    const allocator = std.testing.allocator;

    var contained: std.ArrayList(values.TypeValue) = .empty;
    try contained.append(allocator, values.TypeValue{
        .kind = TypeBytecode.Int,
        .is_nullable = false,
        .contained = .empty,
    });

    const type_ptr = try allocator.create(values.TypeValue);
    type_ptr.* = values.TypeValue{
        .kind = TypeBytecode.List,
        .is_nullable = true,
        .contained = contained,
    };
    var elem = Element{ .modifier = .{}, .value = values.Value{ .Type = type_ptr } };
    defer operations.delete.deleteElement(&elem, allocator);

    const s = try repr(&elem, allocator);
    defer allocator.free(s);
    try std.testing.expectEqualStrings("list<int!>", s);
}

test "repr Reference (indexed and null)" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;
    const allocator = std.testing.allocator;

    // 1. With index
    {
        const ref_ptr = try allocator.create(values.ReferenceValue);
        ref_ptr.* = values.ReferenceValue{
            .index = 123,
            .type = values.TypeValue{
                .kind = TypeBytecode.Int,
                .is_nullable = false,
                .contained = std.ArrayList(values.TypeValue).empty,
            },
        };
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Reference = ref_ptr } };
        defer operations.delete.deleteElement(&elem, allocator);

        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("@123", s);
    }

    // 2. Null index
    {
        const ref_ptr = try allocator.create(values.ReferenceValue);
        ref_ptr.* = values.ReferenceValue{
            .index = null,
            .type = values.TypeValue{
                .kind = TypeBytecode.Int,
                .is_nullable = false,
                .contained = std.ArrayList(values.TypeValue).empty,
            },
        };
        var elem = Element{ .modifier = .{}, .value = values.Value{ .Reference = ref_ptr } };
        defer operations.delete.deleteElement(&elem, allocator);

        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("null", s);
    }
}

test "repr List items format and null items" {
    const operations = @import("../operations.zig");
    const values = @import("../values.zig");
    const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;
    const allocator = std.testing.allocator;

    // 1. List with items: [1, 2, 3]
    {
        var items: std.ArrayList(values.Value) = .empty;
        try items.append(allocator, values.Value{ .Integer = 1 });
        try items.append(allocator, values.Value{ .Integer = 2 });
        try items.append(allocator, values.Value{ .Integer = 3 });

        const list_ptr = try allocator.create(values.ListValue);
        list_ptr.* = values.ListValue{
            .items = items,
            .type = values.TypeValue{
                .kind = TypeBytecode.List,
                .is_nullable = false,
                .contained = .empty,
            },
        };
        var elem = Element{ .modifier = .{}, .value = values.Value{ .List = list_ptr } };
        defer operations.delete.deleteElement(&elem, allocator);

        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("[1, 2, 3]", s);
    }

    // 2. Empty list: []
    {
        const list_ptr = try allocator.create(values.ListValue);
        list_ptr.* = values.ListValue{
            .items = std.ArrayList(values.Value).empty,
            .type = values.TypeValue{
                .kind = TypeBytecode.List,
                .is_nullable = false,
                .contained = .empty,
            },
        };
        var elem = Element{ .modifier = .{}, .value = values.Value{ .List = list_ptr } };
        defer operations.delete.deleteElement(&elem, allocator);

        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("[]", s);
    }

    // 3. Null items
    {
        const list_ptr = try allocator.create(values.ListValue);
        list_ptr.* = values.ListValue{
            .items = null,
            .type = values.TypeValue{
                .kind = TypeBytecode.List,
                .is_nullable = false,
                .contained = .empty,
            },
        };
        var elem = Element{ .modifier = .{}, .value = values.Value{ .List = list_ptr } };
        defer operations.delete.deleteElement(&elem, allocator);

        const s = try repr(&elem, allocator);
        defer allocator.free(s);
        try std.testing.expectEqualStrings("null", s);
    }
}
