pub const SpecificationBytecode = enum(u16) {
    EndOfSpecification = 0x00_00,
    IdCount = 0x00_01,

    Title = 0x00_02,
    Id = 0x00_03,
    Version = 0x00_04,

    WindowWidth = 0x00_05,
    WindowHeight = 0x00_06,
    RendererWidth = 0x00_07,
    RendererHeight = 0x00_08,

    LoggerActivation = 0x00_09,
};

pub const SpecificationBytecodeCount: u16 = SpecificationBytecode.LoggerActivation + 1;
