const CPU = @import("../root.zig").CPU;
const InstructionMetadata = @import("./table.zig").InstructionMetadata;
const std = @import("std");

/// Loads all instructions handling branching operations into the main instruction lookup table
///
/// Should be run at compile time
pub fn register(table: *[256]InstructionMetadata) void {
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

    // BCC:
    table[0x90] = .{
        .mnemonic = "BCC",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &bcc,
    };

    // BCS:
    table[0xB0] = .{
        .mnemonic = "BCS",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &bcs,
    };
}

/// Sets the CPU's program counter to a new memory address
fn jmp(cpu: *CPU, op: u16) void {
    cpu.pc = op;
}

/// Branches to a new execution path if the CPU's carry flag is not set
fn bcc(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    if (!cpu.flags.carry) {
        const offset: i8 = @bitCast(op);
        if (offset < 0) { // The Zig compiler doesn't like adding an i8 to a u16.
            // There's definitely a better way to do this.
            cpu.pc -= @as(u8, @abs(offset));
        } else {
            cpu.pc += @as(u8, @abs(offset));
        }
    }
}

/// Branches to a new execution path if the CPU's carry flag is set
fn bcs(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    if (cpu.flags.carry) {
        const offset: i8 = @bitCast(op);
        if (offset < 0) {
            cpu.pc -= @as(u8, @abs(offset));
        } else {
            cpu.pc += @as(u8, @abs(offset));
        }
    }
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

test "BCC" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x90, 0x42, // BCC #42
        0x90, 0x42, // BCC #42
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.flags.carry = true;
    _ = try cpu.step();
    try expectEqual(0x2002, cpu.pc);

    cpu.flags.carry = false;
    _ = try cpu.step();
    try expectEqual(0x2046, cpu.pc);
}

test "BCS" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xB0, 0x42, // BCS #42
        0xB0, 0x42, // BCS #42
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.flags.carry = false;
    _ = try cpu.step();
    try expectEqual(0x2002, cpu.pc);

    cpu.flags.carry = true;
    _ = try cpu.step();
    try expectEqual(0x2046, cpu.pc);
}
