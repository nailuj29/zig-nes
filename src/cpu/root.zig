const std = @import("std");
const Allocator = std.mem.Allocator;

const CPUError = error{
    IllegalAccess,
};

const AddressMode = enum {
    immediate,
    absolute,
    zero_page,
    indexed_absolute_x,
    indexed_absolute_y,
    indexed_zero_page_y,
    indexed_zero_page_x,
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
