const CPU = @import("../root.zig").CPU;
const InstructionMetadata = @import("./table.zig").InstructionMetadata;
const std = @import("std");

// TODO: all of these instructions have cycle weirdness. handle it eventually PLEASE

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

    // BEQ:
    table[0xF0] = .{
        .mnemonic = "BEQ",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &beq,
    };

    // BNE:
    table[0xD0] = .{
        .mnemonic = "BNE",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &bne,
    };

    // BMI:
    table[0x30] = .{
        .mnemonic = "BMI",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &bmi,
    };

    // BPL:
    table[0x10] = .{
        .mnemonic = "BPL",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &bpl,
    };

    // BVC:
    table[0x50] = .{
        .mnemonic = "BVC",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &bvc,
    };

    // BVS:
    table[0x70] = .{
        .mnemonic = "BVS",
        .addressing_mode = .immediate,
        .operand_type = .value,
        .cycles = 2,
        .handler = &bvs,
    };

    // JSR:
    table[0x20] = .{
        .mnemonic = "JSR",
        .addressing_mode = .absolute,
        .operand_type = .address,
        .cycles = 6,
        .handler = &jsr,
    };

    // RTS:
    table[0x60] = .{
        .mnemonic = "RTS",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 6,
        .handler = &rts,
    };

    // BRK:
    table[0x00] = .{
        .mnemonic = "BRK",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 7,
        .handler = &brk,
    };

    // RTI:
    table[0x40] = .{
        .mnemonic = "RTI",
        .addressing_mode = .implied,
        .operand_type = .none,
        .cycles = 6,
        .handler = &rti,
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
        const old_pc = cpu.pc;
        cpu.pc += op;
        if (op > 127) {
            cpu.pc -= 256;
        }
        cpu.extra_cycles += if (cpu.pc & 0xff00 != old_pc & 0xff00) 2 else 1;
    }
}

/// Branches to a new execution path if the CPU's carry flag is set
fn bcs(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    if (cpu.flags.carry) {
        const old_pc = cpu.pc;
        cpu.pc += op;
        if (op > 127) {
            cpu.pc -= 256;
        }
        cpu.extra_cycles += if (cpu.pc & 0xff00 != old_pc & 0xff00) 2 else 1;
    }
}

/// Branches to a new execution path if the CPU's zero flag is set (equal)
fn beq(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    if (cpu.flags.zero) {
        const old_pc = cpu.pc;
        cpu.pc += op;
        if (op > 127) {
            cpu.pc -= 256;
        }
        cpu.extra_cycles += if (cpu.pc & 0xff00 != old_pc & 0xff00) 2 else 1;
    }
}

/// Branches to a new execution path if the CPU's zero flag not set (not equal)
fn bne(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    if (!cpu.flags.zero) {
        const old_pc = cpu.pc;
        cpu.pc += op;
        if (op > 127) {
            cpu.pc -= 256;
        }
        cpu.extra_cycles += if (cpu.pc & 0xff00 != old_pc & 0xff00) 2 else 1;
    }
}

/// Branches to a new execution path if the CPU's negative flag is set (minus)
fn bmi(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    if (cpu.flags.negative) {
        const old_pc = cpu.pc;
        cpu.pc += op;
        if (op > 127) {
            cpu.pc -= 256;
        }
        cpu.extra_cycles += if (cpu.pc & 0xff00 != old_pc & 0xff00) 2 else 1;
    }
}

/// Branches to a new execution path if the CPU's negative flag is not set (plus)
fn bpl(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    if (!cpu.flags.negative) {
        const old_pc = cpu.pc;
        cpu.pc += op;
        if (op > 127) {
            cpu.pc -= 256;
        }
        cpu.extra_cycles += if (cpu.pc & 0xff00 != old_pc & 0xff00) 2 else 1;
    }
}

/// Branches to a new execution path if the CPU's overflow flag is not set
fn bvc(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    if (!cpu.flags.overflow) {
        const old_pc = cpu.pc;
        cpu.pc += op;
        if (op > 127) {
            cpu.pc -= 256;
        }
        cpu.extra_cycles += if (cpu.pc & 0xff00 != old_pc & 0xff00) 2 else 1;
    }
}

/// Branches to a new execution path if the CPU's overflow flag is set
fn bvs(cpu: *CPU, op16: u16) void {
    const op: u8 = @truncate(op16);
    if (cpu.flags.overflow) {
        const old_pc = cpu.pc;
        cpu.pc += op;
        if (op > 127) {
            cpu.pc -= 256;
        }
        cpu.extra_cycles += if (cpu.pc & 0xff00 != old_pc & 0xff00) 2 else 1;
    }
}

/// Jumps to a subroutine at the specified address, and pushes the return address to the stack
fn jsr(cpu: *CPU, op: u16) void {
    cpu.pushWord(cpu.pc - 1);

    cpu.pc = op;
}

/// Returns from a subroutine, pulling the return address from the stack
fn rts(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.pc = cpu.pullWord() + 1;
}

/// Hands control to an interrupt handler at $FFFE
///
/// Pushes a return address (leaving a byte of space after the instruction)
/// as well as the status register, with the break flag set.
fn brk(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.pushWord(cpu.pc + 1);

    cpu.flags.brk = true;
    cpu.push(@bitCast(cpu.flags));

    cpu.pc = cpu.readWord(0xFFFE);
}

/// Returns control to the program from an interrupt handler
///
/// Pulls the status flags, then the return address from the stack
fn rti(cpu: *CPU, op: u16) void {
    _ = op;
    cpu.flags = @bitCast(cpu.pull());
    cpu.flags.unused = true;

    cpu.pc = cpu.pullWord();
}

test "JMP" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x4C, 0x00, 0x42, // JMP $4200
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

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

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.flags.carry = true;
    _ = try cpu.step();
    try expectEqual(0x6002, cpu.pc);

    cpu.flags.carry = false;
    _ = try cpu.step();
    try expectEqual(0x6046, cpu.pc);
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

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.flags.carry = false;
    _ = try cpu.step();
    try expectEqual(0x6002, cpu.pc);

    cpu.flags.carry = true;
    _ = try cpu.step();
    try expectEqual(0x6046, cpu.pc);
}

test "BEQ" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xF0, 0x42, // BEQ #42
        0xF0, 0x42, // BEQ #42
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.flags.zero = false;
    _ = try cpu.step();
    try expectEqual(0x6002, cpu.pc);

    cpu.flags.zero = true;
    _ = try cpu.step();
    try expectEqual(0x6046, cpu.pc);
}

test "BNE" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xD0, 0x42, // BNE #42
        0xD0, 0x42, // BNE #42
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.flags.zero = true;
    _ = try cpu.step();
    try expectEqual(0x6002, cpu.pc);

    cpu.flags.zero = false;
    _ = try cpu.step();
    try expectEqual(0x6046, cpu.pc);
}

test "BMI" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x30, 0x42, // BMI #42
        0x30, 0x42, // BMI #42
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.flags.negative = false;
    _ = try cpu.step();
    try expectEqual(0x6002, cpu.pc);

    cpu.flags.negative = true;
    _ = try cpu.step();
    try expectEqual(0x6046, cpu.pc);
}

test "BPL" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x10, 0x42, // BPL #42
        0x10, 0x42, // BPL #42
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.flags.negative = true;
    _ = try cpu.step();
    try expectEqual(0x6002, cpu.pc);

    cpu.flags.negative = false;
    _ = try cpu.step();
    try expectEqual(0x6046, cpu.pc);
}

test "BVC" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x50, 0x42, // BVC #42
        0x50, 0x42, // BVC #42
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.flags.overflow = true;
    _ = try cpu.step();
    try expectEqual(0x6002, cpu.pc);

    cpu.flags.overflow = false;
    _ = try cpu.step();
    try expectEqual(0x6046, cpu.pc);
}

test "BVS" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x70, 0x42, // BVS #42
        0x70, 0x42, // BVS #42
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.flags.overflow = false;
    _ = try cpu.step();
    try expectEqual(0x6002, cpu.pc);

    cpu.flags.overflow = true;
    _ = try cpu.step();
    try expectEqual(0x6046, cpu.pc);
}

test "JSR" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x20, 0x00, 0x42, // JSR $4200
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    _ = try cpu.step();
    try expectEqual(0x6002, cpu.pullWord());
    try expectEqual(0x4200, cpu.pc);
}

test "RTS" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x60, // RTS ; A value will have been manually pushed to the stack for testing purposes
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;
    cpu.pushWord(0x4200);

    _ = try cpu.step();
    try expectEqual(0x4201, cpu.pc);
}

test "BRK" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x00, // BRK
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;
    cpu.flags.carry = true;

    cpu.writeWord(0xFFFE, 0x4200);

    _ = try cpu.step();
    try expectEqual(0b00110001, cpu.pull());
    try expectEqual(0x6002, cpu.pullWord());
    try expectEqual(0x4200, cpu.pc);
}

test "RTI" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x40, // RTI ; Stack initialized already, for testing reasons
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;
    cpu.pushWord(0x4200);
    cpu.push(0b10110001);

    _ = try cpu.step();
    try expect(cpu.flags.carry);
    try expect(cpu.flags.negative);
    try expectEqual(0x4200, cpu.pc);
}
