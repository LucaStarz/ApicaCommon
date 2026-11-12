const std = @import("std");
const Value = @import("value.zig").Value;
const TypeBytecode = @import("../bytecodes/type.zig").TypeBytecode;
const InternalError = @import("../utils.zig").InternalError;

pub const ErrorValue = struct {
    name: ?[]const u8,
    details: ?[]const u8,
    stack_trace: std.ArrayList([]const u8),

    pub fn clone(self: *const ErrorValue, allocator: std.mem.Allocator) InternalError!ErrorValue {
        const copy_name = if (self.name) |n|
            allocator.dupe(u8, n) catch return InternalError.OutOfMemory
        else
            null;
        errdefer if (copy_name) |n| allocator.free(n);

        const copy_details = if (self.details) |d|
            allocator.dupe(u8, d) catch return InternalError.OutOfMemory
        else
            null;
        errdefer if (copy_details) |d| allocator.free(d);

        var copy_trace = std.ArrayList([]const u8).initCapacity(allocator, self.stack_trace.items.len) catch return InternalError.OutOfMemory;
        errdefer {
            for (copy_trace.items) |frame| allocator.free(frame);
            copy_trace.deinit(allocator);
        }

        for (self.stack_trace.items) |frame| {
            const frame_dupe = allocator.dupe(u8, frame) catch return InternalError.OutOfMemory;
            copy_trace.appendAssumeCapacity(frame_dupe);
        }

        return ErrorValue{
            .name = copy_name,
            .details = copy_details,
            .stack_trace = copy_trace,
        };
    }

    pub fn deinit(self: *ErrorValue, allocator: std.mem.Allocator) void {
        if (self.name) |n| allocator.free(n);
        if (self.details) |d| allocator.free(d);
        for (self.stack_trace.items) |frame| {
            allocator.free(frame);
        }
        self.stack_trace.deinit(allocator);
    }
};

pub const TypeValue = struct {
    kind: TypeBytecode,
    is_nullable: bool,
    contained: std.ArrayList(TypeValue),

    pub fn clone(self: *const TypeValue, allocator: std.mem.Allocator) InternalError!TypeValue {
        var copy = TypeValue{
            .kind = self.kind,
            .is_nullable = self.is_nullable,
            .contained = std.ArrayList(TypeValue).initCapacity(allocator, self.contained.items.len) catch return InternalError.OutOfMemory,
        };
        errdefer {
            for (copy.contained.items) |*item| {
                item.deinit(allocator);
            }
            copy.contained.deinit(allocator);
        }

        for (self.contained.items) |*item| {
            const cloned = try item.clone(allocator);
            copy.contained.appendAssumeCapacity(cloned);
        }

        return copy;
    }

    pub fn deinit(self: *TypeValue, allocator: std.mem.Allocator) void {
        for (self.contained.items) |*item| {
            item.deinit(allocator);
        }
        self.contained.deinit(allocator);
    }

    pub fn equals(self: *const TypeValue, other: *const TypeValue) bool {
        var equality = self.kind == other.kind and self.is_nullable == other.is_nullable and self.contained.items.len == other.contained.items.len;
        if (equality) {
            for (0..self.contained.items.len) |i| {
                equality = equality and self.contained.items[i].equals(&other.contained.items[i]);
                if (!equality) break;
            }
        }

        return equality;
    }

    pub fn canCollect(self: *const TypeValue, other: *const TypeValue) bool {
        var collectable = self.kind == other.kind and (self.is_nullable or !other.is_nullable) and self.contained.items.len == other.contained.items.len;
        if (collectable) {
            for (0..self.contained.items.len) |i| {
                collectable = collectable and self.contained.items[i].canCollect(&other.contained.items[i]);
                if (!collectable) break;
            }
        }

        return collectable;
    }
};

pub const ReferenceValue = struct {
    index: ?u32,
    type: TypeValue,

    pub fn clone(self: *const ReferenceValue, allocator: std.mem.Allocator) InternalError!ReferenceValue {
        return ReferenceValue{
            .index = self.index,
            .type = try self.type.clone(allocator),
        };
    }

    pub fn deinit(self: *ReferenceValue, allocator: std.mem.Allocator) void {
        self.type.deinit(allocator);
    }
};

pub const ListValue = struct {
    items: ?std.ArrayList(Value),
    type: TypeValue,

    pub fn clone(self: *const ListValue, allocator: std.mem.Allocator) InternalError!ListValue {
        var copy_type = try self.type.clone(allocator);
        errdefer copy_type.deinit(allocator);

        var copy_items: ?std.ArrayList(Value) = null;
        if (self.items) |items| {
            var new_items = std.ArrayList(Value).initCapacity(allocator, items.items.len) catch return InternalError.OutOfMemory;
            errdefer {
                for (new_items.items) |*item| {
                    item.deinit(allocator);
                }
                new_items.deinit(allocator);
            }

            for (items.items) |*item| {
                const cloned_item = try item.clone(allocator);
                new_items.appendAssumeCapacity(cloned_item);
            }
            copy_items = new_items;
        }

        return ListValue{
            .items = copy_items,
            .type = copy_type,
        };
    }

    pub fn deinit(self: *ListValue, allocator: std.mem.Allocator) void {
        self.type.deinit(allocator);
        if (self.items) |*items| {
            for (items.items) |*item| {
                item.deinit(allocator);
            }
            items.deinit(allocator);
        }
    }
};
