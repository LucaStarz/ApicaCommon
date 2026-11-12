pub const BuiltinFunctionBytecode = enum(u32) {
    QuitApplication = 0x00_00_00_00,
    LoadApplication = 0x00_00_00_01,

    LogInfo = 0x00_00_00_02,
    LogInfoNewLine = 0x00_00_00_03,
    LogSuccess = 0x00_00_00_04,
    LogSuccessNewLine = 0x00_00_00_05,
    LogWarning = 0x00_00_00_06,
    LogWarningNewLine = 0x00_00_00_07,
    LogError = 0x00_00_00_08,
    LogErrorNewLine = 0x00_00_00_09,

    SetWindowTitle = 0x00_00_00_0A,
    SetWindowResizable = 0x00_00_00_0B,
    SetWindowClearColor = 0x00_00_00_0C,
    SetWindowSize = 0x00_00_00_0D,

    IsKeyJustReleased = 0x00_00_00_0E,
    IsKeyReleased = 0x00_00_00_0F,
    IsKeyJustPressed = 0x00_00_00_10,
    IsKeyPressed = 0x00_00_00_11,

    LoadSpritesheet2D = 0x00_00_00_12,
    UnloadSpritesheet2D = 0x00_00_00_13,
    DrawSprite2DAt = 0x00_00_00_14,
    GetSpritesheet2DColumns = 0x00_00_00_15,
    GetSpritesheet2DRows = 0x00_00_00_16,
    GetSpritesheet2DFrames = 0x00_00_00_17,

    SetSystemLanguage = 0x00_00_00_18,
    GetSystemLanguage = 0x00_00_00_19,

    GetDeltaTime = 0x00_00_00_1A,
    GetFormattedDateTime = 0x00_00_00_1B,
    GetActualFormattedDateTime = 0x00_00_00_1C,
    GetActualMilliTimestamp = 0x00_00_00_1D,

    LoadFont = 0x00_00_00_1E,
    UnloadFont = 0x00_00_00_1F,
    DisplayTextAt = 0x00_00_00_20,

    LoadShader = 0x00_00_00_21,
    UnloadShader = 0x00_00_00_22,
    UseShader = 0x00_00_00_23,
};

pub const BuiltinFunctionBytecodeCount: u32 = BuiltinFunctionBytecode.UseShader + 1;
