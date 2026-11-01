const CPU = @import("./root.zig").CPU;
const std = @import("std");

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

/// Loads a value into the CPU's A register, updating the negative and zero flags if necessary
fn lda(self: *CPU, op: u8) void {
    self.a = op;
    self.update_nz_flags(op);
}

/// Does nothing
fn nop(self: *CPU, op: u8) void {
    _ = self;
    _ = op;
}

/// Initializes the table of instruction metadata at comptime
fn initTable() [256]InstructionMetadata {
    var table: [256]InstructionMetadata = undefined;

    // Set defaults:
    for (&table) |*entry| {
        entry.* = .{
            .mnemonic = "JAM",
            .addressing_mode = .implied,
            .cycles = 255,
            .handler = &jam,
        };
    }

    // NOP:
    table[0xEA] = .{
        .mnemonic = "NOP",
        .addressing_mode = .implied,
        .cycles = 2,
        .handler = &nop,
    };

    // LDA:
    table[0xA9] = .{
        .mnemonic = "LDA",
        .addressing_mode = .immediate,
        .cycles = 2,
        .handler = &lda,
    };

    table[0xA5] = .{
        .mnemonic = "LDA",
        .addressing_mode = .zero_page,
        .cycles = 3,
        .handler = &lda,
    };

    table[0xB5] = .{
        .mnemonic = "LDA",
        .addressing_mode = .zero_page_x,
        .cycles = 4,
        .handler = &lda,
    };

    table[0xAD] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute,
        .cycles = 4,
        .handler = &lda,
    };

    table[0xBD] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute_x,
        .cycles = 4,
        .handler = &lda,
    };

    table[0xB9] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute_y,
        .cycles = 4,
        .handler = &lda,
    };

    table[0xA1] = .{
        .mnemonic = "LDA",
        .addressing_mode = .pre_indexed_indirect,
        .cycles = 6,
        .handler = &lda,
    };

    table[0xB1] = .{
        .mnemonic = "LDA",
        .addressing_mode = .post_indexed_indirect,
        .cycles = 5,
        .handler = &lda,
    };

    return table;
}

/// A table of all 256 possible opcodes the CPU may encounter
pub const instruction_table: [256]InstructionMetadata = initTable();

test "LDA" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x42, // LDA #42
        0xA5, 0x42, // LDA $42
        0xB5, 0x42, // LDA $42,X
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.writeByte(0x42, 0x80);
    cpu.writeByte(0x84, 0x00);

    cpu.x = 0x42;

    const cycle_count = cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2002, cpu.pc);
    try expectEqual(0x42, cpu.a);

    const cycle_count2 = cpu.step();
    try expectEqual(3, cycle_count2);
    try expectEqual(0x2004, cpu.pc);
    try expectEqual(0x80, cpu.a);
    try expect(0b10000000 & cpu.p != 0);

    const cycle_count3 = cpu.step();
    try expectEqual(4, cycle_count3);
    try expectEqual(0x2006, cpu.pc);
    try expectEqual(0x00, cpu.a);
    try expect(0b00000010 & cpu.p != 0);
}

test "NOP" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xEA, // NOP
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    const cycle_count = cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2001, cpu.pc);
}
