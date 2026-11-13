# Changelog

All notable changes to this project will be documented in this file.

## [0.1.2] - Released

### Added
- **errors**:
  - `WriteFailed` errors.
- **chars**:
  - `countUtf8Codepoints` helper.

## [0.1.1] - Released

### Fixed
- **Bytecodes**:
  - Fixed bytecode count constants calculation (`ApicaBytecodeCount`, `BuiltinFunctionBytecodeCount`, `BuiltinMethodBytecodeCount`, `EntrypointBytecodeCount`, `SpecificationBytecodeCount`, `TypeBytecodeCount`) using `@backingInt` instead of direct enum arithmetic.

## [0.1.0] - Released

### Added
- **Bytecodes**:
  - Core VM instruction set (`ApicaBytecode`) covering control flow (`IfStatement`, `IfElseStatement`, `WhileStatement`, `ForStatement`, `Break`, `Continue`, `BlankReturn`, `FilledReturn`), variable/constant declarations and calls, literals, compounds, entrypoints, member accesses, references/dereferences, casts, and ternary operations.
  - Type system opcodes (`TypeBytecode`) supporting `Null`, `Any`, `Int`, `UnsignedInt`, `Float`, `Bool`, `Char`, `String`, `Error`, `Type`, `Reference`, and `List` with string representation (`repr`).
  - Built-in functions (`BuiltinFunctionBytecode`), built-in methods (`BuiltinMethodBytecode`), entrypoints (`EntrypointBytecode`: `Init`, `Update`, `Quit`), and application specifications (`SpecificationBytecode`).
- **Values & Memory Management**:
  - Tagged union `Value` supporting scalar primitives, optional/nullable states, `ErrorValue` (with stack traces), `TypeValue` (with nested `contained` types and `canCollect`/`equals` checks), `ReferenceValue`, and `ListValue`.
  - Deep cloning (`clone`) and deterministic memory cleanup (`deinit`, `deleteElement`, `deleteSignal`, `deleteResult`) across all value types.
- **Operations Engine**:
  - **Assignment**: `assign` with `NOT_NULLABLE` modifier enforcement, type compatibility checks (`canCollect`), and implicit primitive conversions.
  - **Arithmetic**: `add` (including string concatenation), `subtract`, `multiply` (including string and list repetition), `divide` (with `@divTrunc` and zero-division error handling), `modulo` (with `@rem` and zero-division error handling), `leftIncrement`, and `leftDecrement`.
  - **Bitwise & Shifts**: `bitwiseAnd`, `bitwiseOr`, `bitwiseXor`, `bitwiseNot`, `leftShift`, and `rightShift` (with negative right-operand detection and bit-width saturation).
  - **Comparison & Logic**: `equals`, `notEquals` (with cross-type numeric comparisons and deep recursive list equality), `lessThan`, `lessOrEquals`, `greaterThan`, `greaterOrEquals`, `logicalAnd`, `logicalOr`, and `logicalNot`.
  - **Type Conversion & Representation**: Unified explicit (`as`) and implicit (`auto`) `convert` operation supporting scalar casts, string formatting, and element-wise recursive `List` conversions (`list<T>` to `list<U>`), alongside `repr` and `typeRepr`.
- **Diagnostics & Signals**:
  - `OperationResult`, `Element` (with `CONSTANT` and `NOT_NULLABLE` modifiers), and `Signal` system (`ERROR`, `BREAK`, `CONTINUE`, `RETURN`, `TERMINATE`) with detailed runtime error generators (`nullOperationError`, `constantOperationError`, `notNullableOperationError`, `negativeRightOperandError`, `zeroDivisionOperationError`, `unaryOperationError`, `binaryOperationError`, `conversionOperationError`).
- **Testing & Build**:
  - Zig `0.17.0` package configuration exposing the `ApicaCommon` module.
  - Comprehensive unit test suite covering all operations, edge cases, type incompatibilities, error signals, and leak-free memory management via `std.testing.allocator`.
