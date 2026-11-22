const CPU = @import("../root.zig").CPU;
const InstructionMetadata = @import("./table.zig").InstructionMetadata;
const std = @import("std");

/// Loads all instructions handling stack operations into the main instruction lookup table
///
/// Should be run at compile time
pub fn register(table: *[256]InstructionMetadata) void {
    // PHA:
    table[0x48] = .{
        .mnemonic = "PHA",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 3,
        .handler = &pha,
    };

    // PHP:
    table[0x08] = .{
        .mnemonic = "PHP",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 3,
        .handler = &php,
    };

    // PLA:
    table[0x68] = .{
        .mnemonic = "PLA",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 4,
        .handler = &pla,
    };

    // PLP:
    table[0x28] = .{
        .mnemonic = "PLP",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 4,
        .handler = &plp,
    };
}

/// Pushes the CPU's A register to the stack
fn pha(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.push(cpu.a);
}

/// Pushes the CPU's flags register to the stack, with the break flag set
fn php(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags.brk = true;

    cpu.push(@bitCast(cpu.flags));
}

/// Pulls a value from the stack into the CPU's A register
fn pla(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.a = cpu.pull();
}

/// Pulls a value from the stack into the CPU's flags register
fn plp(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags.brk = true;

    const value = cpu.pull();

    cpu.flags = @bitCast(value);
    cpu.flags.unused = true;
}

test "PHA" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x42, // LDA #42
        0x48, // PHA
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    _ = try cpu.step();
    _ = try cpu.step();
    try expectEqual(0x6003, cpu.pc);
    try expectEqual(0x42, cpu.pull());
}

test "PHP" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x38, // SEC
        0x78, // SEI
        0x08, // PHP
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    _ = try cpu.step();
    _ = try cpu.step();
    _ = try cpu.step();
    try expectEqual(0x6003, cpu.pc);
    try expectEqual(0b00110101, cpu.pull());
}

test "PLA" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x68, // PLA ; A value will have been manually pushed to the stack for testing purposes
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;
    cpu.push(0x42);

    _ = try cpu.step();
    try expectEqual(0x6001, cpu.pc);
    try expectEqual(0x42, cpu.a);
}

test "PLP" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x28, // PLP ; A value will have been manually pushed to the stack for testing purposes
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;
    cpu.push(0b00010101);

    _ = try cpu.step();
    try expectEqual(0x6001, cpu.pc);
    try expect(!cpu.flags.negative);
    try expect(!cpu.flags.overflow);
    try expect(cpu.flags.unused);
    try expect(cpu.flags.brk);
    try expect(!cpu.flags.decimal);
    try expect(cpu.flags.interrupt_disable);
    try expect(!cpu.flags.zero);
    try expect(cpu.flags.carry);
}
