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
}

fn pha(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.push(cpu.a);
}

fn php(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags.brk = true;

    cpu.push(@bitCast(cpu.flags));
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

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();
    _ = try cpu.step();
    try expectEqual(0x2003, cpu.pc);
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

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = try cpu.step();
    _ = try cpu.step();
    _ = try cpu.step();
    try expectEqual(0x2003, cpu.pc);
    try expectEqual(0b00110101, cpu.pull());
}
