pub const delete = @import("operations/delete.zig");
pub const repr = @import("operations/repr.zig").repr;
pub const type_repr = @import("operations/type_repr.zig");
pub const convert = @import("operations/convert.zig").convert;

pub const leftIncrement = @import("operations/left_increment.zig").leftIncrement;
pub const leftDecrement = @import("operations/left_decrement.zig").leftDecrement;
pub const rightIncrement = @import("operations/right_increment.zig").rightIncrement;
pub const rightDecrement = @import("operations/right_decrement.zig").rightDecrement;

pub const add = @import("operations/add.zig").add;
pub const subtract = @import("operations/subtract.zig").subtract;
pub const multiply = @import("operations/multiply.zig").multiply;
pub const divide = @import("operations/divide.zig").divide;
pub const modulo = @import("operations/modulo.zig").modulo;

pub const lessThan = @import("operations/less_than.zig").lessThan;
pub const lessOrEquals = @import("operations/less_or_equals.zig").lessOrEquals;
pub const greaterThan = @import("operations/greater_than.zig").greaterThan;
pub const greaterOrEquals = @import("operations/greater_or_equals.zig").greaterOrEquals;
pub const equals = @import("operations/equals.zig").equals;
pub const notEquals = @import("operations/not_equals.zig").notEquals;

pub const logicalNot = @import("operations/logical_not.zig").logicalNot;
pub const logicalOr = @import("operations/logical_or.zig").logicalOr;
pub const logicalAnd = @import("operations/logical_and.zig").logicalAnd;
pub const bitwiseNot = @import("operations/bitwise_not.zig").bitwiseNot;
pub const bitwiseOr = @import("operations/bitwise_or.zig").bitwiseOr;
pub const bitwiseAnd = @import("operations/bitwise_and.zig").bitwiseAnd;
pub const bitwiseXor = @import("operations/bitwise_xor.zig").bitwiseXor;

pub const leftShift = @import("operations/left_shift.zig").leftShift;
pub const rightShift = @import("operations/right_shift.zig").rightShift;

pub const assign = @import("operations/assign.zig").assign;

test {
    _ = delete;
    _ = repr;
    _ = type_repr;
    _ = convert;

    _ = leftIncrement;
    _ = leftDecrement;
    _ = rightIncrement;
    _ = rightDecrement;

    _ = add;
    _ = subtract;
    _ = multiply;
    _ = divide;
    _ = modulo;

    _ = lessThan;
    _ = lessOrEquals;
    _ = greaterThan;
    _ = greaterOrEquals;
    _ = equals;
    _ = notEquals;

    _ = logicalNot;
    _ = logicalOr;
    _ = logicalAnd;
    _ = bitwiseNot;
    _ = bitwiseOr;
    _ = bitwiseAnd;
    _ = bitwiseXor;

    _ = leftShift;
    _ = rightShift;

    _ = assign;
}
