const CPU = @import("../root.zig").CPU;
const std = @import("std");

/// Loads a value into the CPU's A register, updating the negative and zero flags if necessary
pub fn lda(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.a = op;
    cpu.update_nz_flags(op);
}

/// Loads a value into the CPU's X register, updating the negative and zero flags if necessary
pub fn ldx(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.x = op;
    cpu.update_nz_flags(op);
}

/// Loads a value into the CPU's Y register, updating the negative and zero flags if necessary
pub fn ldy(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.y = op;
    cpu.update_nz_flags(op);
}

/// Stores a value from the CPU's A register in memory
pub fn sta(cpu: *CPU, op: u16) void {
    cpu.writeByte(op, cpu.a);
}

/// Stores a value from the CPU's X register in memory
pub fn stx(cpu: *CPU, op: u16) void {
    cpu.writeByte(op, cpu.x);
}

/// Stores a value from the CPU's Y register in memory
pub fn sty(cpu: *CPU, op: u16) void {
    cpu.writeByte(op, cpu.y);
}

/// Transfers the CPU's A register to its X register
pub fn tax(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.x = cpu.a;
    cpu.update_nz_flags(cpu.x);
}

/// Transfers the CPU's A register to its Y register
pub fn tay(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.y = cpu.a;
    cpu.update_nz_flags(cpu.y);
}

/// Transfers the CPU's stack pointer to its X register
pub fn tsx(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.x = cpu.sp;
    cpu.update_nz_flags(cpu.x);
}

/// Transfers the CPU's X register to its A register
pub fn txa(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.a = cpu.x;
    cpu.update_nz_flags(cpu.a);
}

/// Transfers the CPU's X register to its stack pointer
pub fn txs(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.sp = cpu.x;
    cpu.update_nz_flags(cpu.sp);
}

/// Transfers the CPU's Y register to its A register
pub fn tya(cpu: *CPU, op: u16) void {
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
