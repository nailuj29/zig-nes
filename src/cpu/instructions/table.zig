const CPU = @import("../root.zig").CPU;
const std = @import("std");

const regs = @import("./regs.zig");
const math = @import("./math.zig");
const bits = @import("./bits.zig");

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

/// Sets the CPU's program counter to a new memory address
fn jmp(cpu: *CPU, op: u16) void {
    cpu.pc = op;
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

    // LDA:
    table[0xA9] = .{
        .mnemonic = "LDA",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &regs.lda,
    };

    table[0xA5] = .{
        .mnemonic = "LDA",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &regs.lda,
    };

    table[0xB5] = .{
        .mnemonic = "LDA",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &regs.lda,
    };

    table[0xAD] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &regs.lda,
    };

    table[0xBD] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &regs.lda,
    };

    table[0xB9] = .{
        .mnemonic = "LDA",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &regs.lda,
    };

    table[0xA1] = .{
        .mnemonic = "LDA",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &regs.lda,
    };

    table[0xB1] = .{
        .mnemonic = "LDA",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &regs.lda,
    };

    // LDX:
    table[0xA2] = .{
        .mnemonic = "LDX",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &regs.ldx,
    };

    table[0xA6] = .{
        .mnemonic = "LDX",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &regs.ldx,
    };

    table[0xB6] = .{
        .mnemonic = "LDX",
        .addressing_mode = .zero_page_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &regs.ldx,
    };

    table[0xAE] = .{
        .mnemonic = "LDX",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &regs.ldx,
    };

    table[0xBE] = .{
        .mnemonic = "LDX",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &regs.ldx,
    };

    // LDY:
    table[0xA0] = .{
        .mnemonic = "LDY",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &regs.ldy,
    };

    table[0xA4] = .{
        .mnemonic = "LDY",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &regs.ldy,
    };

    table[0xB4] = .{
        .mnemonic = "LDY",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &regs.ldy,
    };

    table[0xAC] = .{
        .mnemonic = "LDY",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &regs.ldy,
    };

    table[0xBC] = .{
        .mnemonic = "LDY",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &regs.ldy,
    };

    // STA:
    table[0x85] = .{
        .mnemonic = "STA",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 3,
        .handler = &regs.sta,
    };

    table[0x95] = .{
        .mnemonic = "STA",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 4,
        .handler = &regs.sta,
    };

    table[0x8D] = .{
        .mnemonic = "STA",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 4,
        .handler = &regs.sta,
    };

    table[0x9D] = .{
        .mnemonic = "STA",
        .addressing_mode = .absolute_x,
        .operand_type = .address,
        .cycles = 5,
        .handler = &regs.sta,
    };

    table[0x99] = .{
        .mnemonic = "STA",
        .addressing_mode = .absolute_y,
        .operand_type = .address,
        .cycles = 5,
        .handler = &regs.sta,
    };

    table[0x81] = .{
        .mnemonic = "STA",
        .addressing_mode = .indirect_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &regs.sta,
    };

    table[0x91] = .{
        .mnemonic = "STA",
        .addressing_mode = .indirect_y,
        .operand_type = .address,
        .cycles = 5,
        .handler = &regs.sta,
    };

    // STX:
    table[0x86] = .{
        .mnemonic = "STX",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 3,
        .handler = &regs.stx,
    };

    table[0x96] = .{
        .mnemonic = "STX",
        .addressing_mode = .zero_page_y,
        .operand_type = .address,
        .cycles = 4,
        .handler = &regs.stx,
    };

    table[0x8E] = .{
        .mnemonic = "STX",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 4,
        .handler = &regs.stx,
    };

    // STY:
    table[0x84] = .{
        .mnemonic = "STY",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 3,
        .handler = &regs.sty,
    };

    table[0x94] = .{
        .mnemonic = "STY",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 4,
        .handler = &regs.sty,
    };

    table[0x8C] = .{
        .mnemonic = "STY",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 4,
        .handler = &regs.sty,
    };

    // TAX:
    table[0xAA] = .{
        .mnemonic = "TAX",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &regs.tax,
    };

    // TAY:
    table[0xA8] = .{
        .mnemonic = "TAY",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &regs.tay,
    };

    // TAY:
    table[0xA8] = .{
        .mnemonic = "TAY",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &regs.tay,
    };

    // TSX:
    table[0xBA] = .{
        .mnemonic = "TSX",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &regs.tsx,
    };

    // TXA:
    table[0x8A] = .{
        .mnemonic = "TXA",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &regs.txa,
    };

    // TXS:
    table[0x9A] = .{
        .mnemonic = "TXS",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &regs.txs,
    };

    // TYA:
    table[0x98] = .{
        .mnemonic = "TYA",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &regs.tya,
    };

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

    // ADC:
    table[0x69] = .{
        .mnemonic = "ADC",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &math.adc,
    };

    table[0x65] = .{
        .mnemonic = "ADC",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &math.adc,
    };

    table[0x75] = .{
        .mnemonic = "ADC",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &math.adc,
    };

    table[0x6D] = .{
        .mnemonic = "ADC",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &math.adc,
    };

    table[0x7D] = .{
        .mnemonic = "ADC",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &math.adc,
    };

    table[0x79] = .{
        .mnemonic = "ADC",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &math.adc,
    };

    table[0x61] = .{
        .mnemonic = "ADC",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &math.adc,
    };

    table[0x71] = .{
        .mnemonic = "ADC",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &math.adc,
    };

    // SBC:
    table[0xE9] = .{
        .mnemonic = "SBC",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &math.sbc,
    };

    table[0xE5] = .{
        .mnemonic = "SBC",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &math.sbc,
    };

    table[0xF5] = .{
        .mnemonic = "SBC",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &math.sbc,
    };

    table[0xED] = .{
        .mnemonic = "SBC",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &math.sbc,
    };

    table[0xFD] = .{
        .mnemonic = "SBC",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &math.sbc,
    };

    table[0xF9] = .{
        .mnemonic = "SBC",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &math.sbc,
    };

    table[0xE1] = .{
        .mnemonic = "SBC",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &math.sbc,
    };

    table[0xF1] = .{
        .mnemonic = "SBC",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &math.sbc,
    };

    // INC:
    table[0xE6] = .{
        .mnemonic = "INC",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 5,
        .handler = &math.inc,
    };

    table[0xF6] = .{
        .mnemonic = "INC",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &math.inc,
    };

    table[0xEE] = .{
        .mnemonic = "INC",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 6,
        .handler = &math.inc,
    };

    table[0xFE] = .{
        .mnemonic = "INC",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 2,
        .handler = &math.inc,
    };

    // INX:
    table[0xE8] = .{
        .mnemonic = "INX",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &math.inx,
    };

    // INY:
    table[0xC8] = .{
        .mnemonic = "INY",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &math.iny,
    };

    // DEC:
    table[0xC6] = .{
        .mnemonic = "DEC",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 5,
        .handler = &math.dec,
    };

    table[0xD6] = .{
        .mnemonic = "DEC",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &math.dec,
    };

    table[0xCE] = .{
        .mnemonic = "DEC",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 6,
        .handler = &math.dec,
    };

    table[0xDE] = .{
        .mnemonic = "DEC",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 2,
        .handler = &math.dec,
    };

    // DEX:
    table[0xCA] = .{
        .mnemonic = "DEX",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &math.dex,
    };

    // DEY:
    table[0x88] = .{
        .mnemonic = "DEY",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &math.dey,
    };

    // AND:
    table[0x29] = .{
        .mnemonic = "AND",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &bits.and_op,
    };

    table[0x25] = .{
        .mnemonic = "AND",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &bits.and_op,
    };

    table[0x35] = .{
        .mnemonic = "AND",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.and_op,
    };

    table[0x2D] = .{
        .mnemonic = "AND",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.and_op,
    };

    table[0x3D] = .{
        .mnemonic = "AND",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.and_op,
    };

    table[0x39] = .{
        .mnemonic = "AND",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.and_op,
    };

    table[0x21] = .{
        .mnemonic = "AND",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &bits.and_op,
    };

    table[0x31] = .{
        .mnemonic = "AND",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &bits.and_op,
    };

    // ORA:
    table[0x09] = .{
        .mnemonic = "ORA",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &bits.ora,
    };

    table[0x05] = .{
        .mnemonic = "ORA",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &bits.ora,
    };

    table[0x15] = .{
        .mnemonic = "ORA",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.ora,
    };

    table[0x0D] = .{
        .mnemonic = "ORA",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.ora,
    };

    table[0x1D] = .{
        .mnemonic = "ORA",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.ora,
    };

    table[0x19] = .{
        .mnemonic = "ORA",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.ora,
    };

    table[0x01] = .{
        .mnemonic = "ORA",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &bits.ora,
    };

    table[0x11] = .{
        .mnemonic = "ORA",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &bits.ora,
    };

    // EOR:
    table[0x49] = .{
        .mnemonic = "EOR",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &bits.eor,
    };

    table[0x45] = .{
        .mnemonic = "EOR",
        .addressing_mode = .zero_page,
        .operand_type = .value,
        .cycles = 3,
        .handler = &bits.eor,
    };

    table[0x55] = .{
        .mnemonic = "EOR",
        .addressing_mode = .zero_page_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.eor,
    };

    table[0x4D] = .{
        .mnemonic = "EOR",
        .addressing_mode = .absolute,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.eor,
    };

    table[0x5D] = .{
        .mnemonic = "EOR",
        .addressing_mode = .absolute_x,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.eor,
    };

    table[0x59] = .{
        .mnemonic = "EOR",
        .addressing_mode = .absolute_y,
        .operand_type = .value,
        .cycles = 4,
        .handler = &bits.eor,
    };

    table[0x41] = .{
        .mnemonic = "EOR",
        .addressing_mode = .indirect_x,
        .operand_type = .value,
        .cycles = 6,
        .handler = &bits.eor,
    };

    table[0x51] = .{
        .mnemonic = "EOR",
        .addressing_mode = .indirect_y,
        .operand_type = .value,
        .cycles = 5,
        .handler = &bits.eor,
    };

    // ASL:
    table[0x0A] = .{
        .mnemonic = "ASL",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &bits.asl_acc,
    };

    table[0x06] = .{
        .mnemonic = "ASL",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 5,
        .handler = &bits.asl,
    };

    table[0x16] = .{
        .mnemonic = "ASL",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &bits.asl,
    };

    table[0x0E] = .{
        .mnemonic = "ASL",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 6,
        .handler = &bits.asl,
    };

    table[0x1E] = .{
        .mnemonic = "ASL",
        .addressing_mode = .absolute_x,
        .operand_type = .address,
        .cycles = 7,
        .handler = &bits.asl,
    };

    // LSR:
    table[0x4A] = .{
        .mnemonic = "LSR",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 2,
        .handler = &bits.lsr_acc,
    };

    table[0x46] = .{
        .mnemonic = "LSR",
        .addressing_mode = .zero_page,
        .operand_type = .address,
        .cycles = 5,
        .handler = &bits.lsr,
    };

    table[0x56] = .{
        .mnemonic = "LSR",
        .addressing_mode = .zero_page_x,
        .operand_type = .address,
        .cycles = 6,
        .handler = &bits.lsr,
    };

    table[0x4E] = .{
        .mnemonic = "LSR",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 6,
        .handler = &bits.lsr,
    };

    table[0x5E] = .{
        .mnemonic = "LSR",
        .addressing_mode = .absolute_x,
        .operand_type = .address,
        .cycles = 7,
        .handler = &bits.lsr,
    };

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

test {
    _ = @import("./regs.zig");
    _ = @import("./math.zig");
    _ = @import("./bits.zig");
}
