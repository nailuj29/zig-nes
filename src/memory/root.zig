const std = @import("std");
const Allocator = std.mem.Allocator;

const MemoryError = error{IllegalAccess};

/// Handles mapping CPU memory access to various other parts of the system
pub const NESMemoryMap = struct {
    ram: []u8 = undefined,
    ppu_regs: []u8 = undefined,
    apu_io_regs: []u8 = undefined,
    cartridge: []u8 = undefined,

    /// Initializes the memory map, allocating all needed memory using the provided Allocator
    pub fn init(allocator: Allocator) !NESMemoryMap {
        var map: NESMemoryMap = .{};
        map.ram = try allocator.alloc(u8, 0x800);
        map.ppu_regs = try allocator.alloc(u8, 0x8);
        map.apu_io_regs = try allocator.alloc(u8, 0x18);
        map.cartridge = try allocator.alloc(u8, 0xBFE0);
        return map;
    }

    /// Frees all memory allocated to this memory map
    pub fn deinit(self: NESMemoryMap, allocator: Allocator) void {
        allocator.free(self.ram);
        allocator.free(self.ppu_regs);
        allocator.free(self.apu_io_regs);
        allocator.free(self.cartridge);
    }

    /// Reads a single byte from the memory
    pub fn read(self: NESMemoryMap, address: u16) u8 {
        return switch (address) {
            0x0000...0x1FFF => self.ram[address & 0x7FF],
            0x2000...0x3FFF => self.ppu_regs[address & 0x7],
            0x4000...0x4017 => self.apu_io_regs[address & 0x1F], // We need all these bits; test mode takes the rest of the address space
            0x4020...0xFFFF => self.cartridge[address - 0x4020],
            else => unreachable, // Test mode not yet implemented
        };
    }

    /// Writes a single byte to the memory
    pub fn write(self: NESMemoryMap, address: u16, byte: u8) void {
        switch (address) {
            0x0000...0x1FFF => self.ram[address & 0x7FF] = byte,
            0x2000...0x3FFF => self.ppu_regs[address & 0x7] = byte,
            0x4000...0x4017 => self.apu_io_regs[address & 0x1F] = byte, // We need all these bits; test mode takes the rest of the address space
            0x4020...0xFFFF => self.cartridge[address - 0x4020] = byte,
            else => unreachable, // Test mode not yet implemented
        }
    }

    /// Writes an arbitrary amount of bytes to the cartridge section of memory
    pub fn writeChunk(self: NESMemoryMap, start_addr: u16, chunk: []u8) MemoryError!void {
        if (start_addr < 0x4020) { // Must be cartridge memory
            return error.IllegalAccess;
        }

        @memcpy(self.cartridge[start_addr - 0x4020 .. start_addr + chunk.len - 0x4020], chunk);
    }
};

test "Memory map init/deinit doesn't fail" {
    const map = try NESMemoryMap.init(std.testing.allocator);
    defer map.deinit(std.testing.allocator);
}

test "RAM Access" {
    const expectEqual = std.testing.expectEqual;

    const mem = try NESMemoryMap.init(std.testing.allocator);
    defer mem.deinit(std.testing.allocator);

    mem.write(0x1234, 0xaa);
    mem.write(0x3456, 0xaa);
    mem.write(0x4001, 0xaa);
    mem.write(0xfffc, 0xaa);

    try expectEqual(0xaa, mem.read(0x0236));
    try expectEqual(0xaa, mem.read(0x2006));
    try expectEqual(0xaa, mem.read(0x4001));
    try expectEqual(0xaa, mem.read(0xfffc));
}
