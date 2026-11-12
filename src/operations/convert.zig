const std = @import("std");
const InternalError = @import("../utils.zig").InternalError;
const results = @import("../results.zig");
const values = @import("../values.zig");
const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;
const characterToUTF8 = @import("../utils.zig").chars.characterToUTF8;
const repr = @import("../operations/repr.zig");

const OPERATOR_NAME: []const u8 = "as";

pub fn convert(left: *const results.Element, target: *const values.TypeValue, auto: bool, allocator: std.mem.Allocator) InternalError!results.OperationResult {
    const result = switch (left.value) {
        .Null => try convertNull(target, allocator),
        .Integer => |value| try convertInteger(value, target, auto, allocator),
        .UnsignedInteger => |value| try convertUnsignedInteger(value, target, auto, allocator),
        .Float => |value| try convertFloat(value, target, auto, allocator),
        .Boolean => |value| try convertBoolean(value, target, auto, allocator),
        .Character => |value| try convertCharacter(value, target, auto, allocator),
        .String => |value| try convertString(value, target, auto, allocator),
        .Error => |value| try convertError(value, target, auto, allocator),
        .Type => |value| try convertType(value, target, auto, allocator),
        .Reference => |value| try convertReference(value, target, auto, allocator),
        .List => |value| try convertList(value, target, auto, allocator),
    };

    if (result) |element| {
        return results.OperationResult{ .success = element };
    } else {
        return results.OperationResult{ .failure = try results.Signal.conversionOperationError(left, target, allocator) };
    }
}

fn convertNull(target: *const values.TypeValue, allocator: std.mem.Allocator) InternalError!?results.Element {
    if (!target.is_nullable) {
        return null;
    }

    return switch (target.kind) {
        .Null, .Any => results.Element.init(values.Value{ .Null = {} }),
        .Int => results.Element.init(values.Value{ .Integer = null }),
        .UnsignedInt => results.Element.init(values.Value{ .UnsignedInteger = null }),
        .Float => results.Element.init(values.Value{ .Float = null }),
        .Bool => results.Element.init(values.Value{ .Boolean = null }),
        .Char => results.Element.init(values.Value{ .Character = null }),
        .String => results.Element.init(values.Value{ .String = null }),
        .Error => blk: {
            const err = allocator.create(values.ErrorValue) catch return InternalError.OutOfMemory;
            err.name = null;
            err.details = null;
            err.stack_trace = .empty;
            break :blk results.Element.init(values.Value{ .Error = err });
        },
        .Type => blk: {
            const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
            t.is_nullable = target.is_nullable;
            t.contained = .empty;
            t.kind = TypeBytecode.Null;
            break :blk results.Element.init(values.Value{ .Type = t });
        },
        .Reference => blk: {
            const r = allocator.create(values.ReferenceValue) catch return InternalError.OutOfMemory;
            r.index = null;
            r.type = try target.contained.items[0].clone(allocator);
            break :blk results.Element.init(values.Value{ .Reference = r });
        },
        .List => blk: {
            const l = allocator.create(values.ListValue) catch return InternalError.OutOfMemory;
            l.items = null;
            l.type = try target.contained.items[0].clone(allocator);
            break :blk results.Element.init(values.Value{ .List = l });
        },
    };
}

fn convertInteger(left: ?i64, target: *const values.TypeValue, auto: bool, allocator: std.mem.Allocator) InternalError!?results.Element {
    if (left) |left_value| {
        return switch (target.kind) {
            .Any, .Int => results.Element.init(values.Value{ .Integer = left_value }),
            .UnsignedInt => if (left_value < 0) null else results.Element.init(values.Value{ .UnsignedInteger = @intCast(left_value) }),
            .Float => results.Element.init(values.Value{ .Float = @floatFromInt(left_value) }),
            .Bool => results.Element.init(values.Value{ .Boolean = left_value != 0 }),
            .Char => if (left_value < 0 or left_value > std.math.maxInt(u32)) null else results.Element.init(values.Value{ .Character = @intCast(left_value) }),

            .String => if (auto) null else results.Element.init(values.Value{ .String = allocator.print("{}", .{left_value}) catch return InternalError.OutOfMemory }),
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = target.is_nullable;
                t.contained = .empty;
                t.kind = TypeBytecode.Int;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    } else {
        if (!target.is_nullable) return null;
        return switch (target.kind) {
            .Any, .Int => results.Element.init(values.Value{ .Integer = null }),
            .UnsignedInt => results.Element.init(values.Value{ .UnsignedInteger = null }),
            .Float => results.Element.init(values.Value{ .Float = null }),
            .Bool => results.Element.init(values.Value{ .Boolean = null }),
            .Char => results.Element.init(values.Value{ .Character = null }),

            .String => if (auto) null else results.Element.init(values.Value{ .String = null }),
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = false;
                t.contained = .empty;
                t.kind = TypeBytecode.Int;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    }
}

fn convertUnsignedInteger(left: ?u64, target: *const values.TypeValue, auto: bool, allocator: std.mem.Allocator) InternalError!?results.Element {
    if (left) |left_value| {
        return switch (target.kind) {
            .Any, .UnsignedInt => results.Element.init(values.Value{ .UnsignedInteger = left_value }),
            .Int => if (left_value > std.math.maxInt(i64)) null else results.Element.init(values.Value{ .Integer = @intCast(left_value) }),
            .Float => results.Element.init(values.Value{ .Float = @floatFromInt(left_value) }),
            .Bool => results.Element.init(values.Value{ .Boolean = left_value != 0 }),
            .Char => if (left_value > std.math.maxInt(u32)) null else results.Element.init(values.Value{ .Character = @intCast(left_value) }),

            .String => if (auto) null else results.Element.init(values.Value{ .String = allocator.print("{}", .{left_value}) catch return InternalError.OutOfMemory }),
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = target.is_nullable;
                t.contained = .empty;
                t.kind = TypeBytecode.UnsignedInt;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    } else {
        if (!target.is_nullable) return null;
        return switch (target.kind) {
            .Any, .UnsignedInt => results.Element.init(values.Value{ .UnsignedInteger = null }),
            .Int => results.Element.init(values.Value{ .Integer = null }),
            .Float => results.Element.init(values.Value{ .Float = null }),
            .Bool => results.Element.init(values.Value{ .Boolean = null }),
            .Char => results.Element.init(values.Value{ .Character = null }),

            .String => if (auto) null else results.Element.init(values.Value{ .String = null }),
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = false;
                t.contained = .empty;
                t.kind = TypeBytecode.UnsignedInt;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    }
}

fn convertFloat(left: ?f64, target: *const values.TypeValue, auto: bool, allocator: std.mem.Allocator) InternalError!?results.Element {
    if (left) |left_value| {
        return switch (target.kind) {
            .Any, .Float => results.Element.init(values.Value{ .Float = left_value }),
            .Int => results.Element.init(values.Value{ .Integer = @intFromFloat(left_value) }),
            .UnsignedInt => if (left_value < 0.0) null else results.Element.init(values.Value{ .UnsignedInteger = @intFromFloat(left_value) }),
            .Bool => results.Element.init(values.Value{ .Boolean = left_value != 0.0 }),

            .Char => if (auto or left_value < 0.0) null else results.Element.init(values.Value{ .Character = @intFromFloat(left_value) }),
            .String => if (auto) null else results.Element.init(values.Value{ .String = allocator.print("{}", .{left_value}) catch return InternalError.OutOfMemory }),
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = target.is_nullable;
                t.contained = .empty;
                t.kind = TypeBytecode.Float;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    } else {
        if (!target.is_nullable) return null;
        return switch (target.kind) {
            .Any, .Float => results.Element.init(values.Value{ .Float = null }),
            .Int => results.Element.init(values.Value{ .Integer = null }),
            .UnsignedInt => results.Element.init(values.Value{ .UnsignedInteger = null }),
            .Bool => results.Element.init(values.Value{ .Boolean = null }),

            .Char => if (auto) null else results.Element.init(values.Value{ .Character = null }),
            .String => if (auto) null else results.Element.init(values.Value{ .String = null }),
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = false;
                t.contained = .empty;
                t.kind = TypeBytecode.Float;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    }
}

fn convertBoolean(left: ?bool, target: *const values.TypeValue, auto: bool, allocator: std.mem.Allocator) InternalError!?results.Element {
    if (left) |left_value| {
        return switch (target.kind) {
            .Any, .Bool => results.Element.init(values.Value{ .Boolean = left_value }),
            .Int => results.Element.init(values.Value{ .Integer = @intFromBool(left_value) }),
            .UnsignedInt => results.Element.init(values.Value{ .UnsignedInteger = @intFromBool(left_value) }),
            .Float => results.Element.init(values.Value{ .Float = @floatFromInt(@intFromBool(left_value)) }),

            .Char => if (auto) null else results.Element.init(values.Value{ .Character = @intFromBool(left_value) }),
            .String => if (auto) null else results.Element.init(values.Value{ .String = allocator.print("{}", .{left_value}) catch return InternalError.OutOfMemory }),
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = target.is_nullable;
                t.contained = .empty;
                t.kind = TypeBytecode.Bool;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    } else {
        if (!target.is_nullable) return null;
        return switch (target.kind) {
            .Any, .Bool => results.Element.init(values.Value{ .Boolean = null }),
            .Int => results.Element.init(values.Value{ .Integer = null }),
            .UnsignedInt => results.Element.init(values.Value{ .UnsignedInteger = null }),
            .Float => results.Element.init(values.Value{ .Float = null }),

            .Char => if (auto) null else results.Element.init(values.Value{ .Character = null }),
            .String => if (auto) null else results.Element.init(values.Value{ .String = null }),
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = false;
                t.contained = .empty;
                t.kind = TypeBytecode.Bool;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    }
}

fn convertCharacter(left: ?u32, target: *const values.TypeValue, auto: bool, allocator: std.mem.Allocator) InternalError!?results.Element {
    if (left) |left_value| {
        return switch (target.kind) {
            .Any, .Char => results.Element.init(values.Value{ .Character = left_value }),
            .Int => results.Element.init(values.Value{ .Integer = @intCast(left_value) }),
            .UnsignedInt => results.Element.init(values.Value{ .UnsignedInteger = @intCast(left_value) }),
            .Float => results.Element.init(values.Value{ .Float = @floatFromInt(left_value) }),

            .Bool => if (auto) null else results.Element.init(values.Value{ .Boolean = left_value != 0 }),
            .String => if (auto) null else blk: {
                var buffer: [4]u8 = undefined;
                const result = allocator.print("{s}", .{characterToUTF8(left_value, &buffer)}) catch return InternalError.OutOfMemory;
                break :blk results.Element.init(values.Value{ .String = result });
            },
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = target.is_nullable;
                t.contained = .empty;
                t.kind = TypeBytecode.Char;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    } else {
        if (!target.is_nullable) return null;
        return switch (target.kind) {
            .Any, .Char => results.Element.init(values.Value{ .Character = null }),
            .Int => results.Element.init(values.Value{ .Integer = null }),
            .UnsignedInt => results.Element.init(values.Value{ .UnsignedInteger = null }),
            .Float => results.Element.init(values.Value{ .Float = null }),

            .Bool => if (auto) null else results.Element.init(values.Value{ .Boolean = null }),
            .String => if (auto) null else results.Element.init(values.Value{ .String = null }),
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = false;
                t.contained = .empty;
                t.kind = TypeBytecode.Char;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    }
}

fn convertString(left: ?[]const u8, target: *const values.TypeValue, auto: bool, allocator: std.mem.Allocator) InternalError!?results.Element {
    if (left) |left_value| {
        return switch (target.kind) {
            .Any, .String => results.Element.init(values.Value{ .String = allocator.dupe(u8, left_value) catch return InternalError.OutOfMemory }),

            .Bool => if (auto) null else results.Element.init(values.Value{ .Boolean = left_value.len > 0 }),
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = false;
                t.contained = .empty;
                t.kind = TypeBytecode.String;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    } else {
        if (!target.is_nullable) return null;
        return switch (target.kind) {
            .Any, .String => results.Element.init(values.Value{ .String = null }),

            .Bool => if (auto) null else results.Element.init(values.Value{ .Boolean = null }),
            .Type => if (auto) null else blk: {
                const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
                t.is_nullable = false;
                t.contained = .empty;
                t.kind = TypeBytecode.String;
                break :blk results.Element.init(values.Value{ .Type = t });
            },

            else => null,
        };
    }
}

fn convertError(left: *const values.ErrorValue, target: *const values.TypeValue, auto: bool, allocator: std.mem.Allocator) InternalError!?results.Element {
    if (left.name == null and !target.is_nullable and target.kind != .Bool and target.kind != .String and target.kind != .Type) {
        return null;
    }

    return switch (target.kind) {
        .Any, .Error => blk: {
            const err = allocator.create(values.ErrorValue) catch return InternalError.OutOfMemory;
            err.* = try left.clone(allocator);
            break :blk results.Element.init(values.Value{ .Error = err });
        },

        .Bool => if (auto) null else results.Element.init(values.Value{ .Boolean = left.name != null }),
        .String => if (auto) null else results.Element.init(values.Value{ .String = try repr.reprError(left, allocator) }),
        .Type => if (auto) null else blk: {
            const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
            t.is_nullable = false;
            t.contained = .empty;
            t.kind = TypeBytecode.Error;
            break :blk results.Element.init(values.Value{ .Type = t });
        },

        else => null,
    };
}

fn convertType(left: *const values.TypeValue, target: *const values.TypeValue, auto: bool, allocator: std.mem.Allocator) InternalError!?results.Element {
    return switch (target.kind) {
        .Any => blk: {
            const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
            t.* = try left.clone(allocator);
            break :blk results.Element.init(values.Value{ .Type = t });
        },

        .Type => blk: {
            const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
            t.is_nullable = false;
            t.contained = .empty;
            t.kind = TypeBytecode.Type;
            break :blk results.Element.init(values.Value{ .Type = t });
        },

        .Bool => if (auto) null else results.Element.init(values.Value{ .Boolean = true }),
        .String => if (auto) null else results.Element.init(values.Value{ .String = try repr.reprType(left, allocator) }),

        else => null,
    };
}

fn convertReference(left: *const values.ReferenceValue, target: *const values.TypeValue, auto: bool, allocator: std.mem.Allocator) InternalError!?results.Element {
    return switch (target.kind) {
        .Any => blk: {
            const r = allocator.create(values.ReferenceValue) catch return InternalError.OutOfMemory;
            r.* = try left.clone(allocator);
            break :blk results.Element.init(values.Value{ .Reference = r });
        },

        .Reference => blk: {
            const target_inner = &target.contained.items[0];
            if (left.index == null and !target.is_nullable) break :blk null;
            if (!target_inner.canCollect(&left.type)) break :blk null;

            const r = allocator.create(values.ReferenceValue) catch return InternalError.OutOfMemory;
            r.* = try left.clone(allocator);
            break :blk results.Element.init(values.Value{ .Reference = r });
        },

        .Bool => if (auto) null else results.Element.init(values.Value{ .Boolean = left.index != null }),
        .String => if (auto) null else results.Element.init(values.Value{ .String = if (left.index) |index| allocator.print("@{}", .{index}) catch return InternalError.OutOfMemory else null }),
        .Type => if (auto) null else blk: {
            const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
            errdefer allocator.destroy(t);
            t.kind = TypeBytecode.Reference;
            t.is_nullable = target.is_nullable;
            t.contained = .empty;
            t.contained.append(allocator, try left.type.clone(allocator)) catch return InternalError.OutOfMemory;
            break :blk results.Element.init(values.Value{ .Type = t });
        },

        else => null,
    };
}

fn convertList(left: *const values.ListValue, target: *const values.TypeValue, auto: bool, allocator: std.mem.Allocator) InternalError!?results.Element {
    return switch (target.kind) {
        .Any => blk: {
            const l = allocator.create(values.ListValue) catch return InternalError.OutOfMemory;
            l.* = try left.clone(allocator);
            break :blk results.Element.init(values.Value{ .List = l });
        },

        .List => blk: {
            const target_inner = &target.contained.items[0];

            // Si la liste source est nulle
            if (left.items == null) {
                if (!target.is_nullable) break :blk null;
                const l = allocator.create(values.ListValue) catch return InternalError.OutOfMemory;
                errdefer allocator.destroy(l);
                l.items = null;
                l.type = try target_inner.clone(allocator);
                break :blk results.Element.init(values.Value{ .List = l });
            }

            // Si les types d'éléments sont directement collectables (ex: list<int!> -> list<int>)
            if (target_inner.canCollect(&left.type)) {
                const l = allocator.create(values.ListValue) catch return InternalError.OutOfMemory;
                errdefer allocator.destroy(l);
                l.* = try left.clone(allocator);
                break :blk results.Element.init(values.Value{ .List = l });
            }

            // Sinon, conversion élément par élément (ex: list<int> -> list<float>, list<list<int>> -> list<list<float>>, etc.)
            const src_items = left.items.?.items;
            var new_items = std.ArrayList(values.Value).initCapacity(allocator, src_items.len) catch return InternalError.OutOfMemory;
            errdefer {
                for (new_items.items) |*item| item.deinit(allocator);
                new_items.deinit(allocator);
            }

            for (src_items) |item| {
                const item_elem = results.Element.init(item);
                var converted_res = try convert(&item_elem, target_inner, auto, allocator);
                switch (converted_res) {
                    .success => |elem| new_items.appendAssumeCapacity(elem.value),
                    .failure => {
                        const operations = @import("../operations.zig");
                        operations.delete.deleteResult(&converted_res, allocator);
                        for (new_items.items) |*it| it.deinit(allocator);
                        new_items.deinit(allocator);
                        break :blk null;
                    },
                }
            }

            const l = allocator.create(values.ListValue) catch return InternalError.OutOfMemory;
            errdefer allocator.destroy(l);
            l.items = new_items;
            l.type = try target_inner.clone(allocator);
            break :blk results.Element.init(values.Value{ .List = l });
        },

        .Bool => if (auto) null else results.Element.init(values.Value{ .Boolean = left.items != null and left.items.?.items.len > 0 }),
        .String => if (auto) null else results.Element.init(values.Value{ .String = try repr.reprList(left, allocator) }),
        .Type => if (auto) null else blk: {
            const t = allocator.create(values.TypeValue) catch return InternalError.OutOfMemory;
            errdefer allocator.destroy(t);
            t.kind = TypeBytecode.List;
            t.is_nullable = target.is_nullable;
            t.contained = .empty;
            t.contained.append(allocator, try left.type.clone(allocator)) catch return InternalError.OutOfMemory;
            break :blk results.Element.init(values.Value{ .Type = t });
        },

        else => null,
    };
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "convert Null to nullable and non-nullable targets" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Null = {} },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Null -> Int non-nullable => failure
    {
        var target = values.TypeValue{ .kind = TypeBytecode.Int, .is_nullable = false, .contained = .empty };
        defer target.deinit(allocator);
        var res = try convert(&left, &target, true, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .failure);
    }

    // 2. Null -> Int nullable => success (Integer = null)
    {
        var target = values.TypeValue{ .kind = TypeBytecode.Int, .is_nullable = true, .contained = .empty };
        defer target.deinit(allocator);
        var res = try convert(&left, &target, true, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .success);
        try std.testing.expect(res.success.value.Integer == null);
    }

    // 3. Null -> List<Int> nullable => success (List with items = null)
    {
        var contained: std.ArrayList(values.TypeValue) = .empty;
        try contained.append(allocator, values.TypeValue{ .kind = TypeBytecode.Int, .is_nullable = false, .contained = .empty });

        var target = values.TypeValue{ .kind = TypeBytecode.List, .is_nullable = true, .contained = contained };
        defer target.deinit(allocator);

        var res = try convert(&left, &target, true, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .success);
        try std.testing.expect(res.success.value.List.items == null);
        try std.testing.expectEqual(TypeBytecode.Int, res.success.value.List.type.kind);
    }
}

test "convert Integer auto vs explicit" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Integer = 65 },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // 1. Int -> Float (auto = true)
    {
        var target = values.TypeValue{ .kind = TypeBytecode.Float, .is_nullable = false, .contained = .empty };
        defer target.deinit(allocator);
        var res = try convert(&left, &target, true, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?f64, 65.0), res.success.value.Float);
    }

    // 2. Int -> String (auto = true -> failure, auto = false -> "65")
    {
        var target = values.TypeValue{ .kind = TypeBytecode.String, .is_nullable = false, .contained = .empty };
        defer target.deinit(allocator);

        var res_auto = try convert(&left, &target, true, allocator);
        defer operations.delete.deleteResult(&res_auto, allocator);
        try std.testing.expect(res_auto == .failure);

        var res_exp = try convert(&left, &target, false, allocator);
        defer operations.delete.deleteResult(&res_exp, allocator);
        try std.testing.expectEqualStrings("65", res_exp.success.value.String.?);
    }

    // 3. Int -> Char ('A')
    {
        var target = values.TypeValue{ .kind = TypeBytecode.Char, .is_nullable = false, .contained = .empty };
        defer target.deinit(allocator);
        var res = try convert(&left, &target, false, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expectEqual(@as(?u32, 'A'), res.success.value.Character);
    }

    // 4. Int -> Type (explicit only)
    {
        var target = values.TypeValue{ .kind = TypeBytecode.Type, .is_nullable = false, .contained = .empty };
        defer target.deinit(allocator);
        var res = try convert(&left, &target, false, allocator);
        defer operations.delete.deleteResult(&res, allocator);
        try std.testing.expect(res == .success);
        try std.testing.expectEqual(TypeBytecode.Int, res.success.value.Type.kind);
    }
}

test "convert Float, Boolean, Character, and String" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // Float -> Int (truncation) & String
    {
        var f = results.Element{ .modifier = .{}, .value = values.Value{ .Float = 42.9 } };
        defer operations.delete.deleteElement(&f, allocator);

        var t_int = values.TypeValue{ .kind = TypeBytecode.Int, .is_nullable = false, .contained = .empty };
        defer t_int.deinit(allocator);
        var res_int = try convert(&f, &t_int, false, allocator);
        defer operations.delete.deleteResult(&res_int, allocator);
        try std.testing.expectEqual(@as(?i64, 42), res_int.success.value.Integer);
    }

    // Boolean -> Int, String
    {
        var b = results.Element{ .modifier = .{}, .value = values.Value{ .Boolean = true } };
        defer operations.delete.deleteElement(&b, allocator);

        var t_int = values.TypeValue{ .kind = TypeBytecode.Int, .is_nullable = false, .contained = .empty };
        defer t_int.deinit(allocator);
        var res_int = try convert(&b, &t_int, true, allocator);
        defer operations.delete.deleteResult(&res_int, allocator);
        try std.testing.expectEqual(@as(?i64, 1), res_int.success.value.Integer);

        var t_str = values.TypeValue{ .kind = TypeBytecode.String, .is_nullable = false, .contained = .empty };
        defer t_str.deinit(allocator);
        var res_str = try convert(&b, &t_str, false, allocator);
        defer operations.delete.deleteResult(&res_str, allocator);
        try std.testing.expectEqualStrings("true", res_str.success.value.String.?);
    }

    // Character ('€' = 0x20AC) -> String
    {
        var c = results.Element{ .modifier = .{}, .value = values.Value{ .Character = 0x20AC } };
        defer operations.delete.deleteElement(&c, allocator);

        var t_str = values.TypeValue{ .kind = TypeBytecode.String, .is_nullable = false, .contained = .empty };
        defer t_str.deinit(allocator);
        var res_str = try convert(&c, &t_str, false, allocator);
        defer operations.delete.deleteResult(&res_str, allocator);
        try std.testing.expectEqualStrings("€", res_str.success.value.String.?);
    }

    // String -> Bool (non-empty vs empty)
    {
        var s_nonempty = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "hi") } };
        defer operations.delete.deleteElement(&s_nonempty, allocator);

        var s_empty = results.Element{ .modifier = .{}, .value = values.Value{ .String = try allocator.dupe(u8, "") } };
        defer operations.delete.deleteElement(&s_empty, allocator);

        var t_bool = values.TypeValue{ .kind = TypeBytecode.Bool, .is_nullable = false, .contained = .empty };
        defer t_bool.deinit(allocator);

        var res1 = try convert(&s_nonempty, &t_bool, false, allocator);
        defer operations.delete.deleteResult(&res1, allocator);
        try std.testing.expectEqual(@as(?bool, true), res1.success.value.Boolean);

        var res2 = try convert(&s_empty, &t_bool, false, allocator);
        defer operations.delete.deleteResult(&res2, allocator);
        try std.testing.expectEqual(@as(?bool, false), res2.success.value.Boolean);
    }
}

test "convert List<Int> to List<Float> element-wise conversion" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    var src_items = std.ArrayList(values.Value).empty;
    try src_items.append(allocator, values.Value{ .Integer = 1 });
    try src_items.append(allocator, values.Value{ .Integer = -2 });
    try src_items.append(allocator, values.Value{ .Integer = 10 });

    const list_val = try allocator.create(values.ListValue);
    list_val.* = values.ListValue{
        .items = src_items,
        .type = values.TypeValue{
            .kind = TypeBytecode.Int,
            .is_nullable = false,
            .contained = .empty,
        },
    };

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .List = list_val },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // Target: list<float!>
    var target_contained: std.ArrayList(values.TypeValue) = .empty;
    try target_contained.append(allocator, values.TypeValue{
        .kind = TypeBytecode.Float,
        .is_nullable = false,
        .contained = .empty,
    });
    var target = values.TypeValue{
        .kind = TypeBytecode.List,
        .is_nullable = false,
        .contained = target_contained,
    };
    defer target.deinit(allocator);

    var res = try convert(&left, &target, true, allocator);
    defer operations.delete.deleteResult(&res, allocator);

    try std.testing.expect(res == .success);
    const out_list = res.success.value.List;
    try std.testing.expectEqual(TypeBytecode.Float, out_list.type.kind);
    try std.testing.expectEqual(@as(usize, 3), out_list.items.?.items.len);
    try std.testing.expectEqual(@as(?f64, 1.0), out_list.items.?.items[0].Float);
    try std.testing.expectEqual(@as(?f64, -2.0), out_list.items.?.items[1].Float);
    try std.testing.expectEqual(@as(?f64, 10.0), out_list.items.?.items[2].Float);
}

test "convert nested List<List<Int>> to List<List<String>> and failure cleanup" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    // Inner list: [10, 20]
    var inner_items = std.ArrayList(values.Value).empty;
    try inner_items.append(allocator, values.Value{ .Integer = 10 });
    try inner_items.append(allocator, values.Value{ .Integer = 20 });

    const inner_list = try allocator.create(values.ListValue);
    inner_list.* = values.ListValue{
        .items = inner_items,
        .type = values.TypeValue{ .kind = TypeBytecode.Int, .is_nullable = false, .contained = .empty },
    };

    // Outer list: [[10, 20]]
    var outer_items = std.ArrayList(values.Value).empty;
    try outer_items.append(allocator, values.Value{ .List = inner_list });

    var outer_inner_type: std.ArrayList(values.TypeValue) = .empty;
    try outer_inner_type.append(allocator, values.TypeValue{ .kind = TypeBytecode.Int, .is_nullable = false, .contained = .empty });

    const outer_list = try allocator.create(values.ListValue);
    outer_list.* = values.ListValue{
        .items = outer_items,
        .type = values.TypeValue{ .kind = TypeBytecode.List, .is_nullable = false, .contained = outer_inner_type },
    };

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .List = outer_list },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // Target: list<list<string!>!>
    var target_str_list: std.ArrayList(values.TypeValue) = .empty;
    try target_str_list.append(allocator, values.TypeValue{ .kind = TypeBytecode.String, .is_nullable = false, .contained = .empty });

    var target_outer_contained: std.ArrayList(values.TypeValue) = .empty;
    try target_outer_contained.append(allocator, values.TypeValue{
        .kind = TypeBytecode.List,
        .is_nullable = false,
        .contained = target_str_list,
    });

    var target = values.TypeValue{
        .kind = TypeBytecode.List,
        .is_nullable = false,
        .contained = target_outer_contained,
    };
    defer target.deinit(allocator);

    // 1. Auto = true -> doit échouer sans fuite mémoire (Int -> String interdit en auto)
    {
        var res_auto = try convert(&left, &target, true, allocator);
        defer operations.delete.deleteResult(&res_auto, allocator);
        try std.testing.expect(res_auto == .failure);
    }

    // 2. Auto = false -> réussit et convertit récursivement en [["10", "20"]]
    {
        var res_exp = try convert(&left, &target, false, allocator);
        defer operations.delete.deleteResult(&res_exp, allocator);
        try std.testing.expect(res_exp == .success);

        const converted_outer = res_exp.success.value.List;
        const converted_inner = converted_outer.items.?.items[0].List;
        try std.testing.expectEqualStrings("10", converted_inner.items.?.items[0].String.?);
        try std.testing.expectEqualStrings("20", converted_inner.items.?.items[1].String.?);
    }
}

test "convert Reference compatibility and Type conversion" {
    const operations = @import("../operations.zig");
    const allocator = std.testing.allocator;

    const ref_val = try allocator.create(values.ReferenceValue);
    ref_val.* = values.ReferenceValue{
        .index = 7,
        .type = values.TypeValue{ .kind = TypeBytecode.Int, .is_nullable = false, .contained = .empty },
    };

    var left = results.Element{
        .modifier = .{},
        .value = values.Value{ .Reference = ref_val },
    };
    defer operations.delete.deleteElement(&left, allocator);

    // Target: reference<int> (nullable) -> compatible via canCollect
    var target_contained: std.ArrayList(values.TypeValue) = .empty;
    try target_contained.append(allocator, values.TypeValue{ .kind = TypeBytecode.Int, .is_nullable = true, .contained = .empty });

    var target = values.TypeValue{
        .kind = TypeBytecode.Reference,
        .is_nullable = false,
        .contained = target_contained,
    };
    defer target.deinit(allocator);

    var res = try convert(&left, &target, true, allocator);
    defer operations.delete.deleteResult(&res, allocator);
    try std.testing.expect(res == .success);
    try std.testing.expectEqual(@as(?u32, 7), res.success.value.Reference.index);

    // Target: String (explicit) -> "@7"
    var target_str = values.TypeValue{ .kind = TypeBytecode.String, .is_nullable = false, .contained = .empty };
    defer target_str.deinit(allocator);

    var res_str = try convert(&left, &target_str, false, allocator);
    defer operations.delete.deleteResult(&res_str, allocator);
    try std.testing.expectEqualStrings("@7", res_str.success.value.String.?);
}
