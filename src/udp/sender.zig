const std = @import("std");
const posix = std.posix;

const AddressFamliy = posix.AF;
const SocketType = posix.SOCK;
const SocketLevel = posix.SOL;
const SocketOption = posix.SO;

pub const Sender = struct {
    fd: posix.socket_t,
    address: std.net.Address,

    pub fn broadcast(port: u16) !Sender {
        // set up a socket for UDP/IPv4
        const fd = try posix.socket(AddressFamliy.INET, SocketType.DGRAM, 0);

        // enable broadcasting
        // without this, sendto will fail with error.AccessDenied.
        try posix.setsockopt(
            fd,
            SocketLevel.SOCKET,
            SocketOption.BROADCAST,
            std.mem.asBytes(&@as(c_int, 1)),
        );

        const address = std.net.Address.initIp4(
            .{ 0xFF, 0xFF, 0xFF, 0xFF },
            port,
        );

        return .{
            .fd = fd,
            .address = address,
        };
    }

    pub fn close(self: Sender) void {
        posix.close(self.fd);
    }

    pub fn send(self: Sender, message: []const u8) !usize {
        return try posix.sendto(
            self.fd,
            message,
            0,
            &self.address.any,
            self.address.getOsSockLen(),
        );
    }
};
