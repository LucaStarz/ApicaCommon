const std = @import("std");
const utils = @import("../utils.zig");
const results = @import("../results.zig");
const values = @import("../values.zig");

pub fn deleteElement(operand: *results.Element, allocator: std.mem.Allocator) void {
    operand.value.deinit(allocator);
}

pub fn deleteSignal(operand: *results.Signal, allocator: std.mem.Allocator) void {
    operand.value.deinit(allocator);
}

pub fn deleteResult(operand: *results.OperationResult, allocator: std.mem.Allocator) void {
    switch (operand.*) {
        .success => |*element| deleteElement(element, allocator),
        .failure => |*signal| deleteSignal(signal, allocator),
    }
}

// ============================================================================
// UNIT TESTS
// ============================================================================

test "deleteElement with non-allocated and allocated values" {
    const allocator = std.testing.allocator;

    // 1. Primitive scalar value (no-op in deinit)
    var int_elem = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Integer = 42 },
    };
    deleteElement(&int_elem, allocator);

    // 2. Allocated string value
    var str_elem = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .String = try allocator.dupe(u8, "to be deleted") },
    };
    deleteElement(&str_elem, allocator);

    // 3. Complex allocated structure (ErrorValue)
    const err_ptr = try allocator.create(values.ErrorValue);
    err_ptr.* = values.ErrorValue{
        .name = try allocator.dupe(u8, "TestError"),
        .details = try allocator.dupe(u8, "Error details"),
        .stack_trace = std.ArrayList([]const u8).empty,
    };
    var err_elem = results.Element{
        .modifier = results.ElementModifier{},
        .value = values.Value{ .Error = err_ptr },
    };
    deleteElement(&err_elem, allocator);
}

test "deleteSignal with allocated error" {
    const allocator = std.testing.allocator;

    const err_ptr = try allocator.create(values.ErrorValue);
    err_ptr.* = values.ErrorValue{
        .name = try allocator.dupe(u8, "SignalError"),
        .details = null,
        .stack_trace = std.ArrayList([]const u8).empty,
    };

    var sig = results.Signal{
        .modifier = results.SignalModifier{},
        .value = values.Value{ .Error = err_ptr },
    };
    deleteSignal(&sig, allocator);
}

test "deleteResult success branch" {
    const allocator = std.testing.allocator;

    var res = results.OperationResult{
        .success = results.Element{
            .modifier = results.ElementModifier{},
            .value = values.Value{ .String = try allocator.dupe(u8, "success payload") },
        },
    };

    deleteResult(&res, allocator);
}

test "deleteResult failure branch" {
    const allocator = std.testing.allocator;

    const err_ptr = try allocator.create(values.ErrorValue);
    err_ptr.* = values.ErrorValue{
        .name = try allocator.dupe(u8, "FailureSignal"),
        .details = try allocator.dupe(u8, "Something went wrong"),
        .stack_trace = std.ArrayList([]const u8).empty,
    };

    var res = results.OperationResult{
        .failure = results.Signal{
            .modifier = results.SignalModifier{},
            .value = values.Value{ .Error = err_ptr },
        },
    };

    deleteResult(&res, allocator);
}
