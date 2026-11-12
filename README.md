# ApicaCommon

Core shared library providing fundamental primitives, bytecode definitions and common utilities shared between the compiler and the virtual machine.

---

## Role in the architecture

This module acts as the single source of truth between code generation and runtime execution:

```text
Source (.sbw)
      │
      ▼
┌─────────────┐
│  Compiler   │ ──┐
└─────────────┘   │   shares definitions from
                  ├── ApicaCommon (Bytecodes, Errors, Values, Operations, ...)
┌─────────────┐   │
│   VM / GPU  │ ──┘
└─────────────┘
      │
      ▼
Window / Screen
```
