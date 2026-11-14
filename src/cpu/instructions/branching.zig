const CPU = @import("../root.zig").CPU;
const InstructionMetadata = @import("./table.zig").InstructionMetadata;
const std = @import("std");

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
}

/// Sets the CPU's program counter to a new memory address
fn jmp(cpu: *CPU, op: u16) void {
    cpu.pc = op;
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
