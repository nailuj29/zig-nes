const std = @import("std");
const Allocator = std.mem.Allocator;

const instructions = @import("./instructions/table.zig");
const instruction_table = instructions.instruction_table;
const AddressMode = instructions.AddressMode;
const OperandType = instructions.OperandType;

const memory = @import("memory");
const NESMemoryMap = memory.NESMemoryMap;

const CPUFlags = packed struct {
    carry: bool = false,
    zero: bool = false,
    interrupt_disable: bool = false,
    decimal: bool = false,
    brk: bool = false,
    unused: bool = true,
    overflow: bool = false,
    negative: bool = false,
};

pub const CPU = struct {
    mem: NESMemoryMap = .{},
    a: u8 = 0,
    x: u8 = 0,
    y: u8 = 0,
    pc: u16 = 0,
    sp: u8 = 0xfd,
    flags: CPUFlags = .{},
    extra_cycles: u8 = 0,

    /// Initialize the CPU. Requires an allocator so the CPU struct can reserve 64KB of RAM
    pub fn init(allocator: Allocator) !CPU {
        var cpu: CPU = .{};
        cpu.mem = try NESMemoryMap.init(allocator);
        return cpu;
    }

    /// Free the CPU's RAM
    pub fn deinit(self: CPU, allocator: Allocator) void {
        self.mem.deinit(allocator);
    }

    /// Loads some code into memory at a specified address, and prepares the CPU to execute said code
    pub fn loadCode(self: CPU, addr: u16, code: []u8) !void {
        try self.mem.writeChunk(addr, code);
        self.writeWord(0xfffc, addr);
    }

    /// Runs the instruction the program counter points to, advancing as necessary
    pub fn step(self: *CPU) !u8 {
        self.extra_cycles = 0;
        const instr = self.advance();
        const meta = instruction_table[instr];
        const operand = self.getOperand(meta.addressing_mode, meta.operand_type);

        meta.handler(self, operand);

        return meta.cycles + self.extra_cycles;
    }

    /// Reads a single byte from the CPU's RAM
    pub fn readByte(self: CPU, addr: u16) u8 {
        return self.mem.read(addr);
    }

    /// Writes a single byte to the CPU's RAM
    pub fn writeByte(self: CPU, addr: u16, byte: u8) void {
        self.mem.write(addr, byte);
    }

    /// Reads a single 16-bit word from the CPU's RAM
    pub fn readWord(self: CPU, addr: u16) u16 {
        const high: u16 = self.mem.read(addr + 1);
        const low: u16 = self.mem.read(addr);
        return (high << 8) | low;
    }

    /// Writes a single 16-bit word to the CPU's RAM
    pub fn writeWord(self: CPU, addr: u16, word: u16) void {
        self.mem.write(addr, @truncate(word & 0xff));
        self.mem.write(addr + 1, @truncate(word >> 8));
    }

    /// Advances the program counter, returning the previous value it pointed to
    fn advance(self: *CPU) u8 {
        self.pc += 1;
        return self.readByte(self.pc - 1);
    }

    /// Advances the program counter 2 bytes, returning the word starting at the previous address
    fn advanceWord(self: *CPU) u16 {
        self.pc += 2;
        return self.readWord(self.pc - 2);
    }

    /// Returns the operand of the previously read instruction given its mode.
    /// Will advance the program counter if necessary
    fn getOperand(self: *CPU, mode: AddressMode, op_type: OperandType) u16 {
        if (mode == .implied) return 255; // No opcode that can have an addressing mode of `implied` should be using this, return a garbage value
        if (mode == .immediate) return self.advance(); // Always a `value` type
        const addr = switch (mode) {
            .absolute => self.advanceWord(),
            .zero_page => self.advance(),
            .absolute_x => blk: {
                const base = self.advanceWord();
                const addr = base + self.x;
                if (addr & 0xff00 != base & 0xff00) {
                    self.extra_cycles += 1;
                }
                break :blk addr;
            },
            .absolute_y => blk: {
                const base = self.advanceWord();
                const addr = base + self.y;
                if (addr & 0xff00 != base & 0xff00) {
                    self.extra_cycles += 1;
                }
                break :blk addr;
            },
            .zero_page_x => (self.advance() + self.x) & 0xff,
            .zero_page_y => (self.advance() + self.y) & 0xff,
            .indirect => blk: {
                const addr_indirect_lo: u16 = self.advance();
                const addr_indirect_hi: u16 = self.advance();

                const addr_lo: u16 = self.readWord(addr_indirect_hi << 8 | addr_indirect_lo);
                const addr_hi: u16 = self.readWord(addr_indirect_hi << 8 | (addr_indirect_lo + 1) & 0xff);

                break :blk addr_hi << 8 | addr_lo;
            },
            .indirect_x => blk: {
                const addr_indirect = (self.advance() + self.x) & 0xff;
                const addr_actual = self.readWord(addr_indirect);
                break :blk addr_actual;
            },
            .indirect_y => blk: {
                const addr_indirect = self.advance();
                const addr_actual = self.readWord(addr_indirect) + self.y;
                break :blk addr_actual;
            },
            else => unreachable,
        };

        return switch (op_type) {
            .value => self.readByte(addr),
            .address => addr,
            else => unreachable,
        };
    }

    /// Updates the negative and zero flags after an instruction is executed
    pub fn updateNZFlags(self: *CPU, value: u8) void {
        self.flags.zero = value == 0;
        self.flags.negative = (value & (1 << 7)) != 0;
    }

    pub fn push(self: *CPU, byte: u8) void {
        self.writeByte(@as(u16, self.sp) + 0x100, byte);

        if (self.sp == 0) {
            self.sp = 255;
        } else {
            self.sp -= 1;
        }
    }

    pub fn pull(self: *CPU) u8 {
        if (self.sp == 255) {
            self.sp = 0;
        } else {
            self.sp += 1;
        }

        return self.readByte(@as(u16, self.sp) + 0x100);
    }

    pub fn pushWord(self: *CPU, word: u16) void {
        const lo: u8 = @truncate(word & 0xff);
        const hi: u8 = @truncate(word >> 8);

        self.push(hi);
        self.push(lo);
    }

    pub fn pullWord(self: *CPU) u16 {
        const lo: u16 = self.pull();
        const hi: u16 = self.pull();

        return hi << 8 | lo;
    }
};

test "CPU init/deinit doesn't fail" {
    const cpu = try CPU.init(std.testing.allocator);
    defer cpu.deinit(std.testing.allocator);
}

test "Read and write words" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    const cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    cpu.writeWord(0xfffc, 0x3000);

    try expectEqual(0x3000, cpu.readWord(0xfffc));
    try expectEqual(0x00, cpu.readByte(0xfffc));
    try expectEqual(0x30, cpu.readByte(0xfffd));
}

test "Loading code" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    const cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x42, // LDA #42
    };

    try cpu.loadCode(0x6000, &code);

    try expectEqual(0xa9, cpu.readByte(0x6000));
    try expectEqual(0x42, cpu.readByte(0x6001));
    try expectEqual(0x6000, cpu.readWord(0xfffc));
}

test "Program counter advances" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x42, // LDA #42
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    try expectEqual(0xa9, cpu.advance());
    try expectEqual(0x42, cpu.advance());
}

test "Immediate addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x42, // LDA #42
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0x42, cpu.getOperand(.immediate, .value));
}

test "Absolute addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xAD, 0x00, 0x42, // LDA $4200
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.writeByte(0x4200, 0xaa); // Write the word to be read as the operand

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.getOperand(.absolute, .value));
}

test "Zero-page addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA5, 0x42, // LDA $42
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.writeByte(0x42, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.getOperand(.zero_page, .value));
}

test "Absolute,X addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xBD, 0x00, 0x42, // LDA $4200,X
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.x = 0x42;

    cpu.writeByte(0x4242, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.getOperand(.absolute_x, .value));
}

test "Absolute,Y addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xB9, 0x00, 0x42, // LDA $4200,Y
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.x = 0x42;

    cpu.writeByte(0x4242, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.getOperand(.absolute_y, .value));
}

test "Zero-page,X addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xB5, 0x42, // LDA $42,X
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.x = 0x42;

    cpu.writeByte(0x84, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.getOperand(.zero_page_x, .value));
}

test "Zero-page,Y addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xB6, 0x42, // LDX $42,Y
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.y = 0x42;

    cpu.writeByte(0x84, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.getOperand(.zero_page_x, .value));
}

test "Indirect addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0x6C, 0x00, 0x42, // JMP ($4200)
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.writeWord(0x4200, 0xaaaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaaaa, cpu.getOperand(.indirect, .address));
}

test "(Indirect, X) addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA1, 0x42, // LDA ($42,X)
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.x = 0x42;

    cpu.writeWord(0x84, 0x4200);
    cpu.writeByte(0x4200, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.getOperand(.indirect_x, .value));
}

test "(Indirect),Y addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xB1, 0x42, // LDA ($42),Y
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.y = 0x42;

    cpu.writeWord(0x42, 0x4200);
    cpu.writeByte(0x4242, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.getOperand(.indirect_y, .value));
}

test "Addressing modes can return address" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xAD, 0x00, 0x42, // LDA $4200
    };

    try cpu.loadCode(0x6000, &code);
    cpu.pc = 0x6000;

    cpu.writeByte(0x4200, 0xaa); // Write the word to be read as the operand

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0x4200, cpu.getOperand(.absolute, .address));
}

test "Zero and negative flags" {
    const gpa = std.testing.allocator;
    const expect = std.testing.expect;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    cpu.updateNZFlags(0);
    try expect(cpu.flags.zero);

    cpu.updateNZFlags(255); // -1 in 2's complement
    try expect(cpu.flags.negative);
}

test "Push and pull bytes" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    cpu.push(1);
    cpu.push(2);
    cpu.push(3);

    try expectEqual(3, cpu.pull());
    try expectEqual(2, cpu.pull());
    try expectEqual(1, cpu.pull());
}

test "Push and pull words" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    cpu.pushWord(0x1000);
    cpu.pushWord(0x2000);
    cpu.pushWord(0x3000);

    try expectEqual(0x3000, cpu.pullWord());
    try expectEqual(0x2000, cpu.pullWord());
    try expectEqual(0x00, cpu.pull());
    try expectEqual(0x10, cpu.pull());
}

test "SP wraparound" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    const startingSp = cpu.sp;

    for (0..256) |i| {
        cpu.push(@truncate(i));
    }

    try expectEqual(startingSp, cpu.sp);

    for (0..256) |i| {
        try expectEqual(256 - i - 1, cpu.pull());
    }
}

test {
    _ = @import("./instructions/table.zig");
}
