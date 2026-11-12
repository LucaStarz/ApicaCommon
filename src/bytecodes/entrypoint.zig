pub const EntrypointBytecode = enum(u8) {
    Init = 0x00,
    Update = 0x01,
    Quit = 0x02,
};

pub const EntrypointBytecodeCount: u8 = @backingInt(EntrypointBytecode.Quit) + 1;
