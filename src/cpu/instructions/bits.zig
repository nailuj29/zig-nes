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
        0x09, 0xAA, // AND #AA ; A = 0xaa
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();

    _ = try cpu.step();
    try expectEqual(0x2004, cpu.pc);
    try expectEqual(0xaa, cpu.a);
}
