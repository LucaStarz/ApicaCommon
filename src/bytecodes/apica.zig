pub const ApicaBytecode = enum(u8) {
    // System & Entrypoints
    Halt = 0x00,
    NoOperation = 0x01,
    Specification = 0x02,
    Entrypoint = 0x03,

    // Stack & Constants
    LoadConst = 0x04,
    LoadNull = 0x05,
    LoadTrue = 0x06,
    LoadFalse = 0x07,
    BuildList = 0x08, // Pop N elements + TypeValue -> push ListValue
    BuildType = 0x09, // Build a TypeValue (kind, is_nullable, N nested types)
    Pop = 0x0A,
    Dup = 0x0B,

    // Variables & Scopes
    EnterScope = 0x0C,
    ExitScope = 0x0D,
    DeclareVar = 0x0E,
    DeclareConst = 0x0F,
    LoadVar = 0x10,
    StoreVar = 0x11,
    LoadGlobal = 0x12,
    StoreGlobal = 0x13,

    // Calls
    Call = 0x14,
    BuiltinFunctionCall = 0x15,
    BuiltinMethodCall = 0x16,

    // Assignment & Arithmetic / Bitwise Operations
    Assign = 0x17,
    Negate = 0x18,
    Add = 0x19,
    AddAssignment = 0x1A,
    LeftIncrement = 0x1B,
    RightIncrement = 0x1C,
    Subtract = 0x1D,
    SubtractAssignment = 0x1E,
    LeftDecrement = 0x1F,
    RightDecrement = 0x20,
    Multiply = 0x21,
    MultiplyAssignment = 0x22,
    Divide = 0x23,
    DivideAssignment = 0x24,
    Modulo = 0x25,
    ModuloAssignment = 0x26,
    LeftShift = 0x27,
    LeftShiftAssignment = 0x28,
    RightShift = 0x29,
    RightShiftAssignment = 0x2A,
    BitwiseAnd = 0x2B,
    BitwiseAndAssignment = 0x2C,
    BitwiseOr = 0x2D,
    BitwiseOrAssignment = 0x2E,
    BitwiseXor = 0x2F,
    BitwiseXorAssignment = 0x30,
    BitwiseNot = 0x31,

    // Comparisons & Logic
    Equals = 0x32,
    NotEquals = 0x33,
    LessThan = 0x34,
    LessOrEquals = 0x35,
    GreaterThan = 0x36,
    GreaterOrEquals = 0x37,
    LogicalNot = 0x38,
    LogicalAnd = 0x39,
    LogicalOr = 0x3A,

    // References, Indexing, Members & Types
    MemberAccess = 0x3B,
    ConditionalMemberAccess = 0x3C,
    IndexAccess = 0x3D,
    ReferenceOf = 0x3E,
    Dereference = 0x3F,
    Cast = 0x40,
    Typeof = 0x41,

    // Linear Control Flow
    Jump = 0x42,
    JumpIfFalse = 0x43,
    JumpIfTrue = 0x44,
    LoopBack = 0x45,
    BlankReturn = 0x46,
    FilledReturn = 0x47,

    // Exception Handling
    TryBegin = 0x48, // Install an exception handler (operand: relative offset to the catch block)
    TryEnd = 0x49, // Remove the current exception handler upon normal exit from the try block
    Throw = 0x4A, // Pop an error/exception Value and unwind the stack to the active handler
};

pub const ApicaBytecodeCount: u32 = @backingInt(ApicaBytecode.Throw) + 1;
