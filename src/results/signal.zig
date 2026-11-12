const std = @import("std");
const values = @import("../values.zig");
const repr = @import("../operations.zig").repr;
const type_repr = @import("../operations.zig").type_repr;
const InternalError = @import("../utils.zig").InternalError;
const Element = @import("element.zig").Element;

const OPERATION_ERROR_NAME: []const u8 = "OperationError";

pub const SignalModifier = packed struct(u8) {
    ERROR: bool = false,
    BREAK: bool = false,
    CONTINUE: bool = false,
    RETURN: bool = false,
    TERMINATE: bool = false,
    _reserved: u3 = 0,
};

pub const Signal = struct {
    modifier: SignalModifier,
    value: values.Value,

    pub fn getValue(self: *const Signal) *const values.Value {
        return &self.value;
    }

    pub fn addTrace(self: *Signal, trace: []const u8, allocator: std.mem.Allocator) InternalError!void {
        if (self.value == .Error) {
            self.value.Error.?.stack_trace.append(allocator, trace) catch return InternalError.OutOfMemory;
        }
    }

    pub fn nullOperationError(operation: []const u8, allocator: std.mem.Allocator) InternalError!Signal {
        const errorValue = allocator.create(values.ErrorValue) catch return InternalError.OutOfMemory;
        errdefer allocator.destroy(errorValue);

        errorValue.name = allocator.dupe(u8, OPERATION_ERROR_NAME) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.name.?);

        errorValue.details = allocator.print("Cannot perform operation `{s}` with a null operand", .{operation}) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.details.?);

        errorValue.stack_trace = .empty;

        return Signal{
            .modifier = SignalModifier{ .ERROR = true },
            .value = values.Value{ .Error = errorValue },
        };
    }

    pub fn constantOperationError(operation: []const u8, allocator: std.mem.Allocator) InternalError!Signal {
        const errorValue = allocator.create(values.ErrorValue) catch return InternalError.OutOfMemory;
        errdefer allocator.destroy(errorValue);

        errorValue.name = allocator.dupe(u8, OPERATION_ERROR_NAME) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.name.?);

        errorValue.details = allocator.print("Cannot perform operation `{s}` with a constant operand", .{operation}) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.details.?);

        errorValue.stack_trace = .empty;

        return Signal{
            .modifier = SignalModifier{ .ERROR = true },
            .value = values.Value{ .Error = errorValue },
        };
    }

    pub fn notNullableOperationError(allocator: std.mem.Allocator) InternalError!Signal {
        return try createSimpleError("Cannot assign `null` to a not nullable value", allocator);
    }

    pub fn negativeRightOperandError(allocator: std.mem.Allocator) InternalError!Signal {
        return try createSimpleError("Cannot perform this operation with a negative right operand", allocator);
    }

    pub fn zeroDivisionOperationError(allocator: std.mem.Allocator) InternalError!Signal {
        return try createSimpleError("Cannot divide by zero", allocator);
    }

    pub fn unaryOperationError(operation: []const u8, operand: *const Element, allocator: std.mem.Allocator) InternalError!Signal {
        const operand_repr = try repr(operand, allocator);
        defer allocator.free(operand_repr);

        const errorValue = allocator.create(values.ErrorValue) catch return InternalError.OutOfMemory;
        errdefer allocator.destroy(errorValue);

        errorValue.name = allocator.dupe(u8, OPERATION_ERROR_NAME) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.name.?);

        errorValue.details = allocator.print("Binary operation `{s}` is not defined for type <{s}>", .{ operation, operand_repr }) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.details.?);

        errorValue.stack_trace = .empty;

        return Signal{
            .modifier = SignalModifier{ .ERROR = true },
            .value = values.Value{ .Error = errorValue },
        };
    }

    pub fn binaryOperationError(operation: []const u8, left: *const Element, right: *const Element, allocator: std.mem.Allocator) InternalError!Signal {
        const left_repr = try repr(left, allocator);
        defer allocator.free(left_repr);

        const right_repr = try repr(right, allocator);
        defer allocator.free(right_repr);

        const errorValue = allocator.create(values.ErrorValue) catch return InternalError.OutOfMemory;
        errdefer allocator.destroy(errorValue);

        errorValue.name = allocator.dupe(u8, OPERATION_ERROR_NAME) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.name.?);

        errorValue.details = allocator.print("Binary operation `{s}` is not defined for types <{s}> and <{s}>", .{ operation, left_repr, right_repr }) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.details.?);

        errorValue.stack_trace = .empty;

        return Signal{
            .modifier = SignalModifier{ .ERROR = true },
            .value = values.Value{ .Error = errorValue },
        };
    }

    pub fn conversionOperationError(left: *const Element, target: *const values.TypeValue, allocator: std.mem.Allocator) InternalError!Signal {
        const left_type_repr = try type_repr.typeRepr(left, allocator);
        defer allocator.free(left_type_repr);

        const target_repr = try type_repr.typeReprType(target, allocator);
        defer allocator.free(target_repr);

        const errorValue = allocator.create(values.ErrorValue) catch return InternalError.OutOfMemory;
        errdefer allocator.destroy(errorValue);

        errorValue.name = allocator.dupe(u8, OPERATION_ERROR_NAME) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.name.?);

        errorValue.details = allocator.print("Cannot cast from type <{s}> to type <{s}>", .{ left_type_repr, target_repr }) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.details.?);

        errorValue.stack_trace = .empty;

        return Signal{
            .modifier = SignalModifier{ .ERROR = true },
            .value = values.Value{ .Error = errorValue },
        };
    }

    fn createSimpleError(name: []const u8, allocator: std.mem.Allocator) InternalError!Signal {
        const errorValue = allocator.create(values.ErrorValue) catch return InternalError.OutOfMemory;
        errdefer allocator.destroy(errorValue);

        errorValue.name = allocator.dupe(u8, OPERATION_ERROR_NAME) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.name.?);

        errorValue.details = allocator.print("{s}", .{name}) catch return InternalError.OutOfMemory;
        errdefer allocator.free(errorValue.details.?);

        errorValue.stack_trace = .empty;
        return Signal{
            .modifier = SignalModifier{ .ERROR = true },
            .value = values.Value{ .Error = errorValue },
        };
    }
};
