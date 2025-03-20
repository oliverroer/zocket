const std = @import("std");
const posix = std.posix;

const AddressFamliy = posix.AF;
const SocketType = posix.SOCK;
const SocketLevel = posix.SOL;
const SocketOption = posix.SO;

pub const Receiver = struct {
    fd: posix.socket_t,
    address: std.net.Address,

    pub fn blocking(port: u16) !Receiver {
        // set up a socket for UDP/IPv4
        const fd = try posix.socket(AddressFamliy.INET, SocketType.DGRAM, 0);

        const address = std.net.Address.initIp4(
            .{ 0x00, 0x00, 0x00, 0x00 },
            port,
        );

        try posix.bind(fd, &address.any, address.getOsSockLen());

        return .{
            .fd = fd,
            .address = address,
        };
    }

    pub fn nonblocking(port: u16) !Receiver {
        // set up a socket for UDP/IPv4
        const fd = try posix.socket(AddressFamliy.INET, SocketType.DGRAM | SocketType.NONBLOCK, 0);

        const address = std.net.Address.initIp4(
            .{ 0x00, 0x00, 0x00, 0x00 },
            port,
        );

        try posix.bind(fd, &address.any, address.getOsSockLen());

        return .{
            .fd = fd,
            .address = address,
        };
    }

    pub fn close(self: Receiver) void {
        posix.close(self.fd);
    }

    pub fn receive(self: Receiver, buffer: []u8, src_address: *std.net.Address) !usize {
        var src_addr: posix.sockaddr = undefined;
        var addrlen: posix.socklen_t = @sizeOf(posix.sockaddr);
        const read = try posix.recvfrom(self.fd, buffer, 0, &src_addr, &addrlen);
        src_address.* = std.net.Address.initPosix(@alignCast(&src_addr));
        return read;
    }
};
