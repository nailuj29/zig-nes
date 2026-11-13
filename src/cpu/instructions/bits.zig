const CPU = @import("../root.zig").CPU;
const std = @import("std");

pub fn and_op(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.a = cpu.a & op;

    cpu.update_nz_flags(cpu.a);
}

pub fn ora(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.a = cpu.a | op;

    cpu.update_nz_flags(cpu.a);
}

pub fn eor(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    cpu.a = cpu.a ^ op;

    cpu.update_nz_flags(cpu.a);
}

pub fn asl(cpu: *CPU, op: u16) void {
    var value = cpu.readByte(op);
    cpu.flags.carry = (value & 0b10000000) != 0;
    value <<= 1;
    cpu.writeByte(op, value);

    cpu.update_nz_flags(value);
}

pub fn asl_acc(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags.carry = (cpu.a & 0b10000000) != 0;
    cpu.a <<= 1;

    cpu.update_nz_flags(cpu.a);
}

pub fn lsr(cpu: *CPU, op: u16) void {
    var value = cpu.readByte(op);
    cpu.flags.carry = (value & 0b00000001) != 0;
    value >>= 1;
    cpu.writeByte(op, value);

    cpu.update_nz_flags(value);
}

pub fn lsr_acc(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags.carry = (cpu.a & 0b00000001) != 0;
    cpu.a >>= 1;

    cpu.update_nz_flags(cpu.a);
}

pub fn rol(cpu: *CPU, op: u16) void {
    var value = cpu.readByte(op);
    cpu.flags.carry = (value & 0b10000000) != 0;
    value <<= 1;
    if (cpu.flags.carry) {
        value |= 0x1;
    }
    cpu.writeByte(op, value);

    cpu.update_nz_flags(value);
}

pub fn rol_acc(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags.carry = (cpu.a & 0b10000000) != 0;
    cpu.a <<= 1;
    if (cpu.flags.carry) {
        cpu.a |= 0x1;
    }

    cpu.update_nz_flags(cpu.a);
}

pub fn ror(cpu: *CPU, op: u16) void {
    var value = cpu.readByte(op);
    cpu.flags.carry = (value & 0b00000001) != 0;
    value >>= 1;
    if (cpu.flags.carry) {
        value |= 0b10000000;
    }
    cpu.writeByte(op, value);

    cpu.update_nz_flags(value);
}

pub fn ror_acc(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags.carry = (cpu.a & 0b00000001) != 0;
    cpu.a >>= 1;
    if (cpu.flags.carry) {
        cpu.a |= 0b10000000;
    }

    cpu.update_nz_flags(cpu.a);
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
    try expectEqual(0xab, cpu.a);
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

test "ASL" {
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

test "LSR" {
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

test "ROL" {
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

test "ROR" {
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
