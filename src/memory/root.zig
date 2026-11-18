const std = @import("std");
const Allocator = std.mem.Allocator;

pub const NESMemoryMap = struct {
    ram: []u8 = undefined,
    ppu_regs: []u8 = undefined,
    apu_io_regs: []u8 = undefined,

    pub fn init(allocator: Allocator) !NESMemoryMap {
        var map: NESMemoryMap = .{};
        map.ram = try allocator.alloc(u8, 0x800);
        map.ppu_regs = try allocator.alloc(u8, 0x8);
        map.apu_io_regs = try allocator.alloc(u8, 0x18);
        return map;
    }

    pub fn deinit(self: NESMemoryMap, allocator: Allocator) void {
        allocator.free(self.ram);
        allocator.free(self.ppu_regs);
        allocator.free(self.apu_io_regs);
    }

    pub fn read(self: NESMemoryMap, address: u16) u8 {
        return switch (address) {
            0x0000...0x1FFF => self.ram[address & 0x7FF],
            0x2000...0x3FFF => self.ppu_regs[address & 0x7],
            0x4000...0x4017 => self.apu_io_regs[address & 0x1F], // We need all these bits; test mode takes the rest of the address space; also not yet implemented
            else => unreachable, // Not yet implemented
        };
    }
};

test "Memory map init/deinit doesn't fail" {
    const map = try NESMemoryMap.init(std.testing.allocator);
    defer map.deinit(std.testing.allocator);
}
