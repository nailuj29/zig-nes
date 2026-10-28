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
};

test "CPU init doesn't fail" {
    const cpu = try CPU.init(std.testing.allocator);
    defer cpu.deinit(std.testing.allocator);
}
