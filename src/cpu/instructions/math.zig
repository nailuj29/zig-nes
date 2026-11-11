const CPU = @import("../root.zig").CPU;
const std = @import("std");

/// Adds a value from memory to the computer with the carry flag
pub fn adc(cpu: *CPU, op16: u16) void {
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
pub fn sbc(cpu: *CPU, op16: u16) void {
    adc(cpu, ~op16 & 0xff);
}

/// Increments a value in memory by 1
pub fn inc(cpu: *CPU, op: u16) void {
    const newValue = cpu.readByte(op) +% 1;
    cpu.writeByte(op, newValue);

    cpu.update_nz_flags(newValue);
}

/// Increments the CPU's X register by 1
pub fn inx(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.x = cpu.x +% 1;

    cpu.update_nz_flags(cpu.x);
}

/// Increments the CPU's Y register by 1
pub fn iny(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.y = cpu.y +% 1;

    cpu.update_nz_flags(cpu.y);
}

/// Decrements a value in memory by 1
pub fn dec(cpu: *CPU, op: u16) void {
    const newValue = cpu.readByte(op) -% 1;
    cpu.writeByte(op, newValue);

    cpu.update_nz_flags(newValue);
}

/// Decrements the CPU's X register by 1
pub fn dex(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.x = cpu.x -% 1;

    cpu.update_nz_flags(cpu.x);
}

/// Decrements the CPU's Y register by 1
pub fn dey(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.y = cpu.y -% 1;

    cpu.update_nz_flags(cpu.y);
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
