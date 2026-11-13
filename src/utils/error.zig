pub const InternalError = error{
    OutOfMemory,
    WriteFailed,

    UndefinedOperation,
    UndefinedNegativeOperation,
    ZeroDivisionOperation,
};
