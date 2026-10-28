const std = @import("std");
const Allocator = std.mem.Allocator;

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

    /// Reads a single byte from the CPU's RAM
    fn read_byte(self: CPU, addr: u16) u8 {
        return self.ram[addr];
    }

    /// Writes a single byte to the CPU's RAM
    fn write_byte(self: CPU, addr: u16, byte: u8) void {
        self.ram[addr] = byte;
    }

    /// Reads a single 16-bit word from the CPU's RAM
    fn read_word(self: CPU, addr: u16) u16 {
        const high: u16 = self.ram[addr + 1];
        const low: u16 = self.ram[addr];
        return (high << 8) | low;
    }

    /// Writes a single 16-bit word to the CPU's RAM
    fn write_word(self: CPU, addr: u16, word: u16) void {
        self.ram[addr] = @truncate(word & 0xff);
        self.ram[addr + 1] = @truncate(word >> 8);
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

    cpu.write_byte(0x4242, 0x42);
    cpu.write_byte(0x1234, 0x56);

    try expectEqual(cpu.read_byte(0x4242), 0x42);
    try expectEqual(cpu.read_byte(0x1234), 0x56);
}

test "Read and write words" {
    const gpa = std.testing.allocator;
    const expectEqual = std.testing.expectEqual;

    const cpu = try CPU.init(gpa);
    defer cpu.deinit(gpa);

    cpu.write_word(0xfffc, 0x3000);

    try expectEqual(cpu.read_word(0xfffc), 0x3000);
    try expectEqual(cpu.read_byte(0xfffc), 0x00);
    try expectEqual(cpu.read_byte(0xfffd), 0x30);
}
