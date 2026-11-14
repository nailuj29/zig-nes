const CPU = @import("../root.zig").CPU;
const InstructionMetadata = @import("./table.zig").InstructionMetadata;
const std = @import("std");

/// Loads all instructions handling bitwise operations into the main instruction lookup table
/// Should be run at compile time
pub fn register(table: *[256]InstructionMetadata) void {
    // AND:
    table[0x29] = .{
        .mnemonic = "AND",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &and_op,
    };

    table[0x25] = .{
        .mnemonic = "AND",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &and_op,
    };

    table[0x35] = .{
        .mnemonic = "AND",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &and_op,
    };

    table[0x2D] = .{
        .mnemonic = "AND",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &and_op,
    };

    table[0x3D] = .{
        .mnemonic = "AND",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &and_op,
    };

    table[0x39] = .{
        .mnemonic = "AND",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &and_op,
    };

    table[0x21] = .{
        .mnemonic = "AND",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &and_op,
    };

    table[0x31] = .{
        .mnemonic = "AND",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &and_op,
    };

    // ORA:
    table[0x09] = .{
        .mnemonic = "ORA",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &ora,
    };

    table[0x05] = .{
        .mnemonic = "ORA",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &ora,
    };

    table[0x15] = .{
        .mnemonic = "ORA",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &ora,
    };

    table[0x0D] = .{
        .mnemonic = "ORA",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &ora,
    };

    table[0x1D] = .{
        .mnemonic = "ORA",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &ora,
    };

    table[0x19] = .{
        .mnemonic = "ORA",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &ora,
    };

    table[0x01] = .{
        .mnemonic = "ORA",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &ora,
    };

    table[0x11] = .{
        .mnemonic = "ORA",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &ora,
    };

    // EOR:
    table[0x49] = .{
        .mnemonic = "EOR",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &eor,
    };

    table[0x45] = .{
        .mnemonic = "EOR",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &eor,
    };

    table[0x55] = .{
        .mnemonic = "EOR",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &eor,
    };

    table[0x4D] = .{
        .mnemonic = "EOR",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &eor,
    };

    table[0x5D] = .{
        .mnemonic = "EOR",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &eor,
    };

    table[0x59] = .{
        .mnemonic = "EOR",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &eor,
    };

    table[0x41] = .{
        .mnemonic = "EOR",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &eor,
    };

    table[0x51] = .{
        .mnemonic = "EOR",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &eor,
    };

    // ASL:
    table[0x0A] = .{
        .mnemonic = "ASL",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &asl_acc,
    };

    table[0x06] = .{
        .mnemonic = "ASL",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 5,
        .handler = &asl,
    };

    table[0x16] = .{
        .mnemonic = "ASL",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &asl,
    };

    table[0x0E] = .{
        .mnemonic = "ASL",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 6,
        .handler = &asl,
    };

    table[0x1E] = .{
        .mnemonic = "ASL",
        .addressing_mode = .absolute_x,
        .operand_type = .address,
        .cycles = 7,
        .handler = &asl,
    };

    // LSR:
    table[0x4A] = .{
        .mnemonic = "LSR",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &lsr_acc,
    };

    table[0x46] = .{
        .mnemonic = "LSR",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 5,
        .handler = &lsr,
    };

    table[0x56] = .{
        .mnemonic = "LSR",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &lsr,
    };

    table[0x4E] = .{
        .mnemonic = "LSR",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 6,
        .handler = &lsr,
    };

    table[0x5E] = .{
        .mnemonic = "LSR",
        .addressing_mode = .absolute_x,
        .operand_type = .address,
        .cycles = 7,
        .handler = &lsr,
    };

    // ROL:
    table[0x2A] = .{
        .mnemonic = "ROL",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &rol_acc,
    };

    table[0x26] = .{
        .mnemonic = "ROL",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 5,
        .handler = &rol,
    };

    table[0x36] = .{
        .mnemonic = "ROL",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &rol,
    };

    table[0x2E] = .{
        .mnemonic = "ROL",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 6,
        .handler = &rol,
    };

    table[0x3E] = .{
        .mnemonic = "ROL",
        .addressing_mode = .absolute_x,
        .operand_type = .address,
        .cycles = 7,
        .handler = &rol,
    };

    // ROR:
    table[0x6A] = .{
        .mnemonic = "ROR",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &ror_acc,
    };

    table[0x66] = .{
        .mnemonic = "ROR",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 5,
        .handler = &ror,
    };

    table[0x76] = .{
        .mnemonic = "ROR",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &ror,
    };

    table[0x6E] = .{
        .mnemonic = "ROR",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 6,
        .handler = &ror,
    };

    table[0x7E] = .{
        .mnemonic = "ROR",
        .addressing_mode = .absolute_x,
        .operand_type = .address,
        .cycles = 7,
        .handler = &ror,
    };

    // BIT
    table[0x24] = .{
        .mnemonic = "BIT",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &bit,
    };

    table[0x2C] = .{
        .mnemonic = "BIT",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bit,
    };
}

/// Bitwise ANDs the operand with the A register
fn and_op(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.a = cpu.a & op;

    cpu.update_nz_flags(cpu.a);
}

/// Bitwise ORs the operand with the A register
fn ora(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.a = cpu.a | op;

    cpu.update_nz_flags(cpu.a);
}

/// Bitwise XORs the operand with the A register
fn eor(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.a = cpu.a ^ op;

    cpu.update_nz_flags(cpu.a);
}

/// Shifts a value in memory left (filling in 0's from the right)
fn asl(cpu: *CPU, op: u16) void {
    var value = cpu.readByte(op);
    cpu.flags.carry = (value & 0b10000000) != 0;
    value <<= 1;
    cpu.writeByte(op, value);

    cpu.update_nz_flags(value);
}

/// Shifts the value in the accumulator left (filling in 0's from the right)
fn asl_acc(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags.carry = (cpu.a & 0b10000000) != 0;
    cpu.a <<= 1;

    cpu.update_nz_flags(cpu.a);
}

/// Shifts a value in memory right (filling in 0's from the left)
fn lsr(cpu: *CPU, op: u16) void {
    var value = cpu.readByte(op);
    cpu.flags.carry = (value & 0b00000001) != 0;
    value >>= 1;
    cpu.writeByte(op, value);

    cpu.update_nz_flags(value);
}

/// Shifts the value in the accumulator right (filling in 0's from the left)
fn lsr_acc(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags.carry = (cpu.a & 0b00000001) != 0;
    cpu.a >>= 1;

    cpu.update_nz_flags(cpu.a);
}

/// Rotates a value in memory left
fn rol(cpu: *CPU, op: u16) void {
    var value = cpu.readByte(op);
    cpu.flags.carry = (value & 0b10000000) != 0;
    value <<= 1;
    if (cpu.flags.carry) {
        value |= 0b00000001;
    }
    cpu.writeByte(op, value);

    cpu.update_nz_flags(value);
}

/// Rotates the value in the accumulator left
fn rol_acc(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags.carry = (cpu.a & 0b10000000) != 0;
    cpu.a <<= 1;
    if (cpu.flags.carry) {
        cpu.a |= 0b00000001;
    }

    cpu.update_nz_flags(cpu.a);
}

/// Rotates a value in memory right
fn ror(cpu: *CPU, op: u16) void {
    var value = cpu.readByte(op);
    cpu.flags.carry = (value & 0b00000001) != 0;
    value >>= 1;
    if (cpu.flags.carry) {
        value |= 0b10000000;
    }
    cpu.writeByte(op, value);

    cpu.update_nz_flags(value);
}

/// Rotates the value in the accumulator right
fn ror_acc(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags.carry = (cpu.a & 0b00000001) != 0;
    cpu.a >>= 1;
    if (cpu.flags.carry) {
        cpu.a |= 0b10000000;
    }

    cpu.update_nz_flags(cpu.a);
}

/// Sets the CPU's V and N flags to bits 6 and 7 of the operand, respectively.
///
/// Sets the CPU's Z flag if the result of a bitwise AND between the operand
/// and the A register == 0
fn bit(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);

    const nFlag = op & 0b10000000;
    const vFlag = op & 0b01000000;
    const zFlag = op & cpu.a;

    cpu.flags.negative = nFlag != 0;
    cpu.flags.overflow = vFlag != 0;
    cpu.flags.zero = zFlag == 0;
}

test "AND" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0xFF, // LDA #FF
        0x29, 0xAA, // AND #AA ; A = 0xaa
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    _ = try cpu.step();
    try expectEqual(0x2004, cpu.pc);
    try expectEqual(0xaa, cpu.a);
}

test "ORA" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x00, // LDA #00
        0x09, 0xAA, // ORA #AA ; A = 0xaa
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    _ = try cpu.step();
    try expectEqual(0x2004, cpu.pc);
    try expectEqual(0xaa, cpu.a);
}

test "EOR" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0xFF, // LDA #00
        0x49, 0xAA, // EOR #AA ; A = 0x55
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    _ = try cpu.step();
    try expectEqual(0x2004, cpu.pc);
    try expectEqual(0x55, cpu.a);
}

test "ASL (acc)" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0xFF, // LDA #FF
        0x0A, // ASL A ; A = 0xFE, C
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    _ = try cpu.step();
    try expectEqual(0x2003, cpu.pc);
    try expectEqual(0xFE, cpu.a);
    try expect(cpu.flags.carry);
}

test "ASL (mem)" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0xFF, // LDA #FF
        0x85, 0x80, // STA $80
        0x06, 0x80, // ASL $80 ; *$80 = 0xFE, C
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();
    _ = try cpu.step();
    _ = try cpu.step();
    try expectEqual(0x2006, cpu.pc);
    try expectEqual(0xFE, cpu.readByte(0x80));
    try expect(cpu.flags.carry);
}

test "LSR (acc)" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0xFF, // LDA #FF
        0x4A, // LSR A ; A = 0x7F, C
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    _ = try cpu.step();
    try expectEqual(0x2003, cpu.pc);
    try expectEqual(0x7F, cpu.a);
    try expect(cpu.flags.carry);
}

test "LSR (mem)" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0xFF, // LDA #FF
        0x85, 0x80, // STA $80
        0x46, 0x80, // LSR $80 ; *$80 = 0x7F, C
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();
    _ = try cpu.step();
    _ = try cpu.step();
    try expectEqual(0x2006, cpu.pc);
    try expectEqual(0x7F, cpu.readByte(0x80));
    try expect(cpu.flags.carry);
}

test "ROL (acc)" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x81, // LDA #81
        0x2A, // ROL A ; A = 0x03, C
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    _ = try cpu.step();
    try expectEqual(0x2003, cpu.pc);
    try expectEqual(0x03, cpu.a);
    try expect(cpu.flags.carry);
}

test "ROL (mem)" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x81, // LDA #81
        0x85, 0x80, // STA $80
        0x26, 0x80, // ROL $80 ; *$80 = 0x03, C
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();
    _ = try cpu.step();
    _ = try cpu.step();
    try expectEqual(0x2006, cpu.pc);
    try expectEqual(0x03, cpu.readByte(0x80));
    try expect(cpu.flags.carry);
}

test "ROR (acc)" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x81, // LDA #81
        0x6A, // ROR A ; A = 0xC0, C
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    _ = try cpu.step();
    try expectEqual(0x2003, cpu.pc);
    try expectEqual(0xC0, cpu.a);
    try expect(cpu.flags.carry);
}

test "ROR (mem)" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x81, // LDA #81
        0x85, 0x80, // STA $80
        0x66, 0x80, // ROR $80 ; *$80 = 0xC0, C
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();
    _ = try cpu.step();
    _ = try cpu.step();
    try expectEqual(0x2006, cpu.pc);
    try expectEqual(0xC0, cpu.readByte(0x80));
    try expect(cpu.flags.carry);
}

test "BIT" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0xAA, // LDA #AA
        0x85, 0x42, // STA $42
        0xA9, 0x55, // LDA #55
        0x24, 0x42, // BIT $42 ; N, ~V, Z
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();
    _ = try cpu.step();
    _ = try cpu.step();
    _ = try cpu.step();
    try expectEqual(0x2008, cpu.pc);
    try expect(cpu.flags.negative);
    try expect(!cpu.flags.overflow);
    try expect(cpu.flags.zero);
}
