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
    indirect_x,
    indirect_y,
};

pub const OperandType = enum {
    none,
    value,
    address,
};

/// Contains the necessary metadata to execute an instruction
pub const InstructionMetadata = struct {
    mnemonic: []const u8,
    addressing_mode: AddressMode,
    operand_type: OperandType,
    cycles: u8,
    handler: *const fn (*CPU, u16) void,
};

/// Jams the CPU.
fn jam(self: *CPU, op: u16) void {
    _ = self;
    _ = op;
    while (true) {}
}

/// Loads a value into the CPU's A register, updating the negative and zero flags if necessary
fn lda(self: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    self.a = op;
    self.update_nz_flags(op);
}

/// Loads a value into the CPU's X register, updating the negative and zero flags if necessary
fn ldx(self: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    self.x = op;
    self.update_nz_flags(op);
}

/// Loads a value into the CPU's Y register, updating the negative and zero flags if necessary
fn ldy(self: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    self.y = op;
    self.update_nz_flags(op);
}

/// Stores a value from the CPU's A register in memory
fn sta(self: *CPU, op: u16) void {
    self.writeByte(op, self.a);
}

/// Does nothing
fn nop(self: *CPU, op: u16) void {
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
            .operand_type = .none,
            .cycles = 255,
            .handler = &jam,
        };
    }

    // NOP:
    table[0xEA] = .{
        .mnemonic = "NOP",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &nop,
    };

    // LDA:
    table[0xA9] = .{
        .mnemonic = "LDA",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &lda,
    };

    table[0xA5] = .{
        .mnemonic = "LDA",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &lda,
    };

    table[0xB5] = .{
        .mnemonic = "LDA",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &lda,
    };

    table[0xAD] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &lda,
    };

    table[0xBD] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &lda,
    };

    table[0xB9] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &lda,
    };

    table[0xA1] = .{
        .mnemonic = "LDA",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &lda,
    };

    table[0xB1] = .{
        .mnemonic = "LDA",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &lda,
    };

    // LDX:
    table[0xA2] = .{
        .mnemonic = "LDX",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &ldx,
    };

    table[0xA6] = .{
        .mnemonic = "LDX",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &ldx,
    };

    table[0xB6] = .{
        .mnemonic = "LDX",
        .addressing_mode = .zero_page_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &ldx,
    };

    table[0xAE] = .{
        .mnemonic = "LDX",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &ldx,
    };

    table[0xBE] = .{
        .mnemonic = "LDX",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &ldx,
    };

    // LDY:
    table[0xA0] = .{
        .mnemonic = "LDY",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &ldy,
    };

    table[0xA4] = .{
        .mnemonic = "LDY",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &ldy,
    };

    table[0xB4] = .{
        .mnemonic = "LDY",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &ldy,
    };

    table[0xAC] = .{
        .mnemonic = "LDY",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &ldy,
    };

    table[0xBC] = .{
        .mnemonic = "LDY",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &ldy,
    };

    // STA:
    table[0x85] = .{
        .mnemonic = "STA",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 3,
        .handler = &sta,
    };

    table[0x95] = .{
        .mnemonic = "STA",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &sta,
    };

    table[0x8D] = .{
        .mnemonic = "STA",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 4,
        .handler = &sta,
    };

    table[0x9D] = .{
        .mnemonic = "STA",
        .addressing_mode = .absolute_x,
        .operand_type = .address,
        .cycles = 5,
        .handler = &sta,
    };

    table[0x99] = .{
        .mnemonic = "STA",
        .addressing_mode = .absolute_y,
        .operand_type = .address,
        .cycles = 5,
        .handler = &sta,
    };

    table[0x81] = .{
        .mnemonic = "STA",
        .addressing_mode = .indirect_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &sta,
    };

    table[0x91] = .{
        .mnemonic = "STA",
        .addressing_mode = .indirect_y,
        .operand_type = .address,
        .cycles = 5,
        .handler = &sta,
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

    cpu.writeByte(0x42, 0x80); // -128 in 2's complement
    cpu.writeByte(0x84, 0x00);

    cpu.x = 0x42;

    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2002, cpu.pc);
    try expectEqual(0x42, cpu.a);

    const cycle_count2 = try cpu.step();
    try expectEqual(3, cycle_count2);
    try expectEqual(0x2004, cpu.pc);
    try expectEqual(0x80, cpu.a);
    try expect(0b10000000 & cpu.p != 0);

    const cycle_count3 = try cpu.step();
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

    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2001, cpu.pc);
}

test "LDX" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA2, 0x42, // LDX #42
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2002, cpu.pc);
    try expectEqual(0x42, cpu.x);
}

test "LDY" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA0, 0x42, // LDY #42
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2002, cpu.pc);
    try expectEqual(0x42, cpu.y);
}

test "STA" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x42, // LDA #42
        0x8D, 0x00, 0x80, // STA $8000
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step(); // skip the LDA
    const cycle_count = try cpu.step();
    try expectEqual(4, cycle_count);
    try expectEqual(0x2005, cpu.pc);
    try expectEqual(0x42, cpu.readByte(0x8000));
}
