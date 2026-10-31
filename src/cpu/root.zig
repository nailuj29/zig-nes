const std = @import("std");
const Allocator = std.mem.Allocator;

const CPUError = error{
    IllegalAccess,
};

const AddressMode = enum {
    immediate,
    absolute,
    zero_page,
    absolute_x,
    absolute_y,
    zero_page_x,
    zero_page_y,
    pre_indexed_indirect,
    post_indexed_indirect,
};

pub const CPU = struct {
    ram: []u8 = &.{},
    a: u8 = 0,
    x: u8 = 0,
    y: u8 = 0,
    pc: u16 = 0,
    s: u8 = 0,
    p: u6 = 0,

    /// Initialize the CPU. Requires an allocator so the CPU struct can reserve 64KB of RAM
    pub fn init(allocator: Allocator) !CPU {
        var cpu: CPU = .{};
        cpu.ram = try allocator.alloc(u8, 65536); // CPU can technically access 64KB, this should be configurable, though.

        return cpu;
    }

    /// Free the CPU's RAM
    pub fn deinit(self: CPU, allocator: Allocator) void {
        allocator.free(self.ram);
    }

    /// Loads some code into memory at a specified address, and prepares the CPU to execute said code
    pub fn loadCode(self: CPU, addr: u16, code: []u8) CPUError!void {
        if (addr + code.len > 0xfffc) { // FFFC is reserved for address of code. Will add more to this eventually
            return error.IllegalAccess;
        }

        @memcpy(self.ram[addr .. addr + code.len], code);
        self.writeWord(0xfffc, addr);
    }

    /// Reads a single byte from the CPU's RAM
    fn readByte(self: CPU, addr: u16) u8 {
        return self.ram[addr];
    }

    /// Writes a single byte to the CPU's RAM
    fn writeByte(self: CPU, addr: u16, byte: u8) void {
        self.ram[addr] = byte;
    }

    /// Reads a single 16-bit word from the CPU's RAM
    fn readWord(self: CPU, addr: u16) u16 {
        const high: u16 = self.ram[addr + 1];
        const low: u16 = self.ram[addr];
        return (high << 8) | low;
    }

    /// Writes a single 16-bit word to the CPU's RAM
    fn writeWord(self: CPU, addr: u16, word: u16) void {
        self.ram[addr] = @truncate(word & 0xff);
        self.ram[addr + 1] = @truncate(word >> 8);
    }

    /// Advances the program counter, returning the previous value it pointed to
    fn advance(self: *CPU) u8 {
        self.pc += 1;
        return self.ram[self.pc - 1];
    }

    /// Advances the program counter 2 bytes, returning the word starting at the previous address
    fn advanceWord(self: *CPU) u16 {
        self.pc += 2;
        return self.readWord(self.pc - 2);
    }

    /// Returns the operand of the previously read instruction given its mode.
    /// Will advance the program counter if necessary
    fn get_operand(self: *CPU, mode: AddressMode) u8 {
        // TODO: flag crossing of page boundary
        return switch (mode) {
            .immediate => self.advance(),
            .absolute => self.readByte(self.advanceWord()),
            .zero_page => self.readByte(self.advance()),
            .absolute_x => self.readByte(self.advanceWord() + self.x),
            .absolute_y => self.readByte(self.advanceWord() + self.y),
            .zero_page_x => self.readByte((self.advance() + self.x) & 0xff),
            .zero_page_y => self.readByte((self.advance() + self.y) & 0xff),
            .pre_indexed_indirect => blk: {
                const addr_indirect = (self.advance() + self.x) & 0xff;
                const addr_actual = self.readWord(addr_indirect);
                break :blk self.readByte(addr_actual);
            },
            .post_indexed_indirect => blk: {
                const addr_indirect = self.advance();
                const addr_actual = self.readWord(addr_indirect) + self.y;
                break :blk self.readByte(addr_actual);
            },
        };
    }
};

test "CPU init/deinit doesn't fail" {
    const cpu = try CPU.init(std.testing.allocator);
    defer cpu.deinit(std.testing.allocator);
}

test "Read and write bytes" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    const cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    cpu.writeByte(0x4242, 0x42);
    cpu.writeByte(0x1234, 0x56);

    try expectEqual(0x42, cpu.readByte(0x4242));
    try expectEqual(0x56, cpu.readByte(0x1234));
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

    try cpu.loadCode(0x2000, &code);

    try expectEqual(0xa9, cpu.readByte(0x2000));
    try expectEqual(0x42, cpu.readByte(0x2001));
    try expectEqual(0x2000, cpu.readWord(0xfffc));
}

test "Program counter advances" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA9, 0x42, // LDA #42
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

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

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0x42, cpu.get_operand(.immediate));
}

test "Absolute addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xAD, 0x00, 0x42, // LDA $4200
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.writeByte(0x4200, 0xaa); // Write the word to be read as the operand

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.get_operand(.absolute));
}

test "Zero-page addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA5, 0x42, // LDA $42
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.writeByte(0x42, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.get_operand(.zero_page));
}

test "Absolute,X addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xBD, 0x00, 0x42, // LDA $4200,X
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.x = 0x42;

    cpu.writeByte(0x4242, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.get_operand(.absolute_x));
}

test "Absolute,Y addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xB9, 0x00, 0x42, // LDA $4200,Y
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.x = 0x42;

    cpu.writeByte(0x4242, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.get_operand(.absolute_y));
}

test "Zero-page,X addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xB5, 0x42, // LDA $42,X
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.x = 0x42;

    cpu.writeByte(0x84, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.get_operand(.zero_page_x));
}

test "Zero-page,Y addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xB6, 0x42, // LDX $42,Y
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.y = 0x42;

    cpu.writeByte(0x84, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.get_operand(.zero_page_x));
}

test "(Indirect, X) addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xA1, 0x42, // LDA ($42,X)
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.x = 0x42;

    cpu.writeWord(0x84, 0x4200);
    cpu.writeByte(0x4200, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.get_operand(.pre_indexed_indirect));
}

test "(Indirect),Y addressing mode" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    var cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    var code = [_]u8{
        0xB1, 0x42, // LDA ($42),Y
    };

    try cpu.loadCode(0x2000, &code);
    cpu.pc = 0x2000;

    cpu.y = 0x42;

    cpu.writeWord(0x42, 0x4200);
    cpu.writeByte(0x4242, 0xaa);

    _ = cpu.advance(); // Go past instruction
    try expectEqual(0xaa, cpu.get_operand(.post_indexed_indirect));
}
