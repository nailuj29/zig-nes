const CPU = @import("../root.zig").CPU;
const InstructionMetadata = @import("./table.zig").InstructionMetadata;
const std = @import("std");

/// Loads all instructions handling register operations into the main instruction lookup table
///
/// Should be run at compile time
pub fn register(table: *[256]InstructionMetadata) void {
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
        .operand_type = .address,
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

    // STX:
    table[0x86] = .{
        .mnemonic = "STX",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 3,
        .handler = &stx,
    };

    table[0x96] = .{
        .mnemonic = "STX",
        .addressing_mode = .zero_page_y,
        .operand_type = .address,
        .cycles = 4,
        .handler = &stx,
    };

    table[0x8E] = .{
        .mnemonic = "STX",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 4,
        .handler = &stx,
    };

    // STY:
    table[0x84] = .{
        .mnemonic = "STY",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 3,
        .handler = &sty,
    };

    table[0x94] = .{
        .mnemonic = "STY",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 4,
        .handler = &sty,
    };

    table[0x8C] = .{
        .mnemonic = "STY",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 4,
        .handler = &sty,
    };

    // TAX:
    table[0xAA] = .{
        .mnemonic = "TAX",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &tax,
    };

    // TAY:
    table[0xA8] = .{
        .mnemonic = "TAY",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &tay,
    };

    // TAY:
    table[0xA8] = .{
        .mnemonic = "TAY",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &tay,
    };

    // TSX:
    table[0xBA] = .{
        .mnemonic = "TSX",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &tsx,
    };

    // TXA:
    table[0x8A] = .{
        .mnemonic = "TXA",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &txa,
    };

    // TXS:
    table[0x9A] = .{
        .mnemonic = "TXS",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &txs,
    };

    // TYA:
    table[0x98] = .{
        .mnemonic = "TYA",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &tya,
    };
}

/// Loads a value into the CPU's A register, updating the negative and zero flags if necessary
fn lda(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.a = op;
    cpu.update_nz_flags(op);
}

/// Loads a value into the CPU's X register, updating the negative and zero flags if necessary
fn ldx(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.x = op;
    cpu.update_nz_flags(op);
}

/// Loads a value into the CPU's Y register, updating the negative and zero flags if necessary
fn ldy(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.y = op;
    cpu.update_nz_flags(op);
}

/// Stores a value from the CPU's A register in memory
fn sta(cpu: *CPU, op: u16) void {
    cpu.writeByte(op, cpu.a);
}

/// Stores a value from the CPU's X register in memory
fn stx(cpu: *CPU, op: u16) void {
    cpu.writeByte(op, cpu.x);
}

/// Stores a value from the CPU's Y register in memory
fn sty(cpu: *CPU, op: u16) void {
    cpu.writeByte(op, cpu.y);
}

/// Transfers the CPU's A register to its X register
fn tax(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.x = cpu.a;
    cpu.update_nz_flags(cpu.x);
}

/// Transfers the CPU's A register to its Y register
fn tay(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.y = cpu.a;
    cpu.update_nz_flags(cpu.y);
}

/// Transfers the CPU's stack pointer to its X register
fn tsx(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.x = cpu.sp;
    cpu.update_nz_flags(cpu.x);
}

/// Transfers the CPU's X register to its A register
fn txa(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.a = cpu.x;
    cpu.update_nz_flags(cpu.a);
}

/// Transfers the CPU's X register to its stack pointer
fn txs(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.sp = cpu.x;
    cpu.update_nz_flags(cpu.sp);
}

/// Transfers the CPU's Y register to its A register
fn tya(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.a = cpu.y;
    cpu.update_nz_flags(cpu.a);
}

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
    try expect(cpu.flags.negative);

    const cycle_count3 = try cpu.step();
    try expectEqual(4, cycle_count3);
    try expectEqual(0x2006, cpu.pc);
    try expectEqual(0x00, cpu.a);
    try expect(cpu.flags.zero);
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

test "STX" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA2, 0x42, // LDX #42
        0x8E, 0x00, 0x80, // STX $8000
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step(); // skip the LDA
    const cycle_count = try cpu.step();
    try expectEqual(4, cycle_count);
    try expectEqual(0x2005, cpu.pc);
    try expectEqual(0x42, cpu.readByte(0x8000));
}

test "STY" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA0, 0x42, // LDY #42
        0x8C, 0x00, 0x80, // STY $8000
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step(); // skip the LDA
    const cycle_count = try cpu.step();
    try expectEqual(4, cycle_count);
    try expectEqual(0x2005, cpu.pc);
    try expectEqual(0x42, cpu.readByte(0x8000));
}

test "TAX" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x42, // LDA #42
        0xAA, // TAX
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step(); // Skip LDA
    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2003, cpu.pc);
    try expectEqual(0x42, cpu.x);
}

test "TAY" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x42, // LDA #42
        0xA8, // TAY
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step(); // Skip LDA
    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2003, cpu.pc);
    try expectEqual(0x42, cpu.y);
}

test "TSX" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xBA, // TSX
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2001, cpu.pc);
    try expectEqual(0xfd, cpu.x);
}

test "TXA" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA2, 0x42, // LDX #42
        0x8A, // TXA
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step(); // Skip LDX
    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2003, cpu.pc);
    try expectEqual(0x42, cpu.a);
}

test "TXS" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA2, 0x42, // LDX #42
        0x9A, // TAY
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step(); // Skip LDX
    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2003, cpu.pc);
    try expectEqual(0x42, cpu.sp);
}

test "TYA" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA0, 0x42, // LDY #42
        0x98, // TYA
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step(); // Skip LDY
    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2003, cpu.pc);
    try expectEqual(0x42, cpu.a);
}
