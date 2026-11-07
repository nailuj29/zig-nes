const CPU = @import("./root.zig").CPU;
const std = @import("std");

/// Possible addressing modes for an instruction
pub const AddressMode = enum {
    implied,
    immediate,
    absolute,
    zero_page,
    absolute_x,
    absolute_y,
    zero_page_x,
    zero_page_y,
    indirect,
    indirect_x,
    indirect_y,
};

/// Possible operand types for an instruction (memory or value for all instructions with an operand)
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

    if (@import("builtin").is_test) {
        @panic("Illegal instruction reached");
    }

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

/// Stores a value from the CPU's X register in memory
fn stx(self: *CPU, op: u16) void {
    self.writeByte(op, self.x);
}

/// Stores a value from the CPU's Y register in memory
fn sty(self: *CPU, op: u16) void {
    self.writeByte(op, self.y);
}

/// Transfers the CPU's A register to its X register
fn tax(self: *CPU, op: u16) void {
    _ = op;
    self.x = self.a;
    self.update_nz_flags(self.x);
}

/// Transfers the CPU's A register to its Y register
fn tay(self: *CPU, op: u16) void {
    _ = op;
    self.y = self.a;
    self.update_nz_flags(self.y);
}

/// Transfers the CPU's stack pointer to its X register
fn tsx(self: *CPU, op: u16) void {
    _ = op;
    self.x = self.sp;
    self.update_nz_flags(self.x);
}

/// Transfers the CPU's X register to its A register
fn txa(self: *CPU, op: u16) void {
    _ = op;
    self.a = self.x;
    self.update_nz_flags(self.a);
}

/// Transfers the CPU's X register to its stack pointer
fn txs(self: *CPU, op: u16) void {
    _ = op;
    self.sp = self.x;
    self.update_nz_flags(self.sp);
}

/// Transfers the CPU's Y register to its A register
fn tya(self: *CPU, op: u16) void {
    _ = op;
    self.a = self.y;
    self.update_nz_flags(self.a);
}

/// Sets the CPU's program counter to a new memory address
fn jmp(self: *CPU, op: u16) void {
    self.pc = op;
}

/// Does nothing
fn nop(self: *CPU, op: u16) void {
    _ = self;
    _ = op;
}

/// Adds a value from memory to the computer with the carry flag
fn adc(self: *CPU, op16: u16) void {
    const carry: u8 = if (self.flags.carry) 1 else 0;
    const result16 = self.a + op16 + carry;

    const resultCarry = result16 & (1 << 8);
    const resultSignBit = result16 & (1 << 7);
    const aSignBit = self.a & (1 << 7);
    const opSignBit = op16 & (1 << 7);

    const result: u8 = @truncate(result16);

    const overflow = (aSignBit == opSignBit) and (aSignBit != resultSignBit);

    self.a = result;

    self.flags.carry = resultCarry != 0;

    self.flags.overflow = overflow;

    self.update_nz_flags(self.a);
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

    // JMP:
    table[0x4C] = .{
        .mnemonic = "JMP",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 3,
        .handler = &jmp,
    };

    table[0x6C] = .{
        .mnemonic = "JMP",
        .addressing_mode = .indirect,
        .operand_type = .address,
        .cycles = 5,
        .handler = &jmp,
    };

    // ADC:
    table[0x69] = .{
        .mnemonic = "ADC",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &adc,
    };

    table[0x65] = .{
        .mnemonic = "ADC",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &adc,
    };

    table[0x75] = .{
        .mnemonic = "ADC",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &adc,
    };

    table[0x6D] = .{
        .mnemonic = "ADC",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &adc,
    };

    table[0x7D] = .{
        .mnemonic = "ADC",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &adc,
    };

    table[0x79] = .{
        .mnemonic = "ADC",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &adc,
    };

    table[0x61] = .{
        .mnemonic = "ADC",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &adc,
    };

    table[0x71] = .{
        .mnemonic = "ADC",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &adc,
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
    try expect(cpu.flags.negative);

    const cycle_count3 = try cpu.step();
    try expectEqual(4, cycle_count3);
    try expectEqual(0x2006, cpu.pc);
    try expectEqual(0x00, cpu.a);
    try expect(cpu.flags.zero);
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

test "JMP" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x4C, 0x00, 0x42, // JMP $4200
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    const cycle_count = try cpu.step();
    try expectEqual(3, cycle_count);
    try expectEqual(0x4200, cpu.pc);
}

test "ADC" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x42, // LDA #42
        0x69, 0x10, // ADC #10 ; A = 0x52
        0x69, 0x30, // ADC #30 ; A = 0x82 ; V
        0x69, 0x80, // ADC #80 ; A = 0x02 ; V, C
        0x69, 0x00, // ADC #00 ; A = 0x03 since C is set
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2004, cpu.pc);
    try expectEqual(0x52, cpu.a);
    try expect(!cpu.flags.overflow);
    try expect(!cpu.flags.carry);

    _ = try cpu.step();
    try expectEqual(0x2006, cpu.pc);
    try expectEqual(0x82, cpu.a);
    try expect(cpu.flags.overflow);
    try expect(!cpu.flags.carry);

    _ = try cpu.step();
    try expectEqual(0x2008, cpu.pc);
    try expectEqual(0x02, cpu.a);
    try expect(cpu.flags.overflow);
    try expect(cpu.flags.carry);

    _ = try cpu.step();
    try expectEqual(0x200a, cpu.pc);
    try expectEqual(0x03, cpu.a);
    try expect(!cpu.flags.overflow);
    try expect(!cpu.flags.carry);
}
