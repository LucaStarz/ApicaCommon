const std = @import("std");
const utils = @import("../utils.zig");
const structs = @import("structs.zig");
const InternalError = @import("../utils.zig").InternalError;

pub const Value = union(enum) {
    Null: void,
    Integer: ?i64,
    UnsignedInteger: ?u64,
    Float: ?f64,
    Boolean: ?bool,
    Character: ?u32,
    String: ?[]const u8,
    Error: *structs.ErrorValue,
    Type: *structs.TypeValue,
    Reference: *structs.ReferenceValue,
    List: *structs.ListValue,

    pub fn clone(self: *const Value, allocator: std.mem.Allocator) InternalError!Value {
        return switch (self.*) {
            .Null => Value{ .Null = {} },
            .Integer => |value| Value{ .Integer = value },
            .UnsignedInteger => |value| Value{ .UnsignedInteger = value },
            .Float => |value| Value{ .Float = value },
            .Boolean => |value| Value{ .Boolean = value },
            .Character => |value| Value{ .Character = value },
            .String => |value| Value{
                .String = if (value) |string| allocator.dupe(u8, string) catch return InternalError.OutOfMemory else null,
            },
            .Error => |value| blk: {
                const ptr = allocator.create(structs.ErrorValue) catch return InternalError.OutOfMemory;
                errdefer allocator.destroy(ptr);
                ptr.* = try value.clone(allocator);
                break :blk Value{ .Error = ptr };
            },
            .Type => |value| blk: {
                const ptr = allocator.create(structs.TypeValue) catch return InternalError.OutOfMemory;
                errdefer allocator.destroy(ptr);
                ptr.* = try value.clone(allocator);
                break :blk Value{ .Type = ptr };
            },
            .Reference => |value| blk: {
                const ptr = allocator.create(structs.ReferenceValue) catch return InternalError.OutOfMemory;
                errdefer allocator.destroy(ptr);
                ptr.* = try value.clone(allocator);
                break :blk Value{ .Reference = ptr };
            },
            .List => |value| blk: {
                const ptr = allocator.create(structs.ListValue) catch return InternalError.OutOfMemory;
                errdefer allocator.destroy(ptr);
                ptr.* = try value.clone(allocator);
                break :blk Value{ .List = ptr };
            },
        };
    }

    pub fn deinit(self: *const Value, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .String => |v| {
                if (v) |s| allocator.free(s);
            },
            .Error => |v| {
                v.deinit(allocator);
                allocator.destroy(v);
            },
            .Type => |v| {
                v.deinit(allocator);
                allocator.destroy(v);
            },
            .Reference => |v| {
                v.deinit(allocator);
                allocator.destroy(v);
            },
            .List => |v| {
                v.deinit(allocator);
                allocator.destroy(v);
            },
            else => {},
        }
    }

    pub fn isNull(self: *const Value) bool {
        return switch (self.*) {
            .Null => true,
            .Integer => |value| value == null,
            .UnsignedInteger => |value| value == null,
            .Float => |value| value == null,
            .Boolean => |value| value == null,
            .Character => |value| value == null,
            .String => |value| value == null,
            .Error => |value| value.name == null,
            .Type => false,
            .Reference => |value| value.index == null,
            .List => |value| value.items == null,
        };
    }
};
