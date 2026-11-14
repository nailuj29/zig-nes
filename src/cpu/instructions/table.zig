const CPU = @import("../root.zig").CPU;
const std = @import("std");

const regs = @import("./regs.zig");
const math = @import("./math.zig");
const bits = @import("./bits.zig");
const branching = @import("./branching.zig");

/// Possible addressing modes for an instruction
pub const AddressMode = enum {
    implied,
    immediate,
    absolute,
    zero_page,
    absolute_x,
    absolute_y,
    zero_page_x,
    zero_page_y,
    indirect,
    indirect_x,
    indirect_y,
};

/// Possible operand types for an instruction (memory or value for all instructions with an operand)
pub const OperandType = enum {
    none,
    value,
    address,
};

/// Contains the necessary metadata to execute an instruction
pub const InstructionMetadata = struct {
    mnemonic: []const u8,
    addressing_mode: AddressMode,
    operand_type: OperandType,
    cycles: u8,
    handler: *const fn (*CPU, u16) void,
};

/// Jams the CPU.
fn jam(cpu: *CPU, op: u16) void {
    _ = cpu;
    _ = op;

    if (@import("builtin").is_test) {
        @panic("Illegal instruction reached");
    }

    while (true) {}
}

/// Does nothing
fn nop(cpu: *CPU, op: u16) void {
    _ = cpu;
    _ = op;
}

/// Initializes the table of instruction metadata at comptime
fn initTable() [256]InstructionMetadata {
    var table: [256]InstructionMetadata = undefined;

    // Set defaults:
    for (&table) |*entry| {
        entry.* = .{
            .mnemonic = "JAM",
            .addressing_mode = .implied,
            .operand_type = .none,
            .cycles = 255,
            .handler = &jam,
        };
    }

    // NOP:
    table[0xEA] = .{
        .mnemonic = "NOP",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &nop,
    };

    regs.register(&table);
    math.register(&table);
    bits.register(&table);
    branching.register(&table);

    return table;
}

/// A table of all 256 possible opcodes the CPU may encounter
pub const instruction_table: [256]InstructionMetadata = initTable();

test "NOP" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xEA, // NOP
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    const cycle_count = try cpu.step();
    try expectEqual(2, cycle_count);
    try expectEqual(0x2001, cpu.pc);
}

test {
    _ = @import("./regs.zig");
    _ = @import("./math.zig");
    _ = @import("./bits.zig");
    _ = @import("./branching.zig");
}
