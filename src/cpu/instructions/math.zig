const CPU = @import("../root.zig").CPU;
const InstructionMetadata = @import("./table.zig").InstructionMetadata;
const std = @import("std");

pub fn register(table: *[256]InstructionMetadata) void {
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

    // SBC:
    table[0xE9] = .{
        .mnemonic = "SBC",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &sbc,
    };

    table[0xE5] = .{
        .mnemonic = "SBC",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &sbc,
    };

    table[0xF5] = .{
        .mnemonic = "SBC",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &sbc,
    };

    table[0xED] = .{
        .mnemonic = "SBC",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &sbc,
    };

    table[0xFD] = .{
        .mnemonic = "SBC",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &sbc,
    };

    table[0xF9] = .{
        .mnemonic = "SBC",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &sbc,
    };

    table[0xE1] = .{
        .mnemonic = "SBC",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &sbc,
    };

    table[0xF1] = .{
        .mnemonic = "SBC",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &sbc,
    };

    // INC:
    table[0xE6] = .{
        .mnemonic = "INC",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 5,
        .handler = &inc,
    };

    table[0xF6] = .{
        .mnemonic = "INC",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &inc,
    };

    table[0xEE] = .{
        .mnemonic = "INC",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 6,
        .handler = &inc,
    };

    table[0xFE] = .{
        .mnemonic = "INC",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 2,
        .handler = &inc,
    };

    // INX:
    table[0xE8] = .{
        .mnemonic = "INX",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &inx,
    };

    // INY:
    table[0xC8] = .{
        .mnemonic = "INY",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &iny,
    };

    // DEC:
    table[0xC6] = .{
        .mnemonic = "DEC",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 5,
        .handler = &dec,
    };

    table[0xD6] = .{
        .mnemonic = "DEC",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &dec,
    };

    table[0xCE] = .{
        .mnemonic = "DEC",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 6,
        .handler = &dec,
    };

    table[0xDE] = .{
        .mnemonic = "DEC",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 2,
        .handler = &dec,
    };

    // DEX:
    table[0xCA] = .{
        .mnemonic = "DEX",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &dex,
    };

    // DEY:
    table[0x88] = .{
        .mnemonic = "DEY",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &dey,
    };

    // CMP:
    table[0xC9] = .{
        .mnemonic = "CMP",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &cmp,
    };

    table[0xC5] = .{
        .mnemonic = "CMP",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &cmp,
    };

    table[0xD5] = .{
        .mnemonic = "CMP",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &cmp,
    };

    table[0xCD] = .{
        .mnemonic = "CMP",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &cmp,
    };

    table[0xDD] = .{
        .mnemonic = "CMP",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &cmp,
    };

    table[0xD9] = .{
        .mnemonic = "CMP",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &cmp,
    };

    table[0xC1] = .{
        .mnemonic = "CMP",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &cmp,
    };

    table[0xD1] = .{
        .mnemonic = "CMP",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &cmp,
    };

    // CPX:
    table[0xE0] = .{
        .mnemonic = "CPX",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &cpx,
    };

    table[0xE4] = .{
        .mnemonic = "CPX",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &cpx,
    };

    table[0xEC] = .{
        .mnemonic = "CPX",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &cpx,
    };

    // CPY:
    table[0xC0] = .{
        .mnemonic = "CPY",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &cpy,
    };

    table[0xC4] = .{
        .mnemonic = "CPY",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &cpy,
    };

    table[0xCC] = .{
        .mnemonic = "CPY",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &cpy,
    };
}

/// Adds a value from memory to the computer with the carry flag
fn adc(cpu: *CPU, op16: u16) void {
    const carry: u8 = if (cpu.flags.carry) 1 else 0;
    const result16 = cpu.a + op16 + carry;

    const resultCarry = result16 & (1 << 8);
    const resultSignBit = result16 & (1 << 7);
    const aSignBit = cpu.a & (1 << 7);
    const opSignBit = op16 & (1 << 7);

    const result: u8 = @truncate(result16);

    const overflow = (aSignBit == opSignBit) and (aSignBit != resultSignBit);

    cpu.a = result;

    cpu.flags.carry = resultCarry != 0;

    cpu.flags.overflow = overflow;

    cpu.update_nz_flags(cpu.a);
}

/// Subtracts a value from memory to the computer with the carry flag
fn sbc(cpu: *CPU, op16: u16) void {
    adc(cpu, ~op16 & 0xff);
}

/// Increments a value in memory by 1
fn inc(cpu: *CPU, op: u16) void {
    const newValue = cpu.readByte(op) +% 1;
    cpu.writeByte(op, newValue);

    cpu.update_nz_flags(newValue);
}

/// Increments the CPU's X register by 1
fn inx(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.x = cpu.x +% 1;

    cpu.update_nz_flags(cpu.x);
}

/// Increments the CPU's Y register by 1
fn iny(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.y = cpu.y +% 1;

    cpu.update_nz_flags(cpu.y);
}

/// Decrements a value in memory by 1
fn dec(cpu: *CPU, op: u16) void {
    const newValue = cpu.readByte(op) -% 1;
    cpu.writeByte(op, newValue);

    cpu.update_nz_flags(newValue);
}

/// Decrements the CPU's X register by 1
fn dex(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.x = cpu.x -% 1;

    cpu.update_nz_flags(cpu.x);
}

/// Decrements the CPU's Y register by 1
fn dey(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.y = cpu.y -% 1;

    cpu.update_nz_flags(cpu.y);
}

/// Compares a value in the CPU's A register to a value in memory, updating the C, N, and Z flags
/// according to the difference between the two
fn cmp(cpu: *CPU, op16: u16) void {
    const result16 = cpu.a + ((~op16 & 0xff) + 1); // Add the 8-bit two's complement to avoid underflows
    const resultCarry = result16 & (1 << 8);

    cpu.flags.carry = resultCarry != 0;

    cpu.update_nz_flags(@truncate(result16));
}

/// Compares a value in the CPU's X register to a value in memory, updating the C, N, and Z flags
/// according to the difference between the two
fn cpx(cpu: *CPU, op16: u16) void {
    const result16 = cpu.x + ((~op16 & 0xff) + 1); // Add the 8-bit two's complement to avoid underflows
    const resultCarry = result16 & (1 << 8);

    cpu.flags.carry = resultCarry != 0;

    cpu.update_nz_flags(@truncate(result16));
}

/// Compares a value in the CPU's Y register to a value in memory, updating the C, N, and Z flags
/// according to the difference between the two
fn cpy(cpu: *CPU, op16: u16) void {
    const result16 = cpu.y + ((~op16 & 0xff) + 1); // Add the 8-bit two's complement to avoid underflows
    const resultCarry = result16 & (1 << 8);

    cpu.flags.carry = resultCarry != 0;

    cpu.update_nz_flags(@truncate(result16));
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
        0x69, 0x30, // ADC #30 ; A = 0x82, V
        0x69, 0x80, // ADC #80 ; A = 0x02, V, C
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

test "SBC" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        // ; SEC not yet implemented, will be manually done
        0xA9, 0x42, // LDA #42
        0xE9, 0x40, // SBC #40 ; A = 0x02, C
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    cpu.flags.carry = true;

    _ = try cpu.step();
    try expectEqual(0x2004, cpu.pc);
    try expectEqual(0x02, cpu.a);
    try expect(!cpu.flags.overflow);
    try expect(cpu.flags.carry);
}

test "INC" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xE6, 0x42, // INC $42
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.writeByte(0x0042, 0xaa);

    _ = try cpu.step();
    try expectEqual(0x2002, cpu.pc);
    try expectEqual(0xab, cpu.readByte(0x42));
}

test "INX" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xE8, // INX
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.x = 0xaa;

    _ = try cpu.step();
    try expectEqual(0x2001, cpu.pc);
    try expectEqual(0xab, cpu.x);
}

test "INY" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xC8, // INY
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.y = 0xaa;

    _ = try cpu.step();
    try expectEqual(0x2001, cpu.pc);
    try expectEqual(0xab, cpu.y);
}

test "DEC" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xC6, 0x42, // DEC $42
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.writeByte(0x0042, 0xaa);

    _ = try cpu.step();
    try expectEqual(0x2002, cpu.pc);
    try expectEqual(0xa9, cpu.readByte(0x42));
}

test "DEX" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xCA, // DEX
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.x = 0xaa;

    _ = try cpu.step();
    try expectEqual(0x2001, cpu.pc);
    try expectEqual(0xa9, cpu.x);
}

test "DEY" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x88, // DEY
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.y = 0xaa;

    _ = try cpu.step();
    try expectEqual(0x2001, cpu.pc);
    try expectEqual(0xa9, cpu.y);
}

test "CMP" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x42, // LDA #42
        0xC9, 0x40, // CMP #40 ; C
        0xC9, 0x50, // CMP #40 ; N
        0xC9, 0x42, // CMP #40 ; C, Z
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    _ = try cpu.step();
    try expectEqual(0x2004, cpu.pc);
    try expect(!cpu.flags.zero);
    try expect(cpu.flags.carry);
    try expect(!cpu.flags.negative);

    _ = try cpu.step();
    try expectEqual(0x2006, cpu.pc);
    try expect(!cpu.flags.zero);
    try expect(!cpu.flags.carry);
    try expect(cpu.flags.negative);

    _ = try cpu.step();
    try expectEqual(0x2008, cpu.pc);
    try expect(cpu.flags.zero);
    try expect(cpu.flags.carry);
    try expect(!cpu.flags.negative);
}

test "CPX" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA2, 0x42, // LDX #42
        0xE0, 0x40, // CPX #40 ; C
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    _ = try cpu.step();
    try expectEqual(0x2004, cpu.pc);
    try expect(!cpu.flags.zero);
    try expect(cpu.flags.carry);
    try expect(!cpu.flags.negative);
}

test "CPY" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA0, 0x42, // LDY #42
        0xC0, 0x40, // CPY #40 ; C
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    _ = try cpu.step();
    try expectEqual(0x2004, cpu.pc);
    try expect(!cpu.flags.zero);
    try expect(cpu.flags.carry);
    try expect(!cpu.flags.negative);
}
