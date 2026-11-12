pub const ElementModifier = @import("results/element.zig").ElementModifier;
pub const Element = @import("results/element.zig").Element;

pub const SignalModifier = @import("results/signal.zig").SignalModifier;
pub const Signal = @import("results/signal.zig").Signal;

pub const OperationResult = union(enum) {
    success: Element,
    failure: Signal,
};
