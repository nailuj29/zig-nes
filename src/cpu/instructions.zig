const CPU = @import("./root.zig").CPU;

pub const AddressMode = enum {
    implied,
    immediate,
    absolute,
    zero_page,
    absolute_x,
    absolute_y,
    zero_page_x,
    zero_page_y,
    pre_indexed_indirect,
    post_indexed_indirect,
};

/// Contains the necessary metadata to execute an instruction
pub const InstructionMetadata = struct {
    mnemonic: []const u8,
    addressing_mode: AddressMode,
    cycles: u8,
    handler: *const fn (*CPU, u8) void,
};

/// Jams the CPU.
fn jam(self: *CPU, op: u8) void {
    _ = self;
    _ = op;
    while (true) {}
}

/// Initializes the table of instruction metadata at comptime
fn initTable() [256]InstructionMetadata {
    var table: [256]InstructionMetadata = .{};

    // Set defaults:
    for (&table) |*entry| {
        entry.* = .{
            .mnemonic = "JAM",
            .addressing_mode = .implied,
            .cycles = -1,
            .handler = &jam,
        };
    }

    // LDA:
    table[0xA9] = .{
        .mnemonic = "LDA",
        .addressing_mode = .immediate,
        .cycles = 2,
    };

    table[0xA5] = .{
        .mnemonic = "LDA",
        .addressing_mode = .zero_page,
        .cycles = 3,
    };

    table[0xB5] = .{
        .mnemonic = "LDA",
        .addressing_mode = .zero_page_x,
        .cycles = 4,
    };

    table[0xAD] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute,
        .cycles = 4,
    };

    table[0xBD] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute_x,
        .cycles = 4,
    };

    table[0xB9] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute_y,
        .cycles = 4,
    };

    table[0xA1] = .{
        .mnemonic = "LDA",
        .addressing_mode = .indirect_x,
        .cycles = 6,
    };

    table[0xB1] = .{
        .mnemonic = "LDA",
        .addressing_mode = .indirect_y,
        .cycles = 5,
    };

    return table;
}

/// A table of all 256 possible opcodes the CPU may encounter
pub const instruction_table: [256]InstructionMetadata = initTable();
